import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:camera/camera.dart';

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Upload image from XFile
  Future<String> uploadImageFromXFile(XFile xFile) async {
    await ensureAuth();
    
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Uint8List imageBytes = await xFile.readAsBytes();
    
    try {
      final uploadResponse = await supabase.storage
          .from('images')
          .uploadBinary(fileName, imageBytes);
      
      final publicUrl = supabase.storage
          .from('images')
          .getPublicUrl(fileName);
      
      await storeImageMetadata(publicUrl, fileName);
      
      return publicUrl;
    } catch (e) {
      print('❌ Upload error: $e');
      rethrow;
    }
  }

  // Store image metadata
  Future<void> storeImageMetadata(String imageUrl, String fileName) async {
    final user = supabase.auth.currentUser!;
    
    await supabase.from('images').insert({
      'user_id': user.id,
      'image_url': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(Duration(days: 30)).toIso8601String(),
    });
  }

  // Get user images
  Future<List<Map<String, dynamic>>> getUserImages() async {
    await ensureAuth();
    
    final user = supabase.auth.currentUser!;
    
    final response = await supabase
        .from('images')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    
    final images = List<Map<String, dynamic>>.from(response);
    
    for (final image in images) {
      final daysRemaining = getDaysRemaining(image['expires_at']);
      image['days_remaining'] = daysRemaining;
    }
    
    return images;
  }

  // Delete image
  Future<void> deleteImage(String imageId, String imageUrl) async {
    try {
      final fileName = extractFileName(imageUrl);
      
      if (fileName.isNotEmpty) {
        await supabase.storage.from('images').remove([fileName]);
      }
      
      await supabase.from('images').delete().eq('id', imageId);
    } catch (e) {
      rethrow;
    }
  }

  // Cleanup expired images
  Future<void> cleanupExpiredImages() async {
    try {
      final response = await supabase
          .from('images')
          .select()
          .lt('expires_at', DateTime.now().toIso8601String());
      
      final expiredImages = List<Map<String, dynamic>>.from(response);
      
      for (final image in expiredImages) {
        final imageUrl = image['image_url'] as String;
        final fileName = extractFileName(imageUrl);
        
        if (fileName.isNotEmpty) {
          await supabase.storage.from('images').remove([fileName]);
        }
        
        await supabase.from('images').delete().eq('id', image['id']);
      }
    } catch (e) {
      print('Cleanup error: $e');
    }
  }

  // ADD THIS METHOD - Fixes the error
  Future<void> runCleanup() async {
    await cleanupExpiredImages();
  }

  // Helper methods
  Future<void> ensureAuth() async {
    if (supabase.auth.currentUser == null) {
      final randomEmail = 'anonymous_${DateTime.now().millisecondsSinceEpoch}@temp.com';
      final randomPassword = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      
      await supabase.auth.signUp(
        email: randomEmail,
        password: randomPassword,
      );
    }
  }

  String extractFileName(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      return uri.pathSegments.last;
    } catch (e) {
      return '';
    }
  }

  int getDaysRemaining(String expiresAt) {
    try {
      final expiryDate = DateTime.parse(expiresAt);
      final now = DateTime.now();
      return expiryDate.difference(now).inDays;
    } catch (e) {
      return 0;
    }
  }
}