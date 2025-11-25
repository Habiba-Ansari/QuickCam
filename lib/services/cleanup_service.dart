import 'package:supabase_flutter/supabase_flutter.dart';

class CleanupService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Check and delete expired images
  Future<void> cleanupExpiredImages() async {
    try {
      print('🔄 Checking for expired images...');
      
      final response = await supabase
          .from('images')
          .select()
          .lt('expires_at', DateTime.now().toIso8601String());
      
      final expiredImages = List<Map<String, dynamic>>.from(response);
      
      if (expiredImages.isEmpty) {
        print('✅ No expired images found');
        return;
      }
      
      print('🗑️ Found ${expiredImages.length} expired images');
      
      // Delete from database and storage
      for (final image in expiredImages) {
        await _deleteImage(image);
      }
      
      print('✅ Cleanup completed: ${expiredImages.length} images deleted');
    } catch (e) {
      print('❌ Cleanup error: $e');
    }
  }

  // Delete single image from database and storage
  Future<void> _deleteImage(Map<String, dynamic> image) async {
    try {
      final imageUrl = image['image_url'] as String;
      final fileName = extractFileName(imageUrl); // Changed to public method
      
      // Delete from storage
      if (fileName.isNotEmpty) {
        await supabase.storage
            .from('images')
            .remove([fileName]);
      }
      
      // Delete from database
      await supabase
          .from('images')
          .delete()
          .eq('id', image['id']);
      
      print('🗑️ Deleted image: $fileName');
    } catch (e) {
      print('❌ Error deleting image ${image['id']}: $e');
    }
  }

  // Extract filename from URL - CHANGED TO PUBLIC
  String extractFileName(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      return pathSegments.last;
    } catch (e) {
      return '';
    }
  }

  // Get days remaining for an image
  int getDaysRemaining(String expiresAt) {
    try {
      final expiryDate = DateTime.parse(expiresAt);
      final now = DateTime.now();
      final difference = expiryDate.difference(now);
      return difference.inDays;
    } catch (e) {
      return 0;
    }
  }

  // Manual cleanup for testing
  Future<void> manualCleanup() async {
    await cleanupExpiredImages();
  }
}