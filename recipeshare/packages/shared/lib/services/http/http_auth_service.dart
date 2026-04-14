import 'package:dio/dio.dart';

import '../../models/models.dart';
import '../auth_service.dart';
import 'auth_session_storage.dart';

class HttpAuthService implements AuthService {
  HttpAuthService(
    this._dio, {
    required AuthSessionStorage session,
  }) : _session = session;

  final Dio _dio;
  final AuthSessionStorage _session;

  static String _messageFromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    return e.message ?? 'Request failed';
  }

  User _mapProfile(Map<String, dynamic> json, String email) {
    return User(
      id: '${json['id']}',
      username: json['username'] as String? ?? '',
      email: email,
      passwordHash: '',
      bio: (json['bio'] as String?) ?? '',
      profileImageUrl: (json['profileImageUrl'] as String?) ?? '',
      isBlocked: false,
      isAdmin: false,
      followersCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      recipesCount: (json['recipeCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<User> _fetchProfile(String email) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/user');
    final data = res.data;
    if (data == null) {
      throw StateError('Empty profile response');
    }
    return _mapProfile(data, email);
  }

  @override
  Future<User?> getCurrentUser() async {
    final jwt = await _session.read(AuthSessionKeys.jwt);
    if (jwt == null || jwt.isEmpty) return null;
    final email = await _session.read(AuthSessionKeys.email) ?? '';
    try {
      return await _fetchProfile(email);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _session.clear();
      }
      return null;
    }
  }

  @override
  Future<User> login({required String email, required String password}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final map = res.data;
      if (map == null) throw StateError('Empty login response');
      final token = map['token'] as String?;
      final refresh = map['refreshToken'] as String?;
      if (token == null || refresh == null) {
        throw StateError('Invalid login response');
      }
      await _session.writeSessionTokens(
        token: token,
        refreshToken: refresh,
        email: email.trim().toLowerCase(),
      );
      return _fetchProfile(email.trim().toLowerCase());
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
        },
      );
      final map = res.data;
      if (map == null) throw StateError('Empty register response');
      final token = map['token'] as String?;
      final refresh = map['refreshToken'] as String?;
      if (token == null || refresh == null) {
        throw StateError('Invalid register response');
      }
      final normalizedEmail = email.trim().toLowerCase();
      await _session.writeSessionTokens(
        token: token,
        refreshToken: refresh,
        email: normalizedEmail,
      );
      return _fetchProfile(normalizedEmail);
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<void> logout() async {
    final refresh = await _session.read(AuthSessionKeys.refresh);
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _dio.post<void>(
          '/api/auth/logout',
          data: {'refreshToken': refresh},
        );
      } catch (_) {
        //  clear local session if server fails
      }
    }
    await _session.clear();
  }
}
