import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/camera_service.dart';
import '../services/supabase_service.dart';
import 'gallery_screen.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraService _cameraService;
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  bool _isCapturing = false;
  String? _lastUploadedImage;
  List<Map<String, dynamic>> _recentImages = [];
  bool _showGalleryPreview = false;

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
      final images = await _supabaseService.getUserImages();
      setState(() {
        _recentImages = images.take(4).toList(); // Get only 4 recent images
      });
    } catch (e) {
      print('Error loading recent images: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;
    
    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile imageFile = await _cameraService.takePicture();
      print('📸 Picture taken: ${imageFile.path}');
      
      final imageUrl = await _supabaseService.uploadImageFromXFile(imageFile);
      
      setState(() {
        _lastUploadedImage = imageUrl;
      });
      
      // Reload recent images to include the new one
      await _loadRecentImages();
      
      _showSuccessSnackbar('✅ Photo saved!');
      
    } catch (e) {
      print('❌ Error taking picture: $e');
      _showErrorSnackbar('Failed to save photo: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _toggleGalleryPreview() {
    setState(() {
      _showGalleryPreview = !_showGalleryPreview;
    });
  }

  void _openFullGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GalleryScreen()),
    ).then((_) {
      // Refresh images when returning from gallery
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
          : Stack(
              children: [
                // Camera Preview (Full Screen)
                CameraPreview(_cameraService.controller),
                
                // Gallery Preview Box
                if (_showGalleryPreview && _recentImages.isNotEmpty)
                  Positioned(
                    top: 80,
                    right: 20,
                    child: _buildGalleryPreview(),
                  ),

                // Top Bar with Gallery Button
                Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Gallery Toggle Button
                        GestureDetector(
                          onTap: _toggleGalleryPreview,
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _showGalleryPreview ? Icons.close : Icons.photo_library,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        // App Title
                        Text(
                          'Camera',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Image Counter
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_recentImages.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
                      if (_lastUploadedImage != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '✅ Saved',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      
                      // Capture Button
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCapturing ? Colors.grey : Colors.white.withOpacity(0.9),
                            border: Border.all(
                              color: _isCapturing ? Colors.grey : Colors.white, 
                              width: 4
                            ),
                          ),
                          child: _isCapturing
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                  ),
                                )
                              : Icon(
                                  Icons.camera,
                                  size: 40,
                                  color: Colors.black,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGalleryPreview() {
    return GestureDetector(
      onTap: _openFullGallery,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white54, width: 1),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gallery',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 12),
                ],
              ),
            ),
            
            // Images Grid
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(4),
                child: _recentImages.isEmpty
                    ? Center(
                        child: Text(
                          'No photos',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: _recentImages.length,
                        itemBuilder: (context, index) {
                          final image = _recentImages[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: image['image_url'],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[800],
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[800],
                                child: Icon(Icons.error, color: Colors.red, size: 16),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}