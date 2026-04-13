import 'package:dio/dio.dart';

import '../http/auth_session_storage.dart';

class DioClient {
  DioClient._();

  static Dio createDio({
    required String baseUrl,
    required AuthSessionStorage session,
  }) {
    final storage = session;
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
          final token = await storage.read(AuthSessionKeys.jwt);
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
