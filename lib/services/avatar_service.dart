import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import '../core/supabase_client.dart';

class AvatarService {
  final SupabaseClient _client = SupabaseClientManager.instance;
  final ImagePicker _picker = ImagePicker();

  /// Picks an image and applies basic compression/resizing via image_picker.
  /// This avoids complex cropping activities that cause crashes.
  Future<File?> pickAndCropImage() async {
    // Keeping the name 'pickAndCropImage' to avoid breaking SmartAvatar, 
    // but the logic is now simplified.
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, // Sufficient for circular profile pic
        maxHeight: 512,
        imageQuality: 85, // Built-in compression
      );
      
      if (pickedFile == null) return null;
      return File(pickedFile.path);

    } catch (e) {
      debugPrint("❌ [AvatarService] Pick Error: $e");
      return null;
    }
  }

  Future<String?> uploadAvatar(File file, String userId) async {
    try {
      final fileName = '$userId.jpg';

      // Upload (Overwrite existing using upsert: true)
      await _client.storage.from('avatars').upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      // Get Public URL
      final publicUrl = _client.storage.from('avatars').getPublicUrl(fileName);
      
      // Cache bust using timestamp
      return "$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}";

    } catch (e) {
      debugPrint("❌ [AvatarService] Upload Error: $e");
      rethrow;
    }
  }

  Future<void> deleteAvatar(String userId) async {
    try {
       await _client.storage.from('avatars').remove(['$userId.jpg']);
    } catch (e) {
      debugPrint("⚠️ [AvatarService] Delete Warning: $e");
    }
  }
}
