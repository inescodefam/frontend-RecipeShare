import 'package:dio/dio.dart';

import '../../models/models.dart';
import '../comment_service.dart';
import 'dio_error_message.dart';

class HttpCommentService implements CommentService {
  HttpCommentService(this._dio);

  final Dio _dio;

  @override
  Future<CommentPage> getCommentsForRecipe(
    String recipeId, {
    int? cursor,
    int pageSize = 10,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/recipes/$recipeId/comments',
        queryParameters: <String, dynamic>{
          'pageSize': pageSize,
          if (cursor != null) 'cursor': cursor,
        },
      );
      final data = res.data ?? const <String, dynamic>{};
      final items = (data['items'] as List<dynamic>? ?? const [])
          .map((e) => Comment.fromApiJson(e as Map<String, dynamic>, recipeId: recipeId))
          .toList();
      return CommentPage(
        items: items,
        hasMore: data['hasMore'] as bool? ?? false,
        nextCursor: data['nextCursor'] as int?,
      );
    } on DioException catch (e) {
      throw StateError(messageFromDio(e));
    }
  }

  @override
  Future<Comment> addComment({
    required String recipeId,
    required String content,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/recipes/$recipeId/comments',
        data: <String, dynamic>{'content': content},
      );
      final data = res.data;
      if (data == null) throw StateError('Empty comment response');
      return Comment.fromApiJson(data, recipeId: recipeId);
    } on DioException catch (e) {
      throw StateError(messageFromDio(e));
    }
  }

  @override
  Future<Comment> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/api/comments/$commentId',
        data: <String, dynamic>{'content': content},
      );
      final data = res.data;
      if (data == null) throw StateError('Empty comment response');
      return Comment.fromApiJson(data, recipeId: '');
    } on DioException catch (e) {
      throw StateError(messageFromDio(e));
    }
  }

  @override
  Future<void> deleteComment(String commentId) async {
    try {
      await _dio.delete<void>('/api/comments/$commentId');
    } on DioException catch (e) {
      throw StateError(messageFromDio(e));
    }
  }
}
