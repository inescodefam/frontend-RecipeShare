import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/explore_screen.dart';
import '../screens/feed_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_shell_screen.dart';
import '../screens/register_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/recipe_detail_screen.dart';
import '../screens/recipe_editor_screen.dart';
import '../screens/splash_screen.dart';

const _splashPath = '/splash';
const _loginPath = '/login';
const _registerPath = '/register';
const _homePath = '/home';
const _homeFeedPath = '/home/feed';

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
        if (!guest && path == _homePath) {
          return _homeFeedPath;
        }
        if (!guest && (path == _loginPath || path == _registerPath)) {
          return _homeFeedPath;
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
          path: _homePath,
          name: 'home',
          redirect: (context, state) => _homeFeedPath,
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
              path: _homeFeedPath,
              name: 'feed',
              builder: (context, state) => FeedScreen(
                key: ValueKey('feed_${state.uri.queryParameters['refresh'] ?? ''}'),
                refreshToken: state.uri.queryParameters['refresh'],
              ),
            ),
            GoRoute(
              path: '/home/explore',
              name: 'explore',
              builder: (context, state) => ExploreScreen(
                key: ValueKey('explore_${state.uri.queryParameters['refresh'] ?? ''}'),
                refreshToken: state.uri.queryParameters['refresh'],
              ),
            ),
            GoRoute(
              path: '/home/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/home/profile/settings',
              name: 'profileSettings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/recipes/create',
          name: 'recipeCreate',
          builder: (context, state) => const RecipeEditorScreen(),
        ),
        GoRoute(
          path: '/recipes/:id/edit',
          name: 'recipeEdit',
          builder: (context, state) => RecipeEditorScreen(
            recipeId: state.pathParameters['id'],
          ),
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
