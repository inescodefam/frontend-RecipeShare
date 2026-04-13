import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import 'api_config.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final useMock = useMockServices;
  final Dio? dio =
      useMock ? null : DioClient.createDio(baseUrl: resolveApiBaseUrl());
  final services =
      useMock ? RecipeShareServices.mock() : RecipeShareServices.api(dio!);
  final auth = AuthProvider(services.auth);
  final GoRouter router = AppRouter.create(auth);

  runApp(
    MultiProvider(
      providers: [
        Provider<RecipeShareServices>.value(value: services),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        Provider<HttpAdminCategoriesService?>.value(
          value: dio == null ? null : HttpAdminCategoriesService(dio),
        ),
        Provider<HttpAdminTagsService?>.value(
          value: dio == null ? null : HttpAdminTagsService(dio),
        ),
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
