import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/router/app_router.dart';
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
  Future<void> logout() async {
    currentUser = null;
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
      username: 'u',
      email: 'u@example.com',
      passwordHash: 'h',
      bio: '',
      profileImageUrl: '',
      isBlocked: false,
      isAdmin: false,
      followersCount: 0,
      followingCount: 0,
      recipesCount: 0,
    );

Future<void> _pumpRouteChange(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Future<void> _flushMockTimers(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<GoRouter> _pumpRouter(
  WidgetTester tester,
  AuthProvider auth, {
  String initialLocation = '/splash',
}) async {
  final router = AppRouter.create(auth, initialLocation: initialLocation);
  final services = RecipeShareServices.mock();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<RecipeShareServices>.value(value: services),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  if (initialLocation == '/splash') {
    await tester.pump(const Duration(milliseconds: 600));
  }
  return router;
}

Future<AuthProvider> _loggedInAuth() async {
  final auth = AuthProvider(_RouterAuthService(_user()));
  await auth.init();
  return auth;
}

void main() {
  testWidgets('guest is redirected to login from protected route', (tester) async {
    final auth = AuthProvider(_RouterAuthService(null));
    final router = await _pumpRouter(tester, auth);
    router.go('/home/profile');
    await _pumpRouteChange(tester);

    expect(router.routeInformationProvider.value.uri.toString(), '/login');
    await _flushMockTimers(tester);
  });

  testWidgets('logged in user is redirected away from login/register/home', (tester) async {
    final auth = await _loggedInAuth();
    final router = await _pumpRouter(tester, auth, initialLocation: '/login');
    expect(router.routeInformationProvider.value.uri.toString(), '/home/feed');

    router.go('/register');
    await _pumpRouteChange(tester);
    expect(router.routeInformationProvider.value.uri.toString(), '/home/feed');

    router.go('/home');
    await _pumpRouteChange(tester);
    expect(router.routeInformationProvider.value.uri.toString(), '/home/feed');
    await _flushMockTimers(tester);
  });

  testWidgets('logged in user can open shell routes', (tester) async {
    final auth = await _loggedInAuth();
    final router = await _pumpRouter(tester, auth, initialLocation: '/home/explore');
    expect(router.routeInformationProvider.value.uri.toString(), '/home/explore');

    router.go('/home/profile');
    await _pumpRouteChange(tester);
    expect(router.routeInformationProvider.value.uri.toString(), '/home/profile');

    router.go('/home/profile/settings');
    await _pumpRouteChange(tester);
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/home/profile/settings',
    );

    await _flushMockTimers(tester);
  });

  testWidgets('logged in user can open recipe detail route', (tester) async {
    final auth = await _loggedInAuth();
    final router = await _pumpRouter(tester, auth, initialLocation: '/recipes/r1');
    expect(router.routeInformationProvider.value.uri.toString(), '/recipes/r1');

    await _flushMockTimers(tester);
  });
}
