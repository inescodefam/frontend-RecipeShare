import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/home_placeholder_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';

/// Central route table. Swap redirect rules when real tokens exist; screens stay the same.
class AppRouter {
  AppRouter._();

  static GoRouter create(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,

      redirect: (BuildContext context, GoRouterState state) {
        final guest = auth.user == null;
        final path = state.matchedLocation;

        if (guest &&
            path != '/splash' &&
            path != '/login' &&
            path != '/register') {
          return '/login';
        }
        if (!guest && (path == '/login' || path == '/register')) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomePlaceholderScreen(),
        ),
      ],
    );
  }
}
