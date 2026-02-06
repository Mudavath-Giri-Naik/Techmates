import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/smart_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();
  final ProfileService _profileService = ProfileService();

  late TextEditingController _nameController;
  late TextEditingController _linkedinController;
  late TextEditingController _githubController;
  late TextEditingController _instagramController;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditMode = false;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _linkedinController = TextEditingController();
    _githubController = TextEditingController();
    _instagramController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.user;
    if (user == null) return;

    try {
      final profile = await _profileService.fetchProfile(user.id);
      if (mounted) {
        setState(() {
          _profile = profile;
          // If no profile exists, go to edit mode automatically
          _isEditMode = profile == null;
          
          if (profile != null) {
            _nameController.text = profile.name ?? '';
            _linkedinController.text = profile.linkedinUrl ?? '';
            _githubController.text = profile.githubUrl ?? '';
            _instagramController.text = profile.instagramUrl ?? '';
          }
        });
      }
    } catch (e) {
      debugPrint("❌ [EditProfileScreen] Error loading profile: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final userId = _auth.user!.id;
      final data = {
        'name': _nameController.text.trim(),
        'linkedin_url': _linkedinController.text.trim(),
        'github_url': _githubController.text.trim(),
        'instagram_url': _instagramController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _profileService.updateProfile(userId, data);
      
      // Reload profile and switch to view mode
      await _loadProfile();
      
      if (mounted) {
        setState(() => _isEditMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    
    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'https://$url';
    }
    
    final uri = Uri.parse(formattedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Profile' : 'Profile',
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (!_isLoading && !_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditMode = true),
            ),
          if (_isEditMode)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _isEditMode 
          ? _buildEditMode()
          : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Avatar Section
          const SmartAvatar(size: 100, isEditable: true),
          const SizedBox(height: 16),
          
          // Name
          Text(
            _profile?.name ?? 'No name set',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // Email
          Text(
            _auth.user?.email ?? '',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          
          const SizedBox(height: 32),
          
          // Social Links
          if (_profile?.linkedinUrl != null || _profile?.githubUrl != null || _profile?.instagramUrl != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SOCIAL LINKS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                if (_profile?.linkedinUrl?.isNotEmpty == true)
                  _buildSocialTile(
                    icon: Icons.link,
                    label: 'LinkedIn',
                    url: _profile!.linkedinUrl!,
                    color: Colors.blue,
                  ),
                if (_profile?.githubUrl?.isNotEmpty == true)
                  _buildSocialTile(
                    icon: Icons.code,
                    label: 'GitHub',
                    url: _profile!.githubUrl!,
                    color: Colors.black87,
                  ),
                if (_profile?.instagramUrl?.isNotEmpty == true)
                  _buildSocialTile(
                    icon: Icons.camera_alt_outlined,
                    label: 'Instagram',
                    url: _profile!.instagramUrl!,
                    color: Colors.pink,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSocialTile({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      subtitle: Text(url, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => _launchUrl(url),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildEditMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Section
            Center(
              child: Column(
                children: [
                  const SmartAvatar(size: 100, isEditable: true),
                  const SizedBox(height: 12),
                  Text(
                    _auth.user?.email ?? '',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('Basic Information'),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your name',
              icon: Icons.person_outline,
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Social Links'),
            _buildTextField(
              controller: _linkedinController,
              label: 'LinkedIn URL',
              hint: 'linkedin.com/in/username',
              icon: Icons.link,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _githubController,
              label: 'GitHub URL',
              hint: 'github.com/username',
              icon: Icons.code,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _instagramController,
              label: 'Instagram URL',
              hint: 'instagram.com/username',
              icon: Icons.camera_alt_outlined,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: Colors.blue.shade800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
