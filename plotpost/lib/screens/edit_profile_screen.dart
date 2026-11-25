import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    this.initialName = '',
    this.initialAgency = '',
    this.initialRole = '',
    this.initialLocation = '',
    this.initialPhone = '',
    this.initialEmail = '',
    this.initialBio = '',
    this.initialProfileImage = '',
    this.onSaved,
  });

  final String initialName;
  final String initialAgency;
  // Shown as "Role / Designation"; saved as `designation` on the server.
  final String initialRole;
  final String initialLocation;
  final String initialPhone;
  final String initialEmail;
  final String initialBio;
  final String initialProfileImage;
  final ValueChanged<Map<String, String>>? onSaved;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _agencyController;
  late final TextEditingController _roleController;
  late final TextEditingController _locationController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;

  // A newly picked photo (uploaded on Save) and the current online photo.
  XFile? _pickedImage;
  String? _profileImagePath;
  late String _remoteImageUrl;
  bool _removePhoto = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _agencyController = TextEditingController(text: widget.initialAgency);
    _roleController = TextEditingController(text: widget.initialRole);
    _locationController = TextEditingController(text: widget.initialLocation);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _emailController = TextEditingController(text: widget.initialEmail);
    _bioController = TextEditingController(text: widget.initialBio);
    _remoteImageUrl = widget.initialProfileImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _agencyController.dispose();
    _roleController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _pickedImage = picked;
          _profileImagePath = picked.path;
          _removePhoto = false;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open image picker.')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    // Photo first: if it fails, nothing else has changed yet.
    if (_pickedImage != null) {
      final upload = await ApiService.uploadProfilePhoto(_pickedImage!);
      if (!mounted) return;
      if (upload['success'] != true) {
        setState(() => _isSaving = false);
        _showError(upload['message']?.toString() ?? 'Could not upload the photo.');
        return;
      }
      _remoteImageUrl = upload['imageUrl']?.toString() ?? _remoteImageUrl;
      // Uploaded: don't send it again if the rest of the save needs a retry.
      _pickedImage = null;
    } else if (_removePhoto && _remoteImageUrl.isNotEmpty) {
      final removed = await ApiService.deleteProfilePhoto();
      if (!mounted) return;
      if (removed['success'] != true) {
        setState(() => _isSaving = false);
        _showError(removed['message']?.toString() ?? 'Could not remove the photo.');
        return;
      }
      _remoteImageUrl = '';
      _removePhoto = false;
    }

    final res = await ApiService.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      agency: _agencyController.text.trim(),
      designation: _roleController.text.trim(),
      location: _locationController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    final bool success = res['success'] == true;
    if (!success) {
      _showError(res['message']?.toString() ?? 'Could not save your profile.');
      return;
    }
    final updatedData = <String, String>{
      'name': _nameController.text.trim(),
      'agency': _agencyController.text.trim(),
      'role': _roleController.text.trim(),
      'location': _locationController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'bio': _bioController.text.trim(),
      'profileImage': _remoteImageUrl,
      if (_profileImagePath != null) 'imagePath': _profileImagePath!,
    };

    widget.onSaved?.call(updatedData);

    Navigator.of(context).pop(updatedData);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(res['message']?.toString() ?? 'Profile updated successfully.'),
          ],
        ),
        backgroundColor: success ? const Color(0xFF1E40AF) : Colors.red,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  ImageProvider? get _avatarImage {
    if (_profileImagePath != null) return FileImage(File(_profileImagePath!));
    if (!_removePhoto && _remoteImageUrl.startsWith('http')) {
      return NetworkImage(_remoteImageUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: plotPostTextAccent(context, theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Picker Container
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: theme.colorScheme.primary,
                        backgroundImage: _avatarImage,
                        child: _avatarImage == null
                            ? Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _pickImage,
                child: Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: plotPostTextAccent(
                      context,
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              if (_avatarImage != null)
                TextButton(
                  onPressed: () => setState(() {
                    _pickedImage = null;
                    _profileImagePath = null;
                    _removePhoto = true;
                  }),
                  child: Text(
                    'Remove Photo',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Form Input Fields
              _buildSectionTitle('Personal Details', theme),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter your full name'
                    : null,
                isDark: isDark,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _agencyController,
                label: 'Agency / Business Name',
                icon: Icons.business_rounded,
                isDark: isDark,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _roleController,
                label: 'Role / Designation',
                icon: Icons.badge_outlined,
                isDark: isDark,
                theme: theme,
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('Contact & Location', theme),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter a contact phone number';
                  }
                  if (!RegExp(r'^[0-9+()\-\s]{6,20}$').hasMatch(val.trim())) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
                isDark: isDark,
                theme: theme,
              ),
              const SizedBox(height: 12),
              // Email can't be changed here yet; it is the login.
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
                isDark: isDark,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _locationController,
                label: 'Location / City',
                icon: Icons.location_on_outlined,
                isDark: isDark,
                theme: theme,
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('About & Bio', theme),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _bioController,
                label: 'Bio / Description',
                icon: Icons.notes_rounded,
                maxLines: 3,
                isDark: isDark,
                theme: theme,
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Profile Changes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
    required bool isDark,
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      readOnly: readOnly,
      style: TextStyle(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF222630) : const Color(0xFFF6F8FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2D3342) : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2D3342) : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
      ),
    );
  }
}
