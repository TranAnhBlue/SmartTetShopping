import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'dart:async';

class LiveCameraScannerScreen extends StatefulWidget {
  const LiveCameraScannerScreen({super.key});

  @override
  State<LiveCameraScannerScreen> createState() => _LiveCameraScannerScreenState();
}

class _LiveCameraScannerScreenState extends State<LiveCameraScannerScreen> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isCapturing = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _onNewCameraSelected(cameraController.description);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _onNewCameraSelected(_cameras.first);
      } else {
        setState(() {
          _errorMessage = "Không tìm thấy camera trên thiết bị này.";
          _isInitialized = true; // Stop showing the spinner
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi khởi tạo danh sách camera: $e";
        _isInitialized = true;
      });
    }
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) setState(() {});
      if (cameraController.value.hasError) {
        setState(() {
          _errorMessage = "Lỗi camera: ${cameraController.value.errorDescription}";
        });
      }
    });

    try {
      await cameraController.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } on CameraException catch (e) {
      setState(() {
        _errorMessage = "Lỗi camera: ${e.description}";
        _isInitialized = true;
      });
    }
  }

  void _toggleCamera() {
    if (_cameras.length < 2) return;
    
    setState(() {
      _isInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });
    
    _onNewCameraSelected(_cameras[_selectedCameraIndex]);
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final XFile file = await _controller!.takePicture();
      
      // Save permanently to gallery (wrap in try-catch to avoid blocking if it fails on emulator)
      try {
        await Gal.putImage(file.path);
      } catch (e) {
        debugPrint('Lỗi khi lưu vào gallery: $e');
      }
      
      if (mounted) {
        Navigator.pop(context, file);
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi khi chụp ảnh: $e";
        _isCapturing = false;
      });
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 16),
              Text('Đang khởi tạo camera...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null && (_controller == null || !_controller!.value.isInitialized)) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    final ImagePicker picker = ImagePicker();
                    picker.pickImage(source: ImageSource.gallery).then((image) {
                      if (image != null && mounted) {
                        Navigator.pop(context, image);
                      }
                    });
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Chọn từ thư viện để thay thế'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Center(
            child: CameraPreview(_controller!),
          ),

          // Overlay UI
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'QUÉT ĐỒ TẾT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer
                    ],
                  ),
                ),

                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Toggle Camera
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 35),
                        onPressed: _cameras.length > 1 ? _toggleCamera : null,
                      ),

                      // Capture Button
                      GestureDetector(
                        onTap: _takePhoto,
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: _isCapturing
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Container(
                                    height: 60,
                                    width: 60,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      // Gallery Fallback (Important for Emulators)
                      IconButton(
                        icon: const Icon(Icons.photo_library, color: Colors.white, size: 35),
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null && mounted) {
                            Navigator.pop(context, image);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Scanning Indicator (Animated or Static)
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                   // Corner markers could be added here
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
