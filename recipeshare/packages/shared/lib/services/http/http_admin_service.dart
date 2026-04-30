import 'package:dio/dio.dart';

import '../../models/models.dart';
import '../admin_service.dart';
import 'dio_error_message.dart';

class HttpAdminService implements AdminService {
  HttpAdminService(this._dio);

  final Dio _dio;

  _RecipeCursorPage _mapRecipePage(Map<String, dynamic> data) {
    final raw = data['items'] as List<dynamic>? ?? const [];
    final items = raw
        .map((e) => Recipe.fromApiSummary(e as Map<String, dynamic>))
        .toList();
    final next = data['nextCursor'];
    final nextCursor = next is int ? next : int.tryParse('$next');
    final hasMore = data['hasMore'] as bool? ?? false;
    return _RecipeCursorPage(items: items, hasMore: hasMore, nextCursor: nextCursor);
  }

  @override
  Future<List<Recipe>> getAllRecipes() async {
    final all = <Recipe>[];
    int? cursor;
    bool hasMore = true;

    while (hasMore) {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/recipes',
        queryParameters: <String, dynamic>{
          'pageSize': 50,
          if (cursor != null) 'cursor': cursor,
        },
      );
      final data = res.data ?? const <String, dynamic>{};
      final page = _mapRecipePage(data);
      all.addAll(page.items);
      hasMore = page.hasMore;
      cursor = page.nextCursor;
      if (cursor == null) break;
    }

    return all;
  }

  @override
  Future<void> setRecipeFeatured(String recipeId, bool featured) async {
    final path = featured
        ? '/api/recipes/$recipeId/feature'
        : '/api/recipes/$recipeId/unfeature';
    try {
      await _dio.patch<void>(path);
    } on DioException catch (e) {
      throw StateError(messageFromDio(e));
    }
  }

  @override
  Future<int> getTotalUsers() async => throw UnimplementedError();

  @override
  Future<int> getTotalRecipes() async => throw UnimplementedError();

  @override
  Future<int> getPendingReportCount() async => throw UnimplementedError();

  @override
  Future<int> getFeaturedRecipeCount() async => throw UnimplementedError();

  @override
  Future<List<User>> getUsersPage({
    required int page,
    required int pageSize,
    String? filter,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<Comment>> getAllComments() async => throw UnimplementedError();

  @override
  Future<List<Report>> getAllReports() async => throw UnimplementedError();

  @override
  Future<void> setUserBlocked(String userId, bool blocked) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteUser(String userId) async => throw UnimplementedError();

  @override
  Future<void> deleteRecipe(String recipeId) async => throw UnimplementedError();

  @override
  Future<void> deleteComment(String commentId) async => throw UnimplementedError();

  @override
  Future<void> updateReportStatus(String reportId, ReportStatus status) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, int>> getRecipeCountByCategory() async =>
      throw UnimplementedError();

  @override
  Future<void> renameCategory(String categoryId, String newName) async =>
      throw UnimplementedError();

  @override
  Future<void> renameTag(String tagId, String newName) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteCategory(String categoryId) async => throw UnimplementedError();

  @override
  Future<void> deleteTag(String tagId) async => throw UnimplementedError();

  @override
  Future<void> mergeTags({
    required String fromTagId,
    required String intoTagId,
  }) async =>
      throw UnimplementedError();
}

class _RecipeCursorPage {
  const _RecipeCursorPage({
    required this.items,
    required this.hasMore,
    required this.nextCursor,
  });

  final List<Recipe> items;
  final bool hasMore;
  final int? nextCursor;
}
