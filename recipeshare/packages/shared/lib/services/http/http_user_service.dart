import 'package:dio/dio.dart';

import '../../models/models.dart';
import '../user_service.dart';

class HttpUserService implements UserService {
  HttpUserService(this._dio);

  final Dio _dio;

  String _messageFromDio(DioException e) {
    final data = e.response?.data;
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if (data is Map) {
      final err = data['error'];
      if (err != null) return err.toString();
      final title = data['title'];
      if (title != null) return title.toString();
    }
    return e.message ?? 'Request failed';
  }

  User _mapProfile(Map<String, dynamic> json) {
    return User(
      id: '${json['id']}',
      username: json['username'] as String? ?? '',
      email: (json['email'] as String?) ?? '',
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

  User _mapSearchUser(Map<String, dynamic> json) {
    return User(
      id: '${json['id']}',
      username: json['username'] as String? ?? '',
      email: '',
      passwordHash: '',
      bio: '',
      profileImageUrl: (json['profileImageUrl'] as String?) ?? '',
      isBlocked: false,
      isAdmin: false,
      followersCount: 0,
      followingCount: 0,
      recipesCount: 0,
    );
  }

  @override
  Future<User> getUserById(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/api/user/$id');
      final data = res.data;
      if (data == null) throw StateError('Empty user response');
      return _mapProfile(data);
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/user/search',
        queryParameters: {'query': q, 'page': 1, 'pageSize': 20},
      );
      final data = res.data;
      if (data == null) return const [];
      final items = data['items'] as List<dynamic>? ?? const [];
      return items.map((e) => _mapSearchUser(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<void> follow(String followerId, String followingId) async {
    if (followerId == followingId) return;
    final alreadyFollowing = await isFollowing(followerId, followingId);
    if (alreadyFollowing) return;
    try {
      final res = await _dio.post<bool>('/api/user/$followingId/follow');
      if (res.data != true) {
        throw StateError('Follow request failed');
      }
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<void> unfollow(String followerId, String followingId) async {
    if (followerId == followingId) return;
    final alreadyFollowing = await isFollowing(followerId, followingId);
    if (!alreadyFollowing) return;
    try {
      final res = await _dio.post<bool>('/api/user/$followingId/follow');
      if (res.data != false) {
        throw StateError('Unfollow request failed');
      }
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<bool> isFollowing(String followerId, String followingId) async {
    if (followerId == followingId) return false;
    try {
      final res = await _dio.get<Map<String, dynamic>>('/api/user/$followingId');
      final data = res.data;
      if (data == null) return false;
      return data['isFollowedByCurrentUser'] as bool? ?? false;
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }
}
