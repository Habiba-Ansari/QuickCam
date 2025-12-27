// lib/services/local_storage_service.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:camera/camera.dart';

class LocalStorageService {
  static const int DAYS_TO_KEEP = 30;
  
  // Get app's local storage directory
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/quickclick_images';
  }
  
  // Get storage file
  Future<File> _getImageFile(String filename) async {
    final storagePath = await _localPath;
    return File('$storagePath/$filename');
  }
  
  // Get metadata file
  Future<File> _getMetadataFile() async {
    final storagePath = await _localPath;
    return File('$storagePath/_metadata.json');
  }
  
  // Save image from camera
  Future<String> saveImageFromXFile(XFile xFile) async {
    print('💾 Saving image locally...');
    
    try {
      // Create storage directory
      final storagePath = await _localPath;
      await Directory(storagePath).create(recursive: true);
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'quickclick_$timestamp.jpg';
      
      // Read and save image
      final bytes = await xFile.readAsBytes();
      final imageFile = await _getImageFile(filename);
      await imageFile.writeAsBytes(bytes);
      
      // Save metadata
      await _saveMetadata(filename);
      
      print('✅ Image saved locally: $filename');
      print('📍 Path: ${imageFile.path}');
      
      // Clean up old images
      await _cleanupOldImages();
      
      return imageFile.path; // Return local file path
      
    } catch (e) {
      print('❌ Error saving locally: $e');
      throw Exception('Failed to save locally: $e');
    }
  }
  
  // Save metadata for image
  Future<void> _saveMetadata(String filename) async {
    try {
      final metadataFile = await _getMetadataFile();
      Map<String, dynamic> metadata = {};
      
      // Read existing metadata
      if (await metadataFile.exists()) {
        final contents = await metadataFile.readAsString();
        if (contents.isNotEmpty) {
          metadata = json.decode(contents);
        }
      }
      
      // Add new image metadata
      final now = DateTime.now();
      metadata[filename] = {
        'created_at': now.toIso8601String(),
        'expires_at': now.add(Duration(days: DAYS_TO_KEEP)).toIso8601String(),
      };
      
      // Save updated metadata
      await metadataFile.writeAsString(json.encode(metadata));
      print('✅ Metadata saved for $filename');
      
    } catch (e) {
      print('❌ Error saving metadata: $e');
    }
  }
  
  // Get all user images
  Future<List<Map<String, dynamic>>> getUserImages() async {
    try {
      await _cleanupOldImages(); // Clean up first
      
      final metadataFile = await _getMetadataFile();
      if (!await metadataFile.exists()) {
        return [];
      }
      
      // Read metadata
      final contents = await metadataFile.readAsString();
      if (contents.isEmpty) {
        return [];
      }
      
      final metadata = json.decode(contents);
      final List<Map<String, dynamic>> images = [];
      
      // Process each image
      for (var entry in metadata.entries) {
        final filename = entry.key;
        final imageData = Map<String, dynamic>.from(entry.value);
        final imageFile = await _getImageFile(filename);
        
        if (await imageFile.exists()) {
          // Calculate days remaining
          final expiresAt = DateTime.parse(imageData['expires_at']);
          final now = DateTime.now();
          final daysRemaining = expiresAt.difference(now).inDays;
          
          images.add({
            'id': filename,
            'local_path': imageFile.path,
            'image_url': imageFile.path, // Using local path as URL
            'created_at': imageData['created_at'],
            'expires_at': imageData['expires_at'],
            'days_remaining': daysRemaining > 0 ? daysRemaining : 0,
          });
        }
      }
      
      // Sort by newest first
      images.sort((a, b) => b['created_at'].compareTo(a['created_at']));
      
      print('📸 Found ${images.length} local images');
      return images;
      
    } catch (e) {
      print('❌ Error getting local images: $e');
      return [];
    }
  }
  
  // Clean up expired images
  Future<void> _cleanupOldImages() async {
    try {
      final metadataFile = await _getMetadataFile();
      if (!await metadataFile.exists()) {
        return;
      }
      
      final contents = await metadataFile.readAsString();
      if (contents.isEmpty) {
        return;
      }
      
      final metadata = json.decode(contents);
      final now = DateTime.now();
      bool changesMade = false;
      
      // Check each image
      for (var entry in metadata.entries.toList()) {
        final filename = entry.key;
        final imageData = Map<String, dynamic>.from(entry.value);
        final expiresAt = DateTime.parse(imageData['expires_at']);
        
        if (now.isAfter(expiresAt)) {
          // Delete expired image
          final imageFile = await _getImageFile(filename);
          if (await imageFile.exists()) {
            await imageFile.delete();
          }
          
          // Remove from metadata
          metadata.remove(filename);
          changesMade = true;
          
          print('🗑️ Deleted expired image: $filename');
        }
      }
      
      // Save updated metadata
      if (changesMade) {
        await metadataFile.writeAsString(json.encode(metadata));
      }
      
    } catch (e) {
      print('❌ Error during cleanup: $e');
    }
  }
  
  // Delete single image
  Future<void> deleteImage(String filename) async {
    try {
      // Delete image file
      final imageFile = await _getImageFile(filename);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
      
      // Remove from metadata
      final metadataFile = await _getMetadataFile();
      if (await metadataFile.exists()) {
        final contents = await metadataFile.readAsString();
        if (contents.isNotEmpty) {
          final metadata = json.decode(contents);
          metadata.remove(filename);
          await metadataFile.writeAsString(json.encode(metadata));
        }
      }
      
      print('✅ Deleted image: $filename');
      
    } catch (e) {
      print('❌ Error deleting image: $e');
      throw Exception('Failed to delete image');
    }
  }
  
  // Manual cleanup
  Future<void> runCleanup() async {
    await _cleanupOldImages();
  }
  
  // Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final images = await getUserImages();
      double totalSizeMB = 0;
      
      for (var image in images) {
        final file = File(image['local_path']);
        if (await file.exists()) {
          totalSizeMB += (await file.length()) / (1024 * 1024);
        }
      }
      
      return {
        'total_images': images.length,
        'total_size_mb': totalSizeMB.toStringAsFixed(2),
        'storage_path': await _localPath,
      };
      
    } catch (e) {
      return {
        'total_images': 0,
        'total_size_mb': '0.00',
        'storage_path': 'Error',
      };
    }
  }
}