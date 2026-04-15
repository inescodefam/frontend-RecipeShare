import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    if (data is Map) {
      final map = Map<Object?, Object?>.from(data);
      final err = map['error'];
      if (err is String && err.isNotEmpty) return err;
      final title = map['title'];
      if (title is String && title.isNotEmpty) return title;
    }
    return e.message ?? 'Request failed';
  }

  User _mapProfile(Map<String, dynamic> json, String fallbackEmail) {
    final rawEmail = json['email'] ?? json['Email'];
    final emailFromApi = rawEmail is String
        ? rawEmail.trim().toLowerCase()
        : fallbackEmail;
    return User(
      id: '${json['id']}',
      username: json['username'] as String? ?? '',
      email: emailFromApi,
      passwordHash: '',
      bio: (json['bio'] as String?) ?? '',
      profileImageUrl: (json['profileImageUrl'] as String?) ?? '',
      isBlocked: json['isBlocked'] as bool? ?? false,
      isAdmin: json['isAdmin'] as bool? ?? false,
      followersCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      recipesCount: (json['recipeCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<User> _fetchProfile(String fallbackEmail) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/user');
    final data = res.data;
    if (data == null) {
      throw StateError('Empty profile response');
    }
    return _mapProfile(data, fallbackEmail);
  }

  Future<String> _sessionEmail() async =>
      (await _session.read(AuthSessionKeys.email)) ?? '';

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
      } catch (e, stackTrace) {
        if (kDebugMode) {
          developer.log(
            'Remote logout request failed; clearing local session anyway.',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }
    }
    await _session.clear();
  }

  @override
  Future<User> updateProfile({
    required String username,
    required String bio,
  }) async {
    try {
      await _dio.put<void>(
        '/api/user',
        data: {
          'username': username.trim(),
          'bio': bio.trim(),
        },
      );
      return _fetchProfile(await _sessionEmail());
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<User> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    try {
      final normalized = newEmail.trim().toLowerCase();
      await _dio.put<void>(
        '/api/user/email',
        data: {
          'newEmail': normalized,
          'currentPassword': currentPassword,
        },
      );
      await _session.write(AuthSessionKeys.email, normalized);
      return _fetchProfile(normalized);
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.put<void>(
        '/api/user/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<User> uploadProfileImage({
    required List<int> imageBytes,
    String? filename,
  }) async {
    try {
      final form = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: filename ?? 'avatar.jpg',
        ),
      });
      await _dio.put<void>('/api/user/image', data: form);
      return _fetchProfile(await _sessionEmail());
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<User> removeProfileImage() async {
    try {
      await _dio.delete<void>('/api/user/image');
      return _fetchProfile(await _sessionEmail());
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }
}
