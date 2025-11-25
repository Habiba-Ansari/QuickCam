import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  bool _isInitialized = false;
  
  Future<void> initializeCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        throw Exception('Camera permission denied');
      }
      
      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }
      
      // Initialize controller with back camera
      _controller = CameraController(
        _cameras.first, // Use first available camera
        ResolutionPreset.medium,
        enableAudio: false, // Disable audio for photos
      );
      
      await _controller!.initialize();
      _isInitialized = true;
      
      print('✅ Camera initialized successfully');
    } catch (e) {
      print('❌ Camera initialization error: $e');
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