import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/services/http/auth_session_storage.dart';
import 'package:shared/services/http/http_auth_service.dart';

class _MemorySessionStorage implements AuthSessionStorage {
  final Map<String, String> values = <String, String>{};
  int clearCalls = 0;

  @override
  Future<void> clear() async {
    clearCalls++;
    values.clear();
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

typedef _Responder = Future<Response<dynamic>> Function(RequestOptions options);

Dio _stubbedDio(_Responder responder) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          handler.resolve(await responder(options));
        } on DioException catch (e) {
          handler.reject(e);
        }
      },
    ),
  );
  return dio;
}

Response<dynamic> _jsonResponse(RequestOptions req, dynamic data, {int statusCode = 200}) {
  return Response<dynamic>(
    requestOptions: req,
    data: data,
    statusCode: statusCode,
  );
}

void main() {
  group('HttpAuthService', () {
    test('login writes session tokens and fetches profile', () async {
      final session = _MemorySessionStorage();
      final dio = _stubbedDio((req) async {
        if (req.method == 'POST' && req.path == '/api/auth/login') {
          return _jsonResponse(req, {
            'token': 'jwt-1',
            'refreshToken': 'refresh-1',
          });
        }
        if (req.method == 'GET' && req.path == '/api/user') {
          return _jsonResponse(req, {
            'id': '7',
            'username': 'Alice',
            'bio': 'Bio',
            'profileImageUrl': '',
            'isBlocked': false,
            'isAdmin': false,
            'followerCount': 2,
            'followingCount': 3,
            'recipeCount': 4,
          });
        }
        throw StateError('Unexpected request ${req.method} ${req.path}');
      });

      final service = HttpAuthService(dio, session: session);
      final user = await service.login(
        email: ' Alice@Example.com ',
        password: 'secret',
      );

      expect(user.username, 'Alice');
      expect(user.email, 'alice@example.com');
      expect(session.values[AuthSessionKeys.jwt], 'jwt-1');
      expect(session.values[AuthSessionKeys.refresh], 'refresh-1');
      expect(session.values[AuthSessionKeys.email], 'alice@example.com');
    });

    test('getCurrentUser returns null without jwt and clears on 401', () async {
      final session = _MemorySessionStorage();
      final noJwtDio = _stubbedDio((req) async {
        throw StateError('Should not be called without jwt');
      });
      final noJwtService = HttpAuthService(noJwtDio, session: session);
      expect(await noJwtService.getCurrentUser(), isNull);

      session.values[AuthSessionKeys.jwt] = 'jwt';
      session.values[AuthSessionKeys.email] = 'a@example.com';
      final unauthorizedDio = _stubbedDio((req) async {
        throw DioException(
          requestOptions: req,
          response: _jsonResponse(req, {'error': 'unauthorized'}, statusCode: 401),
        );
      });
      final unauthorizedService = HttpAuthService(unauthorizedDio, session: session);
      expect(await unauthorizedService.getCurrentUser(), isNull);
      expect(session.clearCalls, 1);
    });

    test('changeEmail updates stored email and returns profile', () async {
      final session = _MemorySessionStorage()
        ..values[AuthSessionKeys.email] = 'old@example.com';
      final dio = _stubbedDio((req) async {
        if (req.method == 'PUT' && req.path == '/api/user/email') {
          return _jsonResponse(req, null);
        }
        if (req.method == 'GET' && req.path == '/api/user') {
          return _jsonResponse(req, {
            'id': '9',
            'username': 'Neo',
            'email': 'new@example.com',
            'bio': '',
            'profileImageUrl': '',
            'isBlocked': false,
            'isAdmin': false,
            'followerCount': 0,
            'followingCount': 0,
            'recipeCount': 0,
          });
        }
        throw StateError('Unexpected request ${req.method} ${req.path}');
      });

      final service = HttpAuthService(dio, session: session);
      final user = await service.changeEmail(
        newEmail: 'New@Example.com',
        currentPassword: 'pw',
      );

      expect(user.email, 'new@example.com');
      expect(session.values[AuthSessionKeys.email], 'new@example.com');
    });

    test('logout clears session even when remote logout fails', () async {
      final session = _MemorySessionStorage()
        ..values[AuthSessionKeys.refresh] = 'refresh-1';
      final dio = _stubbedDio((req) async {
        if (req.method == 'POST' && req.path == '/api/auth/logout') {
          throw DioException(
            requestOptions: req,
            response: _jsonResponse(req, {'error': 'boom'}, statusCode: 500),
          );
        }
        throw StateError('Unexpected request ${req.method} ${req.path}');
      });

      final service = HttpAuthService(dio, session: session);
      await service.logout();

      expect(session.values, isEmpty);
      expect(session.clearCalls, 1);
    });
  });
}
