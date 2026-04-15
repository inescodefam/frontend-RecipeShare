import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

class _AuthServiceForProfile implements AuthService {
  _AuthServiceForProfile(this.current);

  User? current;
  int logoutCalls = 0;

  @override
  Future<User?> getCurrentUser() async => current;

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
  Future<void> logout() async {
    logoutCalls++;
    current = null;
  }

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
      id: 'u1',
      username: 'Alice',
      email: 'alice@example.com',
      passwordHash: 'hash',
      bio: 'I cook',
      profileImageUrl: '',
      isBlocked: false,
      isAdmin: false,
      followersCount: 1,
      followingCount: 2,
      recipesCount: 3,
    );

GoRouter _router(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/home/profile',
    routes: [
      GoRoute(
        path: '/home/profile',
        builder: (_, __) => ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const Scaffold(body: ProfileScreen()),
        ),
      ),
      GoRoute(
        path: '/home/profile/settings',
        builder: (_, __) => const Scaffold(body: Text('settings-target')),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const Scaffold(body: Text('login-target')),
      ),
    ],
  );
}

void main() {
  testWidgets('renders current user details and settings CTA', (tester) async {
    final service = _AuthServiceForProfile(_user());
    final auth = AuthProvider(service);
    await auth.init();
    final router = _router(auth);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('alice@example.com'), findsOneWidget);
    expect(find.text('Account settings'), findsOneWidget);
  });

  testWidgets('shows loading indicator when user is null', (tester) async {
    final service = _AuthServiceForProfile(null);
    final auth = AuthProvider(service);
    await auth.init();
    final router = _router(auth);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('logout navigates to login route', (tester) async {
    final service = _AuthServiceForProfile(_user());
    final auth = AuthProvider(service);
    await auth.init();
    final router = _router(auth);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(service.logoutCalls, 1);
    expect(find.text('login-target'), findsOneWidget);
  });
}
