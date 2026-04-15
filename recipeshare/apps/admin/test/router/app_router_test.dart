import 'package:admin/providers/auth_provider.dart';
import 'package:admin/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

class _RouterAuthService implements AuthService {
  _RouterAuthService(this.currentUser);
  User? currentUser;

  @override
  Future<User?> getCurrentUser() async => currentUser;

  @override
  Future<User> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async => currentUser = null;

  @override
  Future<User> updateProfile({required String username, required String bio}) {
    throw UnimplementedError();
  }

  @override
  Future<User> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<User> uploadProfileImage({
    required List<int> imageBytes,
    String? filename,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<User> removeProfileImage() {
    throw UnimplementedError();
  }
}

User _user() => const User(
      id: 'u',
      username: 'admin',
      email: 'admin@example.com',
      passwordHash: 'h',
      bio: '',
      profileImageUrl: '',
      isBlocked: false,
      isAdmin: true,
      followersCount: 0,
      followingCount: 0,
      recipesCount: 0,
    );

Future<GoRouter> _pumpRouter(WidgetTester tester, AuthProvider auth) async {
  final router = AppRouter.create(auth);
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('guest gets redirected to /login for protected paths', (tester) async {
    final auth = AuthProvider(_RouterAuthService(null));
    final router = await _pumpRouter(tester, auth);
    router.go('/dashboard');
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.toString(), '/login');
  });

  testWidgets('signed in user is redirected from auth pages to /dashboard', (tester) async {
    final auth = AuthProvider(_RouterAuthService(_user()));
    final router = await _pumpRouter(tester, auth);
    router.go('/login');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.toString(), '/dashboard');

    router.go('/register');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.toString(), '/dashboard');
  });
}
