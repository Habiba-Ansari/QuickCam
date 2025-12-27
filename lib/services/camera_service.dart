// lib/services/camera_service.dart
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  
  Future<void> initializeCamera() async {
    try {
      print('🔍 Requesting camera permission...');
      
      // Request camera permission
      final status = await Permission.camera.request();
      print('📋 Permission status: $status');
      
      if (!status.isGranted) {
        throw Exception('Camera permission denied');
      }
      
      // Get available cameras
      final cameras = await availableCameras();
      print('📷 Available cameras: ${cameras.length}');
      
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }
      
      // Log all cameras
      for (var i = 0; i < cameras.length; i++) {
        print('Camera $i: ${cameras[i].name} - ${cameras[i].lensDirection}');
      }
      
      // Use back camera
      CameraDescription camera;
      try {
        camera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
        );
        print('✅ Using back camera: ${camera.name}');
      } catch (e) {
        camera = cameras.first;
        print('⚠️ Using first camera (no back camera found): ${camera.name}');
      }
      
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      print('🔄 Initializing camera controller...');
      await _controller!.initialize();
      
      // Check if camera is properly initialized
      if (!_controller!.value.isInitialized) {
        throw Exception('Camera failed to initialize');
      }
      
      print('📐 Preview size: ${_controller!.value.previewSize}');
      print('📐 Aspect ratio: ${_controller!.value.aspectRatio}');
      
      _isInitialized = true;
      print('✅ Camera successfully initialized!');
      
    } catch (e) {
      print('❌ Camera init error: $e');
      rethrow;
    }
  }
  
  CameraController get controller {
    if (_controller == null || !_isInitialized) {
      throw Exception('Camera not initialized');
    }
    return _controller!;
  }
  
  Future<XFile> takePicture() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }
    
    if (!_controller!.value.isInitialized) {
      throw Exception('Camera controller not ready');
    }
    
    try {
      return await _controller!.takePicture();
    } catch (e) {
      print('❌ Error taking picture: $e');
      rethrow;
    }
  }
  
  Future<void> dispose() async {
    await _controller?.dispose();
    _isInitialized = false;
  }
  
  bool get isInitialized => _isInitialized;
}