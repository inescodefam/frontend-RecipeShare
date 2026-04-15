import '../auth_service.dart';
import '../../models/models.dart';
import 'mock_data_service.dart';

class MockAuthService implements AuthService {
  MockAuthService(this._data);

  final MockDataService _data;

  User? _session;

  @override
  Future<User?> getCurrentUser() async => _session;

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final user = await _data.findUserByEmail(email.trim());
    if (user == null || password.isEmpty) {
      throw StateError('Invalid email or password');
    }
    if (user.isBlocked) {
      throw StateError('This account is blocked');
    }
    _session = user;
    return user;
  }

  @override
  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    if (password.length < 6) {
      throw StateError('Password must be at least 6 characters');
    }
    final taken = await _data.findUserByEmail(email.trim());
    if (taken != null) {
      throw StateError('Email is already registered');
    }
    final user = User(
      id: 'user_${_data.newId()}',
      username: username.trim(),
      email: email.trim().toLowerCase(),
      passwordHash: 'pbkdf2_${username.trim()}_hash',
      bio: '',
      profileImageUrl: 'https://picsum.photos/seed/${username.trim()}/200/200',
      isBlocked: false,
      isAdmin: false,
      followersCount: 0,
      followingCount: 0,
      recipesCount: 0,
    );
    await _data.replaceUser(user);
    _session = user;
    return user;
  }

  @override
  Future<void> logout() async {
    _session = null;
  }

  @override
  Future<User> updateProfile({
    required String username,
    required String bio,
  }) async {
    final current = _session;
    if (current == null) {
      throw StateError('Not signed in');
    }
    final t = username.trim();
    if (t.length < 3) {
      throw StateError('Username must be at least 3 characters');
    }
    var updated = current.copyWith(
      username: t,
      bio: bio.trim(),
    );
    await _data.replaceUser(updated);
    _session = updated;
    return updated;
  }

  @override
  Future<User> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final current = _session;
    if (current == null) {
      throw StateError('Not signed in');
    }
    if (currentPassword.isEmpty) {
      throw StateError('Current password is required');
    }
    final t = newEmail.trim().toLowerCase();
    if (t.isEmpty) {
      throw StateError('Email cannot be empty');
    }
    final other = await _data.findUserByEmail(t);
    if (other != null && other.id != current.id) {
      throw StateError('Email is already in use');
    }
    final updated = current.copyWith(email: t);
    await _data.replaceUser(updated);
    _session = updated;
    return updated;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_session == null) {
      throw StateError('Not signed in');
    }
    if (currentPassword.isEmpty) {
      throw StateError('Current password is required');
    }
    if (newPassword.length < 6) {
      throw StateError('New password must be at least 6 characters');
    }
  }

  @override
  Future<User> uploadProfileImage({
    required List<int> imageBytes,
    String? filename,
  }) async {
    final current = _session;
    if (current == null) {
      throw StateError('Not signed in');
    }
    if (imageBytes.isEmpty) {
      throw StateError('Image is empty');
    }
    final seed = '${current.id}_${imageBytes.length}_${filename ?? 'img'}';
    final updated = current.copyWith(
      profileImageUrl: 'https://picsum.photos/seed/$seed/400/400',
    );
    await _data.replaceUser(updated);
    _session = updated;
    return updated;
  }

  @override
  Future<User> removeProfileImage() async {
    final current = _session;
    if (current == null) {
      throw StateError('Not signed in');
    }
    final updated = current.copyWith(profileImageUrl: '');
    await _data.replaceUser(updated);
    _session = updated;
    return updated;
  }
}
