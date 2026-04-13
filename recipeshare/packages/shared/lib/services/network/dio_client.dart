import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../http/auth_token_storage.dart';

/// HTTP client for the RecipeShare .NET API: base URL, JWT header, timeouts.
class DioClient {
  DioClient._();

  static Dio createDio({
    required String baseUrl,
    FlutterSecureStorage? storage,
  }) {
    final secure = storage ?? const FlutterSecureStorage();
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secure.read(key: AuthTokenStorage.jwtKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Token expired — [AuthProvider] / router redirect should send user to login.
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}
