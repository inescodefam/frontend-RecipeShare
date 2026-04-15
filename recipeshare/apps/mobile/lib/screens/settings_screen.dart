import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../providers/auth_provider.dart';

void _showSettingsSnack(
  BuildContext context,
  AuthProvider auth, {
  required bool ok,
  required String successMessage,
  required String failureFallback,
}) {
  final text = ok ? successMessage : (auth.errorMessage ?? failureFallback);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

const _buttonProgressIndicator = SizedBox(
  height: 22,
  width: 22,
  child: CircularProgressIndicator(strokeWidth: 2),
);

const _iconProgressIndicator = SizedBox(
  width: 18,
  height: 18,
  child: CircularProgressIndicator(strokeWidth: 2),
);

abstract final class _SettingsStrings {
  static const title = 'Account settings';
  static const profilePhoto = 'Profile photo';
  static const choosePhoto = 'Choose photo';
  static const removePhoto = 'Remove photo';
  static const profile = 'Profile';
  static const profileHint = 'Username and bio (backend: PUT /api/user).';
  static const username = 'Username';
  static const bio = 'Bio';
  static const saveProfile = 'Save profile';
  static const email = 'Email';
  static const emailHint =
      'Changing email requires your current password (backend: PUT /api/user/email).';
  static const emailPasswordLabel =
      'Current password (to confirm email change)';
  static const updateEmail = 'Update email';
  static const password = 'Password';
  static const passwordHint =
      'Backend: PUT /api/user/password. You stay signed in; refresh tokens are rotated server-side.';
  static const currentPassword = 'Current password';
  static const newPassword = 'New password';
  static const confirmPassword = 'Confirm new password';
  static const changePassword = 'Change password';

  static const msgProfileOk = 'Profile updated';
  static const msgProfileErr = 'Could not update profile';
  static const msgEmailOk = 'Email updated';
  static const msgEmailErr = 'Could not update email';
  static const msgPwdOk = 'Password changed';
  static const msgPwdErr = 'Could not change password';
  static const msgPhotoOk = 'Profile photo updated';
  static const msgPhotoErr = 'Upload failed';
  static const msgRemoveOk = 'Profile photo removed';
  static const msgRemoveErr = 'Remove failed';

  static const errUsernameShort = 'At least 3 characters';
  static const errUsernameLong = 'At most 30 characters';
  static const errEmailInvalid = 'Enter a valid email';
  static const errRequired = 'Required';
  static const errPwdShort = 'At least 6 characters';
  static const errPwdMismatch = 'Does not match new password';
}

final RegExp _emailRegExp =
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

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

  bool _looksLikeEmail(String value) => _emailRegExp.hasMatch(value.trim());

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
    _showSettingsSnack(
      context,
      auth,
      ok: ok,
      successMessage: _SettingsStrings.msgProfileOk,
      failureFallback: _SettingsStrings.msgProfileErr,
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
    _showSettingsSnack(
      context,
      auth,
      ok: ok,
      successMessage: _SettingsStrings.msgEmailOk,
      failureFallback: _SettingsStrings.msgEmailErr,
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
    _showSettingsSnack(
      context,
      auth,
      ok: ok,
      successMessage: _SettingsStrings.msgPwdOk,
      failureFallback: _SettingsStrings.msgPwdErr,
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
    _showSettingsSnack(
      context,
      auth,
      ok: ok,
      successMessage: _SettingsStrings.msgPhotoOk,
      failureFallback: _SettingsStrings.msgPhotoErr,
    );
  }

  Future<void> _removeAvatar(AuthProvider auth) async {
    if (!mounted) return;
    setState(() => _removingImage = true);
    auth.clearError();
    final ok = await auth.removeProfileImage();
    if (!mounted) return;
    setState(() => _removingImage = false);
    _showSettingsSnack(
      context,
      auth,
      ok: ok,
      successMessage: _SettingsStrings.msgRemoveOk,
      failureFallback: _SettingsStrings.msgRemoveErr,
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
        title: const Text(_SettingsStrings.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _photoSection(context, user, auth),
            const SizedBox(height: 32),
            _profileFormSection(context, auth),
            const SizedBox(height: 40),
            _emailFormSection(context, auth),
            const SizedBox(height: 40),
            _passwordFormSection(context, auth),
          ],
        ),
      ),
    );
  }

  Widget _photoSection(BuildContext context, User user, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _SettingsStrings.profilePhoto,
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
                      placeholder: (context, url) => const SizedBox(
                        width: 88,
                        height: 88,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) =>
                          const CircleAvatar(
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
                        ? _iconProgressIndicator
                        : const Icon(Icons.photo_library_outlined),
                    label: const Text(_SettingsStrings.choosePhoto),
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
                        ? _iconProgressIndicator
                        : const Icon(Icons.delete_outline),
                    label: const Text(_SettingsStrings.removePhoto),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _profileFormSection(BuildContext context, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _SettingsStrings.profile,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _SettingsStrings.profileHint,
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
                label: _SettingsStrings.username,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().length < 3) {
                    return _SettingsStrings.errUsernameShort;
                  }
                  if (v.trim().length > 30) {
                    return _SettingsStrings.errUsernameLong;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _bio,
                label: _SettingsStrings.bio,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: auth.isLoading || _savingProfile
                    ? null
                    : () => _saveProfile(auth),
                child: _savingProfile
                    ? _buttonProgressIndicator
                    : const Text(_SettingsStrings.saveProfile),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emailFormSection(BuildContext context, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _SettingsStrings.email,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _SettingsStrings.emailHint,
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
                label: _SettingsStrings.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                validator: (v) {
                  if (v == null || !_looksLikeEmail(v)) {
                    return _SettingsStrings.errEmailInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailPassword,
                label: _SettingsStrings.emailPasswordLabel,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return _SettingsStrings.errRequired;
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
                    ? _buttonProgressIndicator
                    : const Text(_SettingsStrings.updateEmail),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _passwordFormSection(BuildContext context, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _SettingsStrings.password,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _SettingsStrings.passwordHint,
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
                label: _SettingsStrings.currentPassword,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return _SettingsStrings.errRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _pwdNew,
                label: _SettingsStrings.newPassword,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return _SettingsStrings.errPwdShort;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _pwdConfirm,
                label: _SettingsStrings.confirmPassword,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                validator: (v) {
                  if (v != _pwdNew.text) {
                    return _SettingsStrings.errPwdMismatch;
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
                    ? _buttonProgressIndicator
                    : const Text(_SettingsStrings.changePassword),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
