import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import 'providers/auth_provider.dart';
import 'router/app_router.dart';

/// Entry point for the RecipeShare **mobile** app (iOS & Android).
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final services = RecipeShareServices.mock();
  final auth = AuthProvider(services.auth);
  final GoRouter router = AppRouter.create(auth);

  runApp(
    MultiProvider(
      providers: [
        Provider<RecipeShareServices>.value(value: services),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ],
      child: RecipeShareMobileApp(router: router),
    ),
  );
}

class RecipeShareMobileApp extends StatelessWidget {
  const RecipeShareMobileApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RecipeShare',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
