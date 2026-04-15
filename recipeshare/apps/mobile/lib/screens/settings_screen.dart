import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formProfileKey = GlobalKey<FormState>();
  final _formEmailKey = GlobalKey<FormState>();
  final _formPasswordKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  final _newEmail = TextEditingController();
  final _emailPassword = TextEditingController();
  final _pwdCurrent = TextEditingController();
  final _pwdNew = TextEditingController();
  final _pwdConfirm = TextEditingController();

  bool _seeded = false;
  bool _savingProfile = false;
  bool _savingEmail = false;
  bool _savingPassword = false;
  bool _uploadingImage = false;
  bool _removingImage = false;

  @override
  void dispose() {
    _username.dispose();
    _bio.dispose();
    _newEmail.dispose();
    _emailPassword.dispose();
    _pwdCurrent.dispose();
    _pwdNew.dispose();
    _pwdConfirm.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  void _seedFromUser(AuthProvider auth) {
    final u = auth.user;
    if (u == null || _seeded) return;
    _username.text = u.username;
    _bio.text = u.bio;
    _newEmail.text = u.email;
    _seeded = true;
  }

  Future<void> _saveProfile(AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    if (!(_formProfileKey.currentState?.validate() ?? false)) return;
    setState(() => _savingProfile = true);
    auth.clearError();
    final ok = await auth.updateProfile(
      username: _username.text.trim(),
      bio: _bio.text,
    );
    if (!mounted) return;
    setState(() => _savingProfile = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profile updated' : (auth.errorMessage ?? 'Could not update profile'),
        ),
      ),
    );
  }

  Future<void> _submitEmail(AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    if (!(_formEmailKey.currentState?.validate() ?? false)) return;
    setState(() => _savingEmail = true);
    auth.clearError();
    final ok = await auth.changeEmail(
      newEmail: _newEmail.text.trim(),
      currentPassword: _emailPassword.text,
    );
    if (!mounted) return;
    setState(() => _savingEmail = false);
    if (ok) {
      _emailPassword.clear();
      final u = auth.user;
      if (u != null) _newEmail.text = u.email;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Email updated' : (auth.errorMessage ?? 'Could not update email'),
        ),
      ),
    );
  }

  Future<void> _changePassword(AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    if (!(_formPasswordKey.currentState?.validate() ?? false)) return;
    setState(() => _savingPassword = true);
    auth.clearError();
    final ok = await auth.changePassword(
      currentPassword: _pwdCurrent.text,
      newPassword: _pwdNew.text,
    );
    if (!mounted) return;
    setState(() => _savingPassword = false);
    if (ok) {
      _pwdCurrent.clear();
      _pwdNew.clear();
      _pwdConfirm.clear();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Password changed' : (auth.errorMessage ?? 'Could not change password'),
        ),
      ),
    );
  }

  Future<void> _pickAvatar(AuthProvider auth) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 88,
    );
    if (file == null || !mounted) return;
    setState(() => _uploadingImage = true);
    auth.clearError();
    final bytes = await file.readAsBytes();
    final ok = await auth.uploadProfileImage(
      imageBytes: bytes,
      filename: file.name,
    );
    if (!mounted) return;
    setState(() => _uploadingImage = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profile photo updated' : (auth.errorMessage ?? 'Upload failed'),
        ),
      ),
    );
  }

  Future<void> _removeAvatar(AuthProvider auth) async {
    if (!mounted) return;
    setState(() => _removingImage = true);
    auth.clearError();
    final ok = await auth.removeProfileImage();
    if (!mounted) return;
    setState(() => _removingImage = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profile photo removed' : (auth.errorMessage ?? 'Remove failed'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    _seedFromUser(auth);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Profile photo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ClipOval(
                  child: user.profileImageUrl.isEmpty
                      ? const CircleAvatar(
                          radius: 44,
                          child: Icon(Icons.person, size: 44),
                        )
                      : CachedNetworkImage(
                          imageUrl: user.profileImageUrl,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const SizedBox(
                            width: 88,
                            height: 88,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (_, __, ___) => const CircleAvatar(
                            radius: 44,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: auth.isLoading || _uploadingImage || _removingImage
                            ? null
                            : () => _pickAvatar(auth),
                        icon: _uploadingImage
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.photo_library_outlined),
                        label: const Text('Choose photo'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: auth.isLoading ||
                                _uploadingImage ||
                                _removingImage ||
                                user.profileImageUrl.isEmpty
                            ? null
                            : () => _removeAvatar(auth),
                        icon: _removingImage
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline),
                        label: const Text('Remove photo'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Username and bio (backend: PUT /api/user).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formProfileKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _username,
                    label: 'Username',
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().length < 3) {
                        return 'At least 3 characters';
                      }
                      if (v.trim().length > 30) {
                        return 'At most 30 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _bio,
                    label: 'Bio',
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: auth.isLoading || _savingProfile
                        ? null
                        : () => _saveProfile(auth),
                    child: _savingProfile
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Email',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Changing email requires your current password (backend: PUT /api/user/email).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formEmailKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _newEmail,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    validator: (v) {
                      if (v == null || !_looksLikeEmail(v)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _emailPassword,
                    label: 'Current password (to confirm email change)',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: auth.isLoading || _savingEmail
                        ? null
                        : () => _submitEmail(auth),
                    child: _savingEmail
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update email'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Password',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Backend: PUT /api/user/password. You stay signed in; refresh tokens are rotated server-side.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formPasswordKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _pwdCurrent,
                    label: 'Current password',
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _pwdNew,
                    label: 'New password',
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'At least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _pwdConfirm,
                    label: 'Confirm new password',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    validator: (v) {
                      if (v != _pwdNew.text) {
                        return 'Does not match new password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: auth.isLoading || _savingPassword
                        ? null
                        : () => _changePassword(auth),
                    child: _savingPassword
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Change password'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
