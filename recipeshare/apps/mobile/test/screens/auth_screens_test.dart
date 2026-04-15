import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

class _ScreenAuthService implements AuthService {
  _ScreenAuthService({required this.loginSucceeds, required this.registerSucceeds});

  final bool loginSucceeds;
  final bool registerSucceeds;
  User? currentUser;

  @override
  Future<User?> getCurrentUser() async => currentUser;

  @override
  Future<User> login({required String email, required String password}) async {
    if (!loginSucceeds) throw StateError('login failed');
    currentUser = _user(email: email.trim().toLowerCase());
    return currentUser!;
  }

  @override
  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    if (!registerSucceeds) throw StateError('register failed');
    currentUser = _user(username: username.trim(), email: email.trim().toLowerCase());
    return currentUser!;
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

User _user({
  String username = 'user',
  String email = 'user@example.com',
}) =>
    User(
      id: 'id',
      username: username,
      email: email,
      passwordHash: 'h',
      bio: '',
      profileImageUrl: '',
      isBlocked: false,
      isAdmin: false,
      followersCount: 0,
      followingCount: 0,
      recipesCount: 0,
    );

Future<void> _pumpWithRouter(
  WidgetTester tester,
  AuthProvider auth,
  String startPath,
) async {
  final router = GoRouter(
    initialLocation: startPath,
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(path: '/home/feed', builder: (_, __) => const Text('feed-target')),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login validates and navigates on success', (tester) async {
    final auth = AuthProvider(_ScreenAuthService(loginSucceeds: true, registerSucceeds: true));
    await _pumpWithRouter(tester, auth, '/login');

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('Email'), 'good@example.com');
    await tester.enterText(find.bySemanticsLabel('Password'), 'pw');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('feed-target'), findsOneWidget);
  });

  testWidgets('register validates and navigates on success', (tester) async {
    final auth = AuthProvider(_ScreenAuthService(loginSucceeds: true, registerSucceeds: true));
    await _pumpWithRouter(tester, auth, '/register');

    await tester.tap(find.widgetWithText(FilledButton, 'Register'));
    await tester.pump();
    expect(find.text('Username must be at least 3 characters'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('Username'), 'alice');
    await tester.enterText(find.bySemanticsLabel('Email'), 'alice@example.com');
    await tester.enterText(find.bySemanticsLabel('Password'), 'secret1');
    await tester.enterText(find.bySemanticsLabel('Confirm password'), 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, 'Register'));
    await tester.pumpAndSettle();

    expect(find.text('feed-target'), findsOneWidget);
  });
}
