import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:shared/shared.dart';

class _FakeAuthService implements AuthService {
  User? currentUser;
  Object? loginError;
  Object? registerError;
  Object? refreshError;
  Object? updateProfileError;
  Object? changeEmailError;
  Object? changePasswordError;
  Object? uploadImageError;
  Object? removeImageError;

  int logoutCalls = 0;

  User _user({
    String id = 'u1',
    String username = 'tester',
    String email = 'tester@example.com',
    String bio = '',
    String profileImageUrl = '',
  }) {
    return User(
      id: id,
      username: username,
      email: email,
      passwordHash: 'hash',
      bio: bio,
      profileImageUrl: profileImageUrl,
      isBlocked: false,
      isAdmin: false,
      followersCount: 0,
      followingCount: 0,
      recipesCount: 0,
    );
  }

  @override
  Future<User?> getCurrentUser() async {
    if (refreshError != null) throw refreshError!;
    return currentUser;
  }

  @override
  Future<User> login({required String email, required String password}) async {
    if (loginError != null) throw loginError!;
    currentUser = _user(email: email.trim().toLowerCase());
    return currentUser!;
  }

  @override
  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    if (registerError != null) throw registerError!;
    currentUser = _user(
      id: 'u2',
      username: username.trim(),
      email: email.trim().toLowerCase(),
    );
    return currentUser!;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    currentUser = null;
  }

  @override
  Future<User> updateProfile({
    required String username,
    required String bio,
  }) async {
    if (updateProfileError != null) throw updateProfileError!;
    final next = (currentUser ?? _user()).copyWith(
      username: username,
      bio: bio,
    );
    currentUser = next;
    return next;
  }

  @override
  Future<User> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    if (changeEmailError != null) throw changeEmailError!;
    final next = (currentUser ?? _user()).copyWith(email: newEmail);
    currentUser = next;
    return next;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (changePasswordError != null) throw changePasswordError!;
  }

  @override
  Future<User> uploadProfileImage({
    required List<int> imageBytes,
    String? filename,
  }) async {
    if (uploadImageError != null) throw uploadImageError!;
    final next = (currentUser ?? _user()).copyWith(
      profileImageUrl: 'https://img/${filename ?? 'avatar.jpg'}',
    );
    currentUser = next;
    return next;
  }

  @override
  Future<User> removeProfileImage() async {
    if (removeImageError != null) throw removeImageError!;
    final next = (currentUser ?? _user()).copyWith(profileImageUrl: '');
    currentUser = next;
    return next;
  }
}

void main() {
  group('AuthProvider', () {
    test('init and login/register/logout success flow', () async {
      final service = _FakeAuthService()
        ..currentUser = User(
          id: 'seed',
          username: 'seed',
          email: 'seed@example.com',
          passwordHash: 'h',
          bio: '',
          profileImageUrl: '',
          isBlocked: false,
          isAdmin: false,
          followersCount: 0,
          followingCount: 0,
          recipesCount: 0,
        );
      final provider = AuthProvider(service);

      await provider.init();
      expect(provider.isLoading, isFalse);
      expect(provider.user?.id, 'seed');

      await provider.login(' NEW@EXAMPLE.COM ', 'secret');
      expect(provider.isLoggedIn, isTrue);
      expect(provider.user?.email, 'new@example.com');
      expect(provider.errorMessage, isNull);

      await provider.register(
        username: 'alice',
        email: 'Alice@Example.com',
        password: 'secret123',
      );
      expect(provider.user?.username, 'alice');
      expect(provider.user?.email, 'alice@example.com');

      await provider.logout();
      expect(provider.user, isNull);
      expect(provider.errorMessage, isNull);
      expect(service.logoutCalls, 1);
    });

    test('sets error on login/register/refresh failures', () async {
      final service = _FakeAuthService()
        ..loginError = StateError('bad login')
        ..registerError = Exception('reg failed')
        ..refreshError = StateError('cannot refresh');
      final provider = AuthProvider(service);

      await provider.login('a@b.com', 'x');
      expect(provider.user, isNull);
      expect(provider.errorMessage, 'bad login');

      await provider.register(
        username: 'abc',
        email: 'a@b.com',
        password: '123456',
      );
      expect(provider.user, isNull);
      expect(provider.errorMessage, contains('reg failed'));

      await provider.refreshUser();
      expect(provider.errorMessage, 'cannot refresh');
      provider.clearError();
      expect(provider.errorMessage, isNull);
    });

    test('returns booleans for profile/email/password/image actions', () async {
      final service = _FakeAuthService()
        ..currentUser = User(
          id: 'u1',
          username: 'user',
          email: 'user@example.com',
          passwordHash: 'h',
          bio: '',
          profileImageUrl: '',
          isBlocked: false,
          isAdmin: false,
          followersCount: 0,
          followingCount: 0,
          recipesCount: 0,
        );
      final provider = AuthProvider(service);

      expect(
        await provider.updateProfile(username: 'neo', bio: 'bio'),
        isTrue,
      );
      expect(provider.user?.username, 'neo');

      expect(
        await provider.changeEmail(
          newEmail: 'neo@example.com',
          currentPassword: 'pw',
        ),
        isTrue,
      );
      expect(provider.user?.email, 'neo@example.com');

      expect(
        await provider.changePassword(
          currentPassword: 'pw',
          newPassword: 'new-pass',
        ),
        isTrue,
      );

      expect(
        await provider.uploadProfileImage(
          imageBytes: const [1, 2, 3],
          filename: 'a.jpg',
        ),
        isTrue,
      );
      expect(provider.user?.profileImageUrl, contains('a.jpg'));

      expect(await provider.removeProfileImage(), isTrue);
      expect(provider.user?.profileImageUrl, '');

      service.updateProfileError = StateError('profile fail');
      expect(
        await provider.updateProfile(username: 'x', bio: 'y'),
        isFalse,
      );
      expect(provider.errorMessage, 'profile fail');

      service.updateProfileError = null;
      service.changeEmailError = StateError('email fail');
      expect(
        await provider.changeEmail(
          newEmail: 'x@example.com',
          currentPassword: 'pw',
        ),
        isFalse,
      );
      expect(provider.errorMessage, 'email fail');

      service.changeEmailError = null;
      service.changePasswordError = Exception('pwd fail');
      expect(
        await provider.changePassword(
          currentPassword: 'pw',
          newPassword: '123456',
        ),
        isFalse,
      );
      expect(provider.errorMessage, contains('pwd fail'));

      service.changePasswordError = null;
      service.uploadImageError = StateError('upload fail');
      expect(
        await provider.uploadProfileImage(
          imageBytes: const [7, 8, 9],
          filename: 'b.jpg',
        ),
        isFalse,
      );
      expect(provider.errorMessage, 'upload fail');

      service.uploadImageError = null;
      service.removeImageError = StateError('remove fail');
      expect(await provider.removeProfileImage(), isFalse);
      expect(provider.errorMessage, 'remove fail');
    });
  });
}
