import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _NearbyPlace {
  final String name;
  final LatLng position;
  final String address;
  double distanceKm;

  _NearbyPlace({required this.name, required this.position, this.address = '', this.distanceKm = 0});
}

class _RouteStep {
  final String instruction;
  final String maneuver;
  final double distanceM;
  final List<LatLng> geometry;

  _RouteStep({required this.instruction, required this.maneuver, required this.distanceM, required this.geometry});

  String get distanceLabel => distanceM < 1000 ? '${distanceM.toInt()} m' : '${(distanceM / 1000).toStringAsFixed(1)} km';

  IconData get icon {
    switch (maneuver) {
      case 'turn-left':         return Icons.turn_left;
      case 'turn-right':        return Icons.turn_right;
      case 'turn-slight-left':  return Icons.turn_slight_left;
      case 'turn-slight-right': return Icons.turn_slight_right;
      case 'turn-sharp-left':   return Icons.turn_sharp_left;
      case 'turn-sharp-right':  return Icons.turn_sharp_right;
      case 'uturn':             return Icons.u_turn_left;
      case 'roundabout':        return Icons.roundabout_left;
      case 'arrive':            return Icons.flag;
      default:                  return Icons.straight;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  final String destination;
  const MapScreen({super.key, required this.destination});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Map
  final MapController _mapController = MapController();

  // State
  bool _isLocating = true;          // GPS phase
  bool _isSearching = false;        // Overpass search
  bool _isRouting = false;          // OSRM fetch
  bool _isNavigating = false;
  String _statusMessage = 'Đang xác định vị trí...';
  String _errorMessage = '';

  // Data
  Position? _currentPosition;
  _NearbyPlace? _selectedPlace;
  List<_NearbyPlace> _nearbyPlaces = [];

  List<LatLng> _routePoints = [];
  List<_RouteStep> _steps = [];
  String? _routeDistance;
  String? _routeDuration;
  int _currentStepIndex = 0;
  String _travelMode = 'car'; // car, motorbike, walking, flight

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 1: Get Location
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _bootstrap() async {
    setState(() { _isLocating = true; _errorMessage = ''; });

    try {
      bool svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) throw 'Dịch vụ định vị đang tắt. Vui lòng bật GPS.';

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) throw 'Quyền định vị bị từ chối.';
      }
      if (perm == LocationPermission.deniedForever) throw 'Quyền định vị bị từ chối vĩnh viễn.';

      // Try cached position first, then real GPS
      Position? pos = await Geolocator.getLastKnownPosition();
      if (pos == null) {
        try {
          pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 20),
          );
        } catch (_) {}
      }

      _currentPosition = pos ?? Position(
        latitude: 21.0278, longitude: 105.8342,
        timestamp: DateTime.now(), accuracy: 0, altitude: 0,
        altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
      );

      if (pos == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Không lấy được GPS. Dùng vị trí mặc định.')));
      }

      setState(() { _isLocating = false; });

      // STEP 2: Search nearby right away
      await _searchNearby();

    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _isLocating = false; });
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GOOGLE MAPS FALLBACK
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _launchGoogleMaps() async {
    final query = Uri.encodeComponent(widget.destination);
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở Google Maps.')));
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 2: Find all nearby instances using Overpass
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _searchNearby() async {
    if (_currentPosition == null) return;
    setState(() { 
      _isSearching = true; 
      _statusMessage = 'Đang tìm ${widget.destination} gần bạn...'; 
      _nearbyPlaces = []; 
    });

    final lat = _currentPosition!.latitude;
    final lon = _currentPosition!.longitude;
    final List<_NearbyPlace> results = [];

    // --- PHASE 1: Try Nominatim (Good for full addresses) ---
    try {
      final nomUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(widget.destination)}&format=json&limit=5&addressdetails=1&lat=$lat&lon=$lon'
      );
      final nomRes = await http.get(nomUrl, headers: {'User-Agent': 'SmartTetShopApp/1.0'}).timeout(const Duration(seconds: 10));
      if (nomRes.statusCode == 200) {
        final data = json.decode(nomRes.body) as List;
        for (final item in data) {
          final pLat = double.parse(item['lat']);
          final pLon = double.parse(item['lon']);
          final name = item['display_name'].split(',')[0];
          final addr = item['display_name'];
          final distM = Geolocator.distanceBetween(lat, lon, pLat, pLon);
          
          results.add(_NearbyPlace(
            name: name,
            position: LatLng(pLat, pLon),
            address: addr,
            distanceKm: distM / 1000,
          ));
        }
      }
    } catch (e) {
      debugPrint('Nominatim failed: $e');
    }

    // --- PHASE 2: Try Overpass (Good for brand-based discovery if results are low) ---
    if (results.isEmpty) {
      // Extract brand/main name if it's a long address
      String searchTag = widget.destination;
      if (searchTag.contains(',')) {
        searchTag = searchTag.split(',')[0].trim();
      }

      final query = '''
[out:json][timeout:20];
(
  node["name"~"$searchTag",i](around:25000,$lat,$lon);
  way["name"~"$searchTag",i](around:25000,$lat,$lon);
  node["brand"~"$searchTag",i](around:25000,$lat,$lon);
  way["brand"~"$searchTag",i](around:25000,$lat,$lon);
);
out center 10;
''';

      final servers = [
        'https://overpass-api.de/api/interpreter',
        'https://lz4.overpass-api.de/api/interpreter',
        'https://z.overpass-api.de/api/interpreter',
        'https://overpass.kumi.systems/api/interpreter',
      ];

      for (final server in servers) {
        try {
          final res = await http.post(Uri.parse(server), body: {'data': query}).timeout(const Duration(seconds: 15));
          if (res.statusCode == 200) {
            final elements = (json.decode(res.body)['elements'] as List);
            for (final e in elements) {
              final eLat = (e['lat'] ?? e['center']?['lat'] as num?)?.toDouble();
              final eLon = (e['lon'] ?? e['center']?['lon'] as num?)?.toDouble();
              if (eLat == null || eLon == null) continue;

              final tags = e['tags'] as Map? ?? {};
              final name = tags['name']?.toString() ?? searchTag;
              final addr = [tags['addr:street'], tags['addr:suburb'], tags['addr:district']].where((s) => s != null).join(', ');
              final distM = Geolocator.distanceBetween(lat, lon, eLat, eLon);
              
              results.add(_NearbyPlace(
                name: name,
                position: LatLng(eLat, eLon),
                address: addr,
                distanceKm: distM / 1000,
              ));
            }
            break; // Success on this server
          }
        } catch (e) {
          debugPrint('Overpass server $server failed: $e');
        }
      }
    }

    // --- FINALIZATION ---
    if (mounted) {
      results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      
      setState(() {
        _nearbyPlaces = results;
        _isSearching = false;
        _statusMessage = results.isEmpty
            ? 'Không tìm thấy "${widget.destination}".'
            : 'Chọn địa điểm gần bạn:';
      });

      if (results.length == 1 && _selectedPlace == null) {
        await _selectAndRoute(results[0]);
      } else if (results.isNotEmpty && _selectedPlace == null) {
        _showPlacePicker();
      }
    }
  }


  // ───────────────────────────────────────────────────────────────────────────
  // STEP 3: Show picker sheet
  // ───────────────────────────────────────────────────────────────────────────

  void _showPlacePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 5,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Icon(Icons.storefront, color: Colors.red),
              const SizedBox(width: 8),
              Text('${widget.destination} gần bạn', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _nearbyPlaces.length,
              itemBuilder: (_, i) {
                final p = _nearbyPlaces[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: i == 0 ? Colors.red.shade800 : Colors.grey.shade200,
                    child: Icon(Icons.storefront, color: i == 0 ? Colors.white : Colors.grey.shade700, size: 18),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    p.address.isNotEmpty ? '${p.address} · ${p.distanceKm.toStringAsFixed(1)} km' : '${p.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () { Navigator.pop(context); _selectAndRoute(p); },
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Đi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 4: Route to selected place
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _selectAndRoute(_NearbyPlace place) async {
    setState(() { _selectedPlace = place; _isRouting = true; _routePoints = []; _steps = []; });
    await _fetchRoute(place.position);
    if (mounted) {
      setState(() => _isRouting = false);
      _fitCamera();
    }
  }

  Future<void> _fetchRoute(LatLng dest) async {
    if (_currentPosition == null) return;
    final oLon = _currentPosition!.longitude, oLat = _currentPosition!.latitude;
    
    // --- FLIGHT MODE (Straight line) ---
    if (_travelMode == 'flight') {
      _routePoints = [LatLng(oLat, oLon), dest];
      final distM = Geolocator.distanceBetween(oLat, oLon, dest.latitude, dest.longitude);
      _routeDistance = '${(distM / 1000).toStringAsFixed(1)} km';
      _routeDuration = '${(distM / 8333).ceil()} phút'; // 500km/h ~ 8333m/min
      _steps = [
        _RouteStep(instruction: 'Cất cánh hướng về ${widget.destination}', maneuver: 'depart', distanceM: 0, geometry: [LatLng(oLat, oLon)]),
        _RouteStep(instruction: '🎯 Hạ cánh tại ${widget.destination}', maneuver: 'arrive', distanceM: distM, geometry: [dest]),
      ];
      return;
    }

    // --- OSRM MODES ---
    String profile = 'driving';
    if (_travelMode == 'walking') profile = 'foot';
    // Note: OSRM demo doesn't have a specific motorbike profile, 'driving' is closest for VN.
    
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/$profile/$oLon,$oLat;${dest.longitude},${dest.latitude}'
      '?overview=full&geometries=geojson&steps=true',
    );
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return;
      final data = json.decode(res.body);
      final routes = data['routes'] as List;
      if (routes.isEmpty) return;
      final route = routes[0];

      _routeDistance = '${((route['distance'] as num) / 1000).toStringAsFixed(1)} km';
      _routeDuration = '${((route['duration'] as num) / 60).ceil()} phút';

      final coords = route['geometry']['coordinates'] as List;
      _routePoints = coords.map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();

      _steps = [];
      for (final leg in route['legs'] as List) {
        for (final step in leg['steps'] as List) {
          final man = step['maneuver'] as Map<String, dynamic>;
          final type = man['type']?.toString() ?? 'straight';
          final mod = man['modifier']?.toString() ?? '';
          final key = mod.isNotEmpty ? '$type-$mod' : type;

          String instr = step['name']?.toString() ?? '';
          if (instr.isEmpty) {
            switch (type) {
              case 'turn': instr = mod.contains('left') ? 'Rẽ trái' : 'Rẽ phải'; break;
              case 'depart': instr = 'Xuất phát'; break;
              case 'arrive': instr = '🎯 Đến nơi!'; break;
              case 'roundabout': instr = 'Vào vòng xuyến'; break;
              case 'continue': case 'new name': instr = 'Tiếp tục đi thẳng'; break;
              case 'fork': instr = mod.contains('left') ? 'Đi nhánh trái' : 'Đi nhánh phải'; break;
              case 'merge': instr = 'Nhập làn'; break;
              default: instr = 'Tiếp tục';
            }
          }

          List<LatLng> stepGeom = [];
          if (step['geometry'] != null) {
            final sc = step['geometry']['coordinates'] as List;
            stepGeom = sc.map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
          }

          _steps.add(_RouteStep(instruction: instr, maneuver: key, distanceM: (step['distance'] as num).toDouble(), geometry: stepGeom));
        }
      }
      _currentStepIndex = 0;
    } catch (e) {
      debugPrint('OSRM error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể tính đường: $e')));
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Navigation Mode
  // ───────────────────────────────────────────────────────────────────────────

  void _startNavigation() {
    if (_steps.isEmpty) return;
    setState(() { _isNavigating = true; _currentStepIndex = 0; });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 8),
    ).listen((pos) {
      if (!mounted) return;
      setState(() => _currentPosition = pos);
      _mapController.move(LatLng(pos.latitude, pos.longitude), 16.5);

      if (_currentStepIndex < _steps.length - 1) {
        final geo = _steps[_currentStepIndex].geometry;
        if (geo.isNotEmpty) {
          final dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, geo.last.latitude, geo.last.longitude);
          if (dist < 25) setState(() => _currentStepIndex++);
        }
      } else {
        _stopNavigation();
      }
    });
  }

  void _stopNavigation() {
    _positionStream?.cancel();
    _positionStream = null;
    if (mounted) setState(() => _isNavigating = false);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Camera
  // ───────────────────────────────────────────────────────────────────────────

  void _fitCamera() {
    final pts = <LatLng>[
      if (_currentPosition != null) LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      if (_selectedPlace != null) _selectedPlace!.position,
      ..._routePoints,
    ];
    if (pts.length < 2) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _mapController.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(pts), padding: const EdgeInsets.fromLTRB(50, 140, 50, 80)));
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI COMPONENTS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildModeSelector() {
    if (_isNavigating || _selectedPlace == null) return const SizedBox.shrink();

    final modes = [
      {'id': 'car', 'icon': Icons.directions_car, 'label': 'Ô tô'},
      {'id': 'motorbike', 'icon': Icons.motorcycle, 'label': 'Xe máy'},
      {'id': 'walking', 'icon': Icons.directions_walk, 'label': 'Đi bộ'},
      {'id': 'flight', 'icon': Icons.flight, 'label': 'Máy bay'},
    ];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((m) {
          final isSelected = _travelMode == m['id'];
          return GestureDetector(
            onTap: () {
              if (isSelected) return;
              setState(() => _travelMode = m['id'] as String);
              _selectAndRoute(_selectedPlace!);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.red.shade800 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                   Icon(m['icon'] as IconData, size: 18, color: isSelected ? Colors.white : Colors.grey.shade700),
                   if (isSelected) ...[
                     const SizedBox(width: 4),
                     Text(m['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                   ]
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final step = (_isNavigating && _currentStepIndex < _steps.length) ? _steps[_currentStepIndex] : null;
    final hasRoute = _routePoints.isNotEmpty;

    return Scaffold(
      // AppBar: hide during navigation for full-screen feel
      appBar: _isNavigating ? null : AppBar(
        title: Text(_selectedPlace?.name ?? widget.destination, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        actions: [
          if (_nearbyPlaces.length > 1)
            IconButton(
              tooltip: 'Đổi địa điểm',
              icon: const Icon(Icons.list),
              onPressed: _showPlacePicker,
            ),
        ],
      ),
      body: Stack(children: [
        // ── MAP ──
        if (_currentPosition != null)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smart_tet_shopping_manager',
              ),
              // Route polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(polylines: [
                  // Shadow
                  Polyline(
                    points: _routePoints, 
                    color: (_travelMode == 'car' ? Colors.blue.shade900 : 
                            _travelMode == 'motorbike' ? Colors.orange.shade900 : 
                            _travelMode == 'walking' ? Colors.green.shade900 : 
                            Colors.purple.shade900).withOpacity(0.3), 
                    strokeWidth: 9
                  ),
                  // Main line
                  Polyline(
                    points: _routePoints, 
                    color: _travelMode == 'car' ? Colors.blue.shade600 : 
                           _travelMode == 'motorbike' ? Colors.orange.shade600 : 
                           _travelMode == 'walking' ? Colors.green.shade600 : 
                           Colors.purple.shade600, 
                    strokeWidth: 5.5
                  ),
                ]),
              // Markers
              MarkerLayer(markers: [
                // My position
                if (_currentPosition != null)
                  Marker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    width: 44, height: 44,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 3), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)]),
                      child: const Icon(Icons.navigation, color: Colors.blue, size: 22),
                    ),
                  ),
                // Selected destination
                if (_selectedPlace != null)
                  Marker(
                    point: _selectedPlace!.position,
                    width: 140, height: 72,
                    alignment: Alignment.topCenter,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red.shade800, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)]),
                        child: Text(_selectedPlace!.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      ),
                      Icon(Icons.location_on, color: Colors.red.shade800, size: 32),
                    ]),
                  ),
                // Other nearby places (not selected)
                ..._nearbyPlaces.where((p) => p != _selectedPlace).map((p) =>
                  Marker(
                    point: p.position,
                    width: 110, height: 52,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _selectAndRoute(p),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(6)),
                          child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        ),
                        Icon(Icons.storefront, color: Colors.orange.shade700, size: 20),
                      ]),
                    ),
                  )
                ),
              ]),
            ],
          ),

        // ── LOCATING / SEARCHING overlay (semi, doesn't block map) ──
        if (_isLocating || _isSearching)
          Positioned(
            bottom: 90, left: 0, right: 0,
            child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.red)),
                const SizedBox(width: 10),
                Text(_statusMessage, style: const TextStyle(fontSize: 13)),
              ]),
            )),
          ),

        // ── ROUTING indicator or Fallback Button ──
        if (!_isLocating && !_isNavigating && _currentPosition != null)
          Positioned(
            top: 12, left: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)]),
              child: _isRouting
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
                      SizedBox(width: 10), Text('Đang tính đường đi...', style: TextStyle(fontSize: 13)),
                    ])
                  : hasRoute
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(
                                _travelMode == 'car' ? Icons.directions_car :
                                _travelMode == 'motorbike' ? Icons.motorcycle :
                                _travelMode == 'walking' ? Icons.directions_walk : Icons.flight,
                                color: Colors.blue, size: 20
                              ),
                              const SizedBox(width: 8),
                              Text('$_routeDistance  ·  $_routeDuration', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              if (_nearbyPlaces.length > 1) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _showPlacePicker,
                                  child: Text('Đổi địa điểm', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, decoration: TextDecoration.underline)),
                                ),
                              ],
                            ]),
                            _buildModeSelector(),
                          ],
                        )
                      : Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_statusMessage, style: const TextStyle(fontSize: 13, color: Colors.black87), textAlign: TextAlign.center),
                          if (!_isSearching && _nearbyPlaces.isEmpty) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _launchGoogleMaps,
                              icon: const Icon(Icons.map, size: 16),
                              label: const Text('Tìm bằng Google Maps'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ]
                        ]),
            ),
          ),

        // ── NAVIGATION HEADER (full screen Google Maps style) ──
        if (_isNavigating && step != null)
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _travelMode == 'car' ? Colors.blue.shade800 :
                       _travelMode == 'motorbike' ? Colors.orange.shade800 :
                       _travelMode == 'walking' ? Colors.green.shade800 :
                       Colors.purple.shade800,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)]
              ),
              child: Row(children: [
                Icon(
                  _travelMode == 'flight' ? Icons.flight : step.icon,
                  color: Colors.white, size: 42
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(step.instruction, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Sau ${step.distanceLabel}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ])),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _stopNavigation),
              ]),
            )),
          ),

        // ── STEPS draggable panel ──
        if (!_isLocating && hasRoute && !_isNavigating)
          DraggableScrollableSheet(
            initialChildSize: 0.15,
            minChildSize: 0.10,
            maxChildSize: 0.55,
            snap: true,
            snapSizes: const [0.15, 0.55],
            builder: (_, ctl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)), 
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]
              ),
              child: ListView.separated(
                controller: ctl,
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _steps.length + 1, // Header + Steps
                separatorBuilder: (_, i) => i == 0 ? const Divider(height: 1) : const Divider(height: 1, indent: 68),
                itemBuilder: (_, i) {
                  // HEADER (Index 0)
                  if (i == 0) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10), 
                          width: 40, height: 5, 
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3))
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                            children: [
                              Text('${_steps.length} chỉ dẫn · $_routeDistance', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ElevatedButton.icon(
                                onPressed: _startNavigation,
                                icon: const Icon(Icons.navigation, size: 16),
                                label: const Text('Bắt đầu'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade800, 
                                  foregroundColor: Colors.white, 
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                                  textStyle: const TextStyle(fontSize: 12)
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // STEPS (Index 1+)
                  final s = _steps[i - 1];
                  final isCurrent = (i - 1) == _currentStepIndex;
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isCurrent ? Colors.blue.shade700 : Colors.grey.shade200,
                      child: Icon(s.icon, size: 18, color: isCurrent ? Colors.white : Colors.grey.shade700),
                    ),
                    title: Text(s.instruction, style: TextStyle(fontSize: 13, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                    trailing: Text(s.distanceLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  );
                },
              ),
            ),
          ),

        // ── ERROR ──
        if (_errorMessage.isNotEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(onPressed: _bootstrap, icon: const Icon(Icons.refresh), label: const Text('Thử lại'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, foregroundColor: Colors.white)),
            ]),
          )),
      ]),

      // ── FABs ──
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: !_isLocating && _errorMessage.isEmpty && !_isNavigating
          ? Padding(
              padding: EdgeInsets.only(bottom: hasRoute ? 80 : 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (!hasRoute || _isRouting)
                  FloatingActionButton.extended(
                    heroTag: 'search',
                    onPressed: _isSearching ? null : _searchNearby,
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.search),
                    label: const Text('Tìm kiếm'),
                  ),
                if (hasRoute && !_isRouting) ...[
                  FloatingActionButton.extended(
                    heroTag: 'pick',
                    onPressed: _nearbyPlaces.length > 1 ? _showPlacePicker : _searchNearby,
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.store),
                    label: Text(_nearbyPlaces.length > 1 ? 'Đổi điểm (${_nearbyPlaces.length})' : 'Tìm lại'),
                  ),
                ],
              ]),
            )
          : null,
    );
  }
}
