import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../services/auth_service.dart';
import '../services/avatar_service.dart';
import '../services/profile_service.dart';

class SmartAvatar extends StatefulWidget {
  final double size;
  final bool isEditable;
  final VoidCallback? onTap;

  const SmartAvatar({
    super.key,
    this.size = 60,
    this.isEditable = false,
    this.onTap,
  });

  @override
  State<SmartAvatar> createState() => _SmartAvatarState();
}

class _SmartAvatarState extends State<SmartAvatar> {
  final AuthService _auth = AuthService();
  final AvatarService _avatarService = AvatarService();
  final ProfileService _profileService = ProfileService();
  final SupabaseClient _client = SupabaseClientManager.instance;
  
  String? _profileAvatarUrl;
  bool _isLoadingProfile = true;
  
  bool _isUploading = false;
  File? _localPreview; // For instant preview before upload finishes

  @override
  void initState() {
    super.initState();
    _fetchLatestProfile();
  }

  Future<void> _fetchLatestProfile() async {
    final user = _auth.user;
    if (user != null) {
      final profile = await _profileService.fetchProfile(user.id);
      if (mounted) {
        setState(() {
          _profileAvatarUrl = profile?.avatarUrl;
          _isLoadingProfile = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _auth.authStateChanges,
      builder: (context, snapshot) {
        final user = _auth.user;
        if (user == null) return _buildPlaceholder();

        final metadata = user.userMetadata ?? {};
        final String? metadataCustomUrl = metadata['custom_avatar_url'];
        final String? providerUrl = metadata['avatar_url'] ?? metadata['picture'];
        
        // Priority: 
        // 1. Local Preview (picking)
        // 2. Profiles Table URL (Fetched in initState)
        // 3. Metadata Custom URL (Sync fallback)
        // 4. Provider URL (Google)
        final String? displayUrl = _profileAvatarUrl ?? metadataCustomUrl ?? providerUrl;

        return Stack(
          children: [
            // The Avatar
            GestureDetector(
              onTap: widget.isEditable ? _showEditOptions : widget.onTap,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: ClipOval(
                  child: _buildAvatarContent(displayUrl),
                ),
              ),
            ),

            // Loading Indicator
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),

            // Edit Badge (Only if editable)
            if (widget.isEditable && !_isUploading)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showEditOptions,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined, // Changed to camera icon for profile look
                      size: 14,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAvatarContent(String? url) {
    // 1. If we have a local preview (just picked/cropping/uploading)
    if (_localPreview != null) {
      return Image.file(_localPreview!, fit: BoxFit.cover);
    }

    // 2. If we have a URL
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade50,
          child: const Center(child: Icon(Icons.person, color: Colors.grey)),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }

    // 3. Falling back to placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Image.asset(
      'assets/images/default_avatar.png',
      fit: BoxFit.cover,
      width: widget.size,
      height: widget.size,
      errorBuilder: (_, __, ___) => Center(
        child: Icon(Icons.person, size: widget.size * 0.5, color: Colors.grey.shade400),
      ),
    );
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.black87),
              title: const Text('Upload new photo'),
              onTap: () {
                Navigator.pop(context);
                _handleUpload();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove current photo', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleRemove();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpload() async {
    try {
      final file = await _avatarService.pickAndCropImage();
      if (file == null) return;

      setState(() {
        _localPreview = file; // Instant Preview!
        _isUploading = true;
      });

      final userId = _auth.user!.id;
      final url = await _avatarService.uploadAvatar(file, userId);
      
      // 1. Update Profiles Table
      await _profileService.updateProfile(userId, {'avatar_url': url});
      
      // 2. Update Auth Metadata (for sync across app)
      await _auth.updateCustomAvatar(url);
      
      if (mounted) {
        setState(() => _profileAvatarUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Avatar updated successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _localPreview = null; // Clear local preview as DB update should trigger Stream rebuild
        });
      }
    }
  }

  Future<void> _handleRemove() async {
    setState(() => _isUploading = true);
    try {
      final userId = _auth.user!.id;
      await _avatarService.deleteAvatar(userId);
      
      // 1. Update Profiles Table
      await _profileService.updateProfile(userId, {'avatar_url': null});
      
      // 2. Update Auth Metadata
      await _auth.updateCustomAvatar(null);
      
       if (mounted) {
         setState(() => _profileAvatarUrl = null);
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Avatar removed")),
         );
       }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
