import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import 'api_config.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

/// Entry point for the RecipeShare **admin** web app (Flutter Web).
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final services = useMockServices
      ? RecipeShareServices.mock()
      : RecipeShareServices.api(
          DioClient.createDio(baseUrl: resolveApiBaseUrl()),
        );
  final auth = AuthProvider(services.auth);
  final GoRouter router = AppRouter.create(auth);

  runApp(
    MultiProvider(
      providers: [
        Provider<RecipeShareServices>.value(value: services),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ],
      child: RecipeShareAdminApp(router: router),
    ),
  );
}

class RecipeShareAdminApp extends StatelessWidget {
  const RecipeShareAdminApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RecipeShare Admin',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
