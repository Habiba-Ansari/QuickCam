import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_service.dart';

class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _images = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      final images = await _supabaseService.getUserImages();
      setState(() {
        _images = images;
        _isLoading = false;
      });
      
      print('📸 Loaded ${_images.length} images');
    } catch (e) {
      print('❌ Error loading images: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _showImageDialog(Map<String, dynamic> image) {
    final daysRemaining = image['days_remaining'] ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: image['image_url'],
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ),
            ),
            
            // Close button
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            
            // Delete button
            Positioned(
              top: 10,
              left: 10,
              child: CircleAvatar(
                backgroundColor: Colors.red,
                child: IconButton(
                  icon: Icon(Icons.delete, color: Colors.white, size: 20),
                  onPressed: () => _showDeleteDialog(image),
                ),
              ),
            ),
            
            // Image info
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uploaded: ${_formatDate(image['created_at'])}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expires: ${_formatDate(image['expires_at'])}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDaysRemainingColor(daysRemaining),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$daysRemaining days left',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Photo?'),
        content: Text('This photo will be permanently deleted from the cloud.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close delete dialog
              Navigator.pop(context); // Close image dialog
              _deleteImage(image);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteImage(Map<String, dynamic> image) async {
    try {
      await _supabaseService.deleteImage(
        image['id'].toString(),
        image['image_url'],
      );
      
      _showSuccessSnackbar('Photo deleted');
      _loadImages(); // Refresh the list
    } catch (e) {
      _showErrorSnackbar('Failed to delete photo: $e');
    }
  }

  Color _getDaysRemainingColor(int days) {
    if (days > 15) return Colors.green;
    if (days > 7) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Gallery'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadImages,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'cleanup') {
                _runCleanup();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'cleanup',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services, size: 20),
                    SizedBox(width: 8),
                    Text('Run Cleanup'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load images',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadImages,
                        child: Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _images.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No photos yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Take some pictures with the camera!',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to camera tab (index 0)
                            },
                            icon: Icon(Icons.camera),
                            label: Text('Open Camera'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadImages,
                      child: GridView.builder(
                        padding: EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          final image = _images[index];
                          final daysRemaining = image['days_remaining'] ?? 0;
                          
                          return GestureDetector(
                            onTap: () => _showImageDialog(image),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  children: [
                                    // Image
                                    CachedNetworkImage(
                                      imageUrl: image['image_url'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[300],
                                        child: Icon(Icons.error, color: Colors.red),
                                      ),
                                    ),
                                    
                                    // Days remaining indicator
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getDaysRemainingColor(daysRemaining),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${daysRemaining}d',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Expired overlay
                                    if (daysRemaining <= 0)
                                      Container(
                                        color: Colors.black54,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.warning, color: Colors.white, size: 24),
                                              SizedBox(height: 4),
                                              Text(
                                                'EXPIRED',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Future<void> _runCleanup() async {
    try {
      await _supabaseService.runCleanup();
      _showSuccessSnackbar('Cleanup completed');
      _loadImages(); // Refresh the list
    } catch (e) {
      _showErrorSnackbar('Cleanup failed: $e');
    }
  }
}