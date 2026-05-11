import 'package:dio/dio.dart';

import '../../models/models.dart';
import '../admin_service.dart';
import 'dio_error_message.dart';

class HttpAdminService implements AdminService {
  HttpAdminService(this._dio);

  final Dio _dio;

  Future<T> _request<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw StateError(messageFromDio(e));
    }
  }

  @override
  Future<PagedResponse<AdminRecipeListItem>> getAdminRecipes({
    int pageNumber = 1,
    int pageSize = 20,
    String? search,
    bool? isDeleted,
    bool? isFeatured,
  }) {
    return _request(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/admin/recipes',
        queryParameters: <String, dynamic>{
          'PageNumber': pageNumber,
          'PageSize': pageSize,
          if (search != null && search.trim().isNotEmpty) 'Search': search.trim(),
          if (isDeleted != null) 'IsDeleted': isDeleted,
          if (isFeatured != null) 'IsFeatured': isFeatured,
        },
      );
      return PagedResponse.fromJson(
        res.data ?? const <String, dynamic>{},
        AdminRecipeListItem.fromJson,
      );
    });
  }

  @override
  Future<AdminRecipeDetail> getAdminRecipeById(int id) {
    return _request(() async {
      final res = await _dio.get<Map<String, dynamic>>('/api/admin/recipes/$id');
      return AdminRecipeDetail.fromJson(res.data ?? const <String, dynamic>{});
    });
  }

  @override
  Future<List<Recipe>> getAllRecipes() async {
    final all = <Recipe>[];
    var page = 1;
    var hasNext = true;

    while (hasNext) {
      final pageResult = await getAdminRecipes(pageNumber: page, pageSize: 50);
      for (final item in pageResult.items) {
        all.add(
          Recipe(
            id: '${item.id}',
            userId: '${item.authorId}',
            title: item.title,
            description: '',
            photoUrl: item.imageUrl ?? '',
            prepTime: 0,
            cookTime: 0,
            servings: 1,
            difficulty: item.difficulty,
            categoryId: '0',
            tagIds: const [],
            isFeature: item.isFeatured,
            likesCount: item.likeCount,
            averageRating: item.averageRating,
            ratingCount: item.ratingCount,
            commentCount: item.commentCount,
            createdAt: item.createdAt,
            ingredients: const [],
            steps: const [],
            categoryLabel: item.categoryName,
            authorUsername: item.authorUsername,
          ),
        );
      }
      hasNext = pageResult.hasNextPage;
      page += 1;
    }

    return all;
  }

  @override
  Future<void> setRecipeFeatured(String recipeId, bool featured) async {
    await _request(() async {
      final detail = await getAdminRecipeById(int.parse(recipeId));
      if (detail.isFeatured == featured) return;
      await _dio.patch<void>('/api/admin/recipes/$recipeId/featured');
    });
  }

  @override
  Future<void> deleteRecipe(String recipeId) async {
    await _request(() => _dio.delete<void>('/api/admin/recipes/$recipeId'));
  }

  @override
  Future<void> restoreRecipe(String recipeId) async {
    await _request(() => _dio.post<void>('/api/admin/recipes/$recipeId/restore'));
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _request(() => _dio.delete<void>('/api/admin/comments/$commentId'));
  }

  @override
  Future<void> restoreComment(String commentId) async {
    await _request(() => _dio.post<void>('/api/admin/comments/$commentId/restore'));
  }

  @override
  Future<PagedResponse<AdminUserListItem>> getAdminUsers({
    int pageNumber = 1,
    int pageSize = 20,
    String? search,
  }) {
    return _request(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/admin/users',
        queryParameters: <String, dynamic>{
          'PageNumber': pageNumber,
          'PageSize': pageSize,
          if (search != null && search.trim().isNotEmpty) 'Search': search.trim(),
        },
      );
      return PagedResponse.fromJson(
        res.data ?? const <String, dynamic>{},
        AdminUserListItem.fromJson,
      );
    });
  }

  @override
  Future<void> setUserBlocked(String userId, bool blocked) async {
    await toggleUserBlocked(userId);
  }

  @override
  Future<void> toggleUserBlocked(String userId) async {
    await _request(() => _dio.patch<void>('/api/admin/users/$userId/blocked'));
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _request(() => _dio.delete<void>('/api/admin/users/$userId'));
  }

  @override
  Future<void> restoreUser(String userId) async {
    await _request(() => _dio.post<void>('/api/admin/users/$userId/restore'));
  }

  @override
  Future<PagedResponse<AdminReportSummary>> getAdminReports({
    int pageNumber = 1,
    int pageSize = 20,
    ReportStatus? status,
  }) {
    return _request(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/admin/reports',
        queryParameters: <String, dynamic>{
          'PageNumber': pageNumber,
          'PageSize': pageSize,
          if (status != null) 'ReportStatus': reportStatusToApi(status),
        },
      );
      return PagedResponse.fromJson(
        res.data ?? const <String, dynamic>{},
        AdminReportSummary.fromJson,
      );
    });
  }

  @override
  Future<AdminReportDetail> getAdminReportById(int id) {
    return _request(() async {
      final res = await _dio.get<Map<String, dynamic>>('/api/admin/reports/$id');
      return AdminReportDetail.fromJson(res.data ?? const <String, dynamic>{});
    });
  }

  @override
  Future<void> resolveAdminReport(
    int id, {
    required AdminAction contentAction,
    required AdminAction userAction,
    String? adminNote,
  }) async {
    await _request(
      () => _dio.patch<void>(
        '/api/admin/reports/$id/resolve',
        data: <String, dynamic>{
          'contentAction': adminActionToApi(contentAction),
          'userAction': adminActionToApi(userAction),
          if (adminNote != null && adminNote.trim().isNotEmpty) 'adminNote': adminNote.trim(),
        },
      ),
    );
  }

  @override
  Future<void> dismissAdminReport(int id) async {
    await _request(() => _dio.patch<void>('/api/admin/reports/$id/dismiss'));
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
