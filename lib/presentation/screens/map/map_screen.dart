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
    setState(() { _isSearching = true; _statusMessage = 'Đang tìm ${widget.destination} gần bạn...'; _nearbyPlaces = []; });

    final lat = _currentPosition!.latitude;
    final lon = _currentPosition!.longitude;

    // Tìm trong 25km, mở rộng qua brand và operator vì OSM VN hay tag thiếu name
    final query = '''
[out:json][timeout:20];
(
  node["name"~"${widget.destination}",i](around:25000,$lat,$lon);
  way["name"~"${widget.destination}",i](around:25000,$lat,$lon);
  node["brand"~"${widget.destination}",i](around:25000,$lat,$lon);
  way["brand"~"${widget.destination}",i](around:25000,$lat,$lon);
  node["operator"~"${widget.destination}",i](around:25000,$lat,$lon);
  way["operator"~"${widget.destination}",i](around:25000,$lat,$lon);
);
out center 10;
''';

    // Danh sách Overpass servers để fallback nếu server chính bị chậm
    final servers = [
      'https://overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
    ];

    http.Response? res;
    for (final server in servers) {
      try {
        res = await http
            .post(Uri.parse(server), body: {'data': query})
            .timeout(const Duration(seconds: 25));
        if (res.statusCode == 200) break; // success
        res = null;
      } catch (e) {
        debugPrint('Overpass server $server failed: $e');
        res = null;
      }
    }

    if (res == null || res.statusCode != 200) {
      if (mounted) setState(() { _isSearching = false; _statusMessage = 'Không thể tìm kiếm. Bấm nút thử lại.'; });
      return;
    }
    try {
      final elements = (json.decode(res.body)['elements'] as List);
      final places = <_NearbyPlace>[];

      for (final e in elements) {
        final eLat = (e['lat'] ?? e['center']?['lat'] as num?)?.toDouble();
        final eLon = (e['lon'] ?? e['center']?['lon'] as num?)?.toDouble();
        if (eLat == null || eLon == null) continue;

        final tags = e['tags'] as Map? ?? {};
        final name = tags['name']?.toString() ?? widget.destination;
        final addr = [
          tags['addr:street'],
          tags['addr:suburb'],
          tags['addr:district'],
        ].where((s) => s != null).join(', ');

        final distM = Geolocator.distanceBetween(lat, lon, eLat, eLon);
        places.add(_NearbyPlace(
          name: name,
          position: LatLng(eLat, eLon),
          address: addr,
          distanceKm: distM / 1000,
        ));
      }

      // Sort nearest first
      places.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      if (mounted) {
        setState(() {
          _nearbyPlaces = places;
          _isSearching = false;
          _statusMessage = places.isEmpty
              ? 'Không tìm thấy "${widget.destination}" trong 25km.'
              : 'Chọn ${widget.destination} gần bạn:';
        });

        if (places.length == 1) {
          await _selectAndRoute(places[0]);
        } else if (places.isNotEmpty) {
          _showPlacePicker();
        }
      }
    } catch (e) {
      debugPrint('Overpass parse error: $e');
      if (mounted) setState(() { _isSearching = false; _statusMessage = 'Không thể tìm kiếm. Bấm nút thử lại.'; });
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
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$oLon,$oLat;${dest.longitude},${dest.latitude}'
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
      if (mounted) _mapController.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(pts), padding: const EdgeInsets.fromLTRB(50, 100, 50, 80)));
    });
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
                  Polyline(points: _routePoints, color: Colors.blue.shade900.withOpacity(0.3), strokeWidth: 9),
                  // Main line
                  Polyline(points: _routePoints, color: Colors.blue.shade600, strokeWidth: 5.5),
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
                      ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.route, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text('$_routeDistance  ·  $_routeDuration', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          if (_nearbyPlaces.length > 1) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _showPlacePicker,
                              child: Text('Đổi địa điểm', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, decoration: TextDecoration.underline)),
                            ),
                          ],
                        ])
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
              decoration: BoxDecoration(color: Colors.blue.shade800, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)]),
              child: Row(children: [
                Icon(step.icon, color: Colors.white, size: 42),
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
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20)), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
              child: Column(children: [
                Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${_steps.length} bước · $_routeDistance', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ElevatedButton.icon(
                      onPressed: _startNavigation,
                      icon: const Icon(Icons.navigation, size: 16),
                      label: const Text('Bắt đầu'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), textStyle: const TextStyle(fontSize: 12)),
                    ),
                  ]),
                ),
                const Divider(),
                Expanded(child: ListView.separated(
                  controller: ctl,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: _steps.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = _steps[i];
                    final isCurrent = i == _currentStepIndex;
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
                )),
              ]),
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
