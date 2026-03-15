import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  final String destination;

  const MapScreen({super.key, required this.destination});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _errorMessage = '';
  Position? _currentPosition; // Store position for reuse

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final String url = request.url;
            
            // Allow all standard web navigations
            if (url.startsWith('http://') || url.startsWith('https://')) {
              return NavigationDecision.navigate;
            }
            
            // Handle external schemes (e.g., intent:, maps:, tel:, google.navigation:)
            _handleExternalScheme(url);
            return NavigationDecision.prevent;
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Filter out errors caused by blocked schemes (intent, maps, etc)
            // or errors that are actually normal for some JS redirects
            if (error.description.contains('ERR_UNKNOWN_URL_SCHEME') || 
                error.description.contains('net::ERR_ABORTED')) {
              return;
            }
            if (mounted) {
              setState(() {
                _errorMessage = 'Lỗi tải bản đồ: ${error.description} (Mã: ${error.errorCode})';
                _isLoading = false;
              });
            }
          },
        ),
      );

    _initMap();
  }

  Future<void> _initMap() async {
    try {
      // 1. Get current location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Dịch vụ định vị đang tắt. Vui lòng bật nó lên.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Quyền truy cập vị trí bị từ chối.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Quyền truy cập vị trí bị từ chối vĩnh viễn.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position; // Cache for reuse

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác định được vị trí của bạn')),
        );
      }

      // 2. Generate Google Maps Directions URL
      final String destinationEncoded = Uri.encodeComponent(widget.destination);
      final String origin = '${position.latitude},${position.longitude}';
      
      // Using /dir/ for explicit routing from user's origin
      final String url = 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destinationEncoded&travelmode=driving&hl=vi';

      _controller.loadRequest(Uri.parse(url));

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Mở Google Maps app để bắt đầu chỉ đường thật sự
  Future<void> _openNavigationInApp() async {
    try {
      final destination = Uri.encodeComponent(widget.destination);

      // 📍 Điểm xuất phát: Đại học FPT Hà Nội - Khu CNC Hòa Lạc
      const double originLat = 21.0122;
      const double originLon = 105.5258;

      final mapsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLon&destination=$destination&travelmode=driving'
      );

      final launched = await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        debugPrint('Could not open Google Maps');
      }
    } catch (e) {
      debugPrint('Error opening navigation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở Google Maps: $e')),
        );
      }
    }
  }

  Future<void> _handleExternalScheme(String urlString) async {
    // Khi WebView nhận scheme ngoài http/https (ví dụ intent:, google.navigation:)
    // ta chuyển sang mở Google Maps app thật sự thay vì cố parse URL phức tạp
    if (urlString.startsWith('intent:') ||
        urlString.startsWith('google.navigation:') ||
        urlString.startsWith('maps:')) {
      await _openNavigationInApp();
      return;
    }

    try {
      final Uri url = Uri.parse(urlString);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching external scheme: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chỉ đường đến ${widget.destination}'),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _errorMessage = '';
                          _isLoading = true;
                        });
                        _initMap();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
            
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNavigationInApp,
        label: const Text('Bắt đầu điều hướng'),
        icon: const Icon(Icons.navigation),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
    );
  }
}
