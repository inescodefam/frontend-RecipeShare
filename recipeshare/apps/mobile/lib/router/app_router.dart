import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/explore_screen.dart';
import '../screens/feed_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_shell_screen.dart';
import '../screens/register_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recipe_detail_screen.dart';
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
        if (!guest && path == '/home') {
          return '/home/feed';
        }
        if (!guest && (path == '/login' || path == '/register')) {
          return '/home/feed';
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
          redirect: (context, state) => '/home/feed',
        ),
        ShellRoute(
          builder: (context, state, child) {
            return HomeShellScreen(
              location: state.matchedLocation,
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: '/home/feed',
              name: 'feed',
              builder: (context, state) => const FeedScreen(),
            ),
            GoRoute(
              path: '/home/explore',
              name: 'explore',
              builder: (context, state) => const ExploreScreen(),
            ),
            GoRoute(
              path: '/home/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/recipes/:id',
          name: 'recipeDetail',
          builder: (context, state) => RecipeDetailScreen(
            recipeId: state.pathParameters['id'] ?? '',
          ),
        ),
      ],
    );
  }
}
