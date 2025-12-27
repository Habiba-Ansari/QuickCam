import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/local_storage_service.dart';
import 'gallery_screen.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraService _cameraService;
  final LocalStorageService _storageService = LocalStorageService();
  bool _isLoading = true;
  bool _isCapturing = false;
  String? _lastSavedImage;
  List<Map<String, dynamic>> _recentImages = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadRecentImages();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameraService = CameraService();
      await _cameraService.initializeCamera();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Camera initialization error: $e');
      _showErrorSnackbar('Camera failed to load: $e');
    }
  }

  Future<void> _loadRecentImages() async {
    try {
      final images = await _storageService.getUserImages();
      setState(() {
        _recentImages = images.take(4).toList();
      });
    } catch (e) {
      print('❌ Error loading recent images: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;
    
    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile imageFile = await _cameraService.takePicture();
      
      // Save to LOCAL storage
      final imagePath = await _storageService.saveImageFromXFile(imageFile);
      
      setState(() {
        _lastSavedImage = imagePath;
      });
      
      // Reload recent images
      await _loadRecentImages();
      
      _showSuccessSnackbar('Photo saved! (Auto-deletes in 30 days)');
      
    } catch (e) {
      print('❌ Error: $e');
      
      if (e.toString().contains('file')) {
        _showErrorSnackbar('Photo file error');
      } else {
        _showErrorSnackbar('Failed to save: $e');
      }
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openFullGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryScreen(),
      ),
    ).then((_) {
      _loadRecentImages();
    });
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : _cameraService.isInitialized
              ? Stack(
                  children: [
                    // 🔥 FULL SCREEN Camera Preview
                    SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _cameraService.controller.value.previewSize!.height,
                          height: _cameraService.controller.value.previewSize!.width,
                          child: CameraPreview(_cameraService.controller),
                        ),
                      ),
                    ),

                    // Top Bar - Simple
                    Positioned(
                      top: 50,
                      left: 20,
                      right: 20,
                      child: SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // App Title
                           

                            // Gallery Icon Button
                            GestureDetector(
                              onTap: _openFullGallery,
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.photo_library,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Saved Indicator - Simple white text
                    if (_lastSavedImage != null)
                      Positioned(
                        top: 100,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Saved',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Capture Button (Center Bottom)
                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          // Capture Button
                          GestureDetector(
                            onTap: _takePicture,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isCapturing ? Colors.grey : Colors.white,
                                border: Border.all(
                                  color: Colors.white, 
                                  width: 3
                                ),
                              ),
                              child: _isCapturing
                                  ? Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.camera,
                                      size: 30,
                                      color: Colors.black,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Camera not available',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeCamera,
                        child: Text('Retry Camera'),
                      ),
                    ],
                  ),
                ),
    );
  }
}