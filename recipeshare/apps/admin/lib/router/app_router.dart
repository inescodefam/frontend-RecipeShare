import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';

const _splashPath = '/splash';
const _loginPath = '/login';
const _registerPath = '/register';
const _dashboardPath = '/dashboard';

class AppRouter {
  AppRouter._();

  static GoRouter create(AuthProvider auth) {
    return GoRouter(
      initialLocation: _splashPath,
      refreshListenable: auth,
      redirect: (BuildContext context, GoRouterState state) {
        final guest = auth.user == null;
        final path = state.matchedLocation;

        if (guest &&
            path != _splashPath &&
            path != _loginPath &&
            path != _registerPath) {
          return _loginPath;
        }
        if (!guest && (path == _loginPath || path == _registerPath)) {
          return _dashboardPath;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: _splashPath,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: _loginPath,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: _registerPath,
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: _dashboardPath,
          name: 'dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
      ],
    );
  }
}
