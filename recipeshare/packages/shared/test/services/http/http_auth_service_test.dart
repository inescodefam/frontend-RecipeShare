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

    test('register/update/changePassword/upload/remove success paths', () async {
      final session = _MemorySessionStorage()
        ..values[AuthSessionKeys.email] = 'seed@example.com';
      final dio = _stubbedDio((req) async {
        if (req.method == 'POST' && req.path == '/api/auth/register') {
          return _jsonResponse(req, {'token': 'jwt-2', 'refreshToken': 'refresh-2'});
        }
        if (req.method == 'PUT' && req.path == '/api/user') {
          return _jsonResponse(req, null);
        }
        if (req.method == 'PUT' && req.path == '/api/user/password') {
          return _jsonResponse(req, null);
        }
        if (req.method == 'PUT' && req.path == '/api/user/image') {
          return _jsonResponse(req, null);
        }
        if (req.method == 'DELETE' && req.path == '/api/user/image') {
          return _jsonResponse(req, null);
        }
        if (req.method == 'GET' && req.path == '/api/user') {
          return _jsonResponse(req, {
            'id': '5',
            'username': 'Updated',
            'email': 'updated@example.com',
            'bio': 'bio',
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
      final reg = await service.register(
        username: 'User',
        email: 'USER@example.com',
        password: 'secret1',
      );
      expect(reg.username, 'Updated');
      expect(session.values[AuthSessionKeys.jwt], 'jwt-2');

      final updated = await service.updateProfile(username: 'Neo', bio: 'hello');
      expect(updated.username, 'Updated');

      await service.changePassword(currentPassword: 'old', newPassword: 'new123');

      final withImage = await service.uploadProfileImage(
        imageBytes: const [1, 2, 3],
        filename: 'avatar.jpg',
      );
      expect(withImage.username, 'Updated');

      final noImage = await service.removeProfileImage();
      expect(noImage.username, 'Updated');
    });

    test('maps dio errors to state errors across API methods', () async {
      final session = _MemorySessionStorage();
      final dio = _stubbedDio((req) async {
        throw DioException(
          requestOptions: req,
          response: _jsonResponse(req, {'title': 'Boom title'}, statusCode: 400),
        );
      });
      final service = HttpAuthService(dio, session: session);

      await expectLater(
        () => service.login(email: 'a@b.com', password: 'pw'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        () => service.register(username: 'u', email: 'a@b.com', password: 'pw1234'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        () => service.updateProfile(username: 'u', bio: 'b'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        () => service.changeEmail(newEmail: 'x@y.com', currentPassword: 'pw'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        () => service.changePassword(currentPassword: 'old', newPassword: 'new'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        () => service.uploadProfileImage(imageBytes: const [1], filename: 'x.png'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        () => service.removeProfileImage(),
        throwsA(isA<StateError>()),
      );
    });
  });
}
