import '../auth_service.dart';
import '../../models/models.dart';
import 'mock_data_service.dart';

/// Mock auth: any non-empty password works for existing emails; register appends a user.
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
}
