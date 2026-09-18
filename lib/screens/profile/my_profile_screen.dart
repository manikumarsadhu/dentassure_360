import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../utils/auth_error_handler.dart';
import '../../widgets/profile_photo_viewer.dart';
import '../../widgets/user_avatar.dart';

class MyProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  const MyProfileScreen({super.key, required this.userProfile});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  bool _uploadingAvatar = false;

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ==========================================
  // AVATAR PICKING & UPLOAD METHODS
  // ==========================================

  void _viewProfilePhoto(UserProfile profile) {
    if (_uploadingAvatar) return;
    if (profile.avatarUrl.trim().isEmpty) {
      _showAvatarOptions(profile);
      return;
    }
    ProfilePhotoViewer.open(
      context,
      avatarUrl: profile.avatarUrl,
      name: profile.name,
    );
  }

  void _showAvatarOptions(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Profile Photo Options',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                if (profile.avatarUrl.trim().isNotEmpty)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEDE7F6),
                      child: Icon(
                        Icons.zoom_out_map_rounded,
                        color: Color(0xFF5E35B1),
                      ),
                    ),
                    title: const Text(
                      'View Photo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Open full-screen enlarged view'),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      ProfilePhotoViewer.open(
                        context,
                        avatarUrl: profile.avatarUrl,
                        name: profile.name,
                      );
                    },
                  ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F0FE),
                    child: Icon(
                      Icons.upload_file_rounded,
                      color: Color(0xFF0066CC),
                    ),
                  ),
                  title: const Text(
                    'Upload from System',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Choose JPG/PNG file from computer or gallery',
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickAndUploadFromSystem(profile);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.link_rounded, color: Colors.green),
                  ),
                  title: const Text(
                    'Provide Image URL',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Paste a public image link directly'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showImageUrlDialog(profile);
                  },
                ),
                if (profile.avatarUrl.isNotEmpty)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFEBEE),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                      ),
                    ),
                    title: const Text(
                      'Remove Photo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    subtitle: const Text(
                      'Revert back to default avatar initials',
                    ),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _removeAvatar(profile);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadFromSystem(UserProfile profile) async {
    setState(() => _uploadingAvatar = true);
    try {
      final downloadUrl = await _storageService.pickAndUploadAvatar(
        profile.uid,
      );
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        await _firestoreService.updateAvatarUrl(
          uid: profile.uid,
          avatarUrl: downloadUrl,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload photo: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
      }
    }
  }

  Future<void> _showImageUrlDialog(UserProfile profile) async {
    final urlController = TextEditingController(text: profile.avatarUrl);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Photo URL'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter a direct web URL to an image file (e.g. https://example.com/avatar.jpg).',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Image Web URL',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.link_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter an image URL';
                    }
                    if (!val.trim().startsWith('http://') &&
                        !val.trim().startsWith('https://')) {
                      return 'URL must begin with http:// or https://';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext);

                try {
                  await _firestoreService.updateAvatarUrl(
                    uid: profile.uid,
                    avatarUrl: urlController.text.trim(),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile photo URL updated!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update URL: $e'),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Save Photo'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeAvatar(UserProfile profile) async {
    try {
      await _firestoreService.updateAvatarUrl(uid: profile.uid, avatarUrl: '');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo removed.'),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove photo: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================
  // EDIT PERSONAL DETAILS
  // ==========================================

  Future<void> _showEditProfileDialog(UserProfile profile) async {
    final nameController = TextEditingController(text: profile.name);
    final phoneController = TextEditingController(text: profile.phone);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Personal Information'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Update your personal profile details. Organization assignments remain managed by your administrator.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          if (val.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => saving = true);

                          try {
                            final updated = profile.copyWith(
                              name: nameController.text.trim(),
                              phone: phoneController.text.trim(),
                            );
                            await _firestoreService.updateUserProfile(updated);

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile details updated!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => saving = false);
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Update failed: $e'),
                                backgroundColor: Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // CHANGE PASSWORD & SECURITY
  // ==========================================

  Future<void> _showChangePasswordDialog(UserProfile profile) async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool updating = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Enter a new password for your account (minimum 6 characters).',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setDialogState(() => obscureNew = !obscureNew);
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setDialogState(
                                () => obscureConfirm = !obscureConfirm,
                              );
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please confirm password';
                          }
                          if (val != newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: updating
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: updating
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => updating = true);

                          try {
                            await _authService.updatePassword(
                              newPasswordController.text,
                            );

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password changed successfully!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => updating = false);
                            if (!dialogContext.mounted) return;
                            final msg = AuthErrorHandler.getErrorMessage(e);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: updating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Update Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendPasswordResetEmail(UserProfile profile) async {
    try {
      await _authService.resetPassword(profile.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset link sent to ${profile.email}! Please check your inbox.',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = AuthErrorHandler.getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of Dentassure 360?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  // ==========================================
  // BUILD METHOD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<UserProfile?>(
      stream: _firestoreService.streamUserProfile(widget.userProfile.uid),
      initialData: widget.userProfile,
      builder: (context, snapshot) {
        final profile = snapshot.data ?? widget.userProfile;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Profile',
                onPressed: () => _showEditProfileDialog(profile),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Sign Out',
                onPressed: _handleSignOut,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Banner & Avatar Header
                Card(
                  elevation: 0,
                  color: profile.isPlatformAdmin
                      ? Colors.indigo.shade900
                      : theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.5,
                        ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: profile.isPlatformAdmin
                          ? Colors.indigo.shade700
                          : theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        // Stack for Avatar and Camera Badge
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _viewProfilePhoto(profile),
                                child: Tooltip(
                                  message: profile.avatarUrl.trim().isEmpty
                                      ? 'Add profile photo'
                                      : 'View photo',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: UserAvatar(
                                      key: ValueKey(profile.avatarUrl),
                                      avatarUrl: profile.avatarUrl,
                                      name: profile.name,
                                      radius: 48,
                                      fontSize: 40,
                                      backgroundColor: profile.isPlatformAdmin
                                          ? Colors.indigo.shade400
                                          : theme.colorScheme.primary,
                                      textColor: Colors.white,
                                      child: _uploadingAvatar
                                          ? const SizedBox(
                                              width: 32,
                                              height: 32,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 3,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Camera Icon Button
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: _uploadingAvatar
                                    ? null
                                    : () => _showAvatarOptions(profile),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Name
                        Text(
                          profile.name.isNotEmpty ? profile.name : 'User Name',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: profile.isPlatformAdmin
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Designation & Department
                        Text(
                          profile.isPlatformAdmin
                              ? 'Platform Super Administrator'
                              : '${profile.designation} • ${profile.department}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: profile.isPlatformAdmin
                                ? Colors.indigo.shade100
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Badges Row (Role & Status)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: profile.isPlatformAdmin
                                    ? Colors.amber.shade700
                                    : theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                profile.role,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: profile.isActive
                                    ? Colors.green.shade600
                                    : Colors.red.shade600,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    profile.isActive
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // SECTION 1: Personal & Contact Information
                _SectionTitle(
                  title: 'Personal & Contact Information',
                  icon: Icons.person_pin_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _ProfileDetailTile(
                        icon: Icons.badge_outlined,
                        label: 'Full Name',
                        value: profile.name,
                      ),
                      const Divider(height: 1),
                      _ProfileDetailTile(
                        icon: Icons.email_outlined,
                        label: 'Email Address',
                        value: profile.email,
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          tooltip: 'Copy Email',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: profile.email),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email copied to clipboard!'),
                                duration: Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      _ProfileDetailTile(
                        icon: Icons.phone_outlined,
                        label: 'Phone Number',
                        value: profile.phone.isNotEmpty
                            ? profile.phone
                            : 'Not provided',
                        trailing: profile.phone.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                tooltip: 'Copy Phone',
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: profile.phone),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Phone number copied!'),
                                      duration: Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // SECTION 2: Organization & Employment Details
                _SectionTitle(
                  title: 'Organization & Employment',
                  icon: Icons.corporate_fare_rounded,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      if (profile.companyName.isNotEmpty) ...[
                        _ProfileDetailTile(
                          icon: Icons.apartment_rounded,
                          label: 'Company Name',
                          value: profile.companyName,
                        ),
                        const Divider(height: 1),
                      ],
                      if (profile.companyId.isNotEmpty) ...[
                        _ProfileDetailTile(
                          icon: Icons.domain_rounded,
                          label: 'Company ID',
                          value: profile.companyId,
                          trailing: IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            tooltip: 'Copy Company ID',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: profile.companyId),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Company ID copied!'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                      _ProfileDetailTile(
                        icon: Icons.tag_rounded,
                        label: 'Employee ID',
                        value: profile.employeeId.isNotEmpty
                            ? profile.employeeId
                            : 'N/A',
                      ),
                      const Divider(height: 1),
                      _ProfileDetailTile(
                        icon: Icons.work_outline_rounded,
                        label: 'Job Designation',
                        value: profile.designation,
                      ),
                      const Divider(height: 1),
                      _ProfileDetailTile(
                        icon: Icons.business_outlined,
                        label: 'Department',
                        value: profile.department,
                      ),
                      const Divider(height: 1),
                      _ProfileDetailTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Joining Date',
                        value: _formatDate(profile.joiningDate),
                      ),
                      if (profile.createdAt != null) ...[
                        const Divider(height: 1),
                        _ProfileDetailTile(
                          icon: Icons.event_available_rounded,
                          label: 'Account Created',
                          value: _formatDate(profile.createdAt),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // SECTION 3: Account Security & Credentials
                _SectionTitle(
                  title: 'Security & Credentials',
                  icon: Icons.shield_outlined,
                  color: Colors.teal,
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE0F2FE),
                          child: Icon(
                            Icons.key_rounded,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                        title: const Text(
                          'Change Password',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Update your active account password',
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),
                        onTap: () => _showChangePasswordDialog(profile),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFF3E8FF),
                          child: Icon(
                            Icons.mark_email_read_rounded,
                            color: Colors.purple,
                          ),
                        ),
                        title: const Text(
                          'Send Password Reset Link',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Receive reset instructions at ${profile.email}',
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),
                        onTap: () => _sendPasswordResetEmail(profile),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Profile Edit & Sign Out Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _showEditProfileDialog(profile),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text(
                          'Edit Profile',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _handleSignOut,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ProfileDetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _ProfileDetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.grey.shade600, size: 20),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      trailing: trailing,
    );
  }
}
