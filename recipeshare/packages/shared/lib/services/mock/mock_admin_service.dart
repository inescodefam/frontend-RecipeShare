import '../admin_service.dart';
import '../../models/models.dart';
import 'mock_data_service.dart';

class MockAdminService implements AdminService {
  MockAdminService(this._data);

  final MockDataService _data;

  @override
  Future<int> getTotalUsers() async {
    final users = await _data.getUsers();
    return users.length;
  }

  @override
  Future<int> getTotalRecipes() async {
    final recipes = await _data.getRecipes();
    return recipes.length;
  }

  @override
  Future<int> getPendingReportCount() async {
    final reports = await _data.getReports();
    return reports.where((r) => r.status == ReportStatus.pending).length;
  }

  @override
  Future<int> getFeaturedRecipeCount() async {
    final recipes = await _data.getRecipes();
    return recipes.where((r) => r.isFeature).length;
  }

  @override
  Future<List<User>> getUsersPage({
    required int page,
    required int pageSize,
    String? filter,
  }) async {
    var users = await _data.getUsers();
    switch (filter) {
      case 'blocked':
        users = users.where((u) => u.isBlocked).toList();
        break;
      case 'active':
        users = users.where((u) => !u.isBlocked).toList();
        break;
      default:
        break;
    }
    final start = page * pageSize;
    if (start >= users.length) return const [];
    return users.sublist(
      start,
      start + pageSize > users.length ? users.length : start + pageSize,
    );
  }

  @override
  Future<List<Recipe>> getAllRecipes() async {
    return _data.getRecipes();
  }

  @override
  Future<List<Comment>> getAllComments() async {
    return _data.getAllComments();
  }

  @override
  Future<List<Report>> getAllReports() async {
    return _data.getReports();
  }

  @override
  Future<void> setUserBlocked(String userId, bool blocked) async {
    final u = await _data.getUserById(userId);
    await _data.replaceUser(u.copyWith(isBlocked: blocked));
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _data.deleteUserById(userId);
  }

  @override
  Future<void> setRecipeFeatured(String recipeId, bool featured) async {
    final r = await _data.getRecipeById(recipeId);
    await _data.upsertRecipe(r.copyWith(isFeature: featured));
  }

  @override
  Future<void> deleteRecipe(String recipeId) async {
    await _data.deleteRecipeById(recipeId);
  }

  @override
  Future<void> restoreRecipe(String recipeId) async {
    throw UnimplementedError('Restore recipe is only available with the API.');
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _data.deleteCommentById(commentId);
  }

  @override
  Future<void> restoreComment(String commentId) async {
    throw UnimplementedError('Restore comment is only available with the API.');
  }

  @override
  Future<void> toggleUserBlocked(String userId) async {
    final u = await _data.getUserById(userId);
    await _data.replaceUser(u.copyWith(isBlocked: !u.isBlocked));
  }

  @override
  Future<void> restoreUser(String userId) async {
    throw UnimplementedError('Restore user is only available with the API.');
  }

  @override
  Future<PagedResponse<AdminRecipeListItem>> getAdminRecipes({
    int pageNumber = 1,
    int pageSize = 20,
    String? search,
    bool? isDeleted,
    bool? isFeatured,
  }) async {
    final recipes = await _data.getRecipes();
    final filtered = recipes.where((recipe) {
      if (search != null && search.trim().isNotEmpty) {
        if (!recipe.title.toLowerCase().contains(search.trim().toLowerCase())) {
          return false;
        }
      }
      if (isFeatured != null && recipe.isFeature != isFeatured) return false;
      return true;
    }).toList();
    final start = (pageNumber - 1) * pageSize;
    final slice = start >= filtered.length
        ? const <Recipe>[]
        : filtered.sublist(
            start,
            start + pageSize > filtered.length ? filtered.length : start + pageSize,
          );
    return PagedResponse(
      items: slice
          .map(
            (recipe) => AdminRecipeListItem(
              id: int.tryParse(recipe.id) ?? 0,
              title: recipe.title,
              imageUrl: recipe.photoUrl.isEmpty ? null : recipe.photoUrl,
              isFeatured: recipe.isFeature,
              isDeleted: false,
              createdAt: recipe.createdAt,
              difficulty: recipe.difficulty,
              authorUsername: recipe.authorUsername ?? '',
              authorId: int.tryParse(recipe.userId) ?? 0,
              categoryName: recipe.categoryLabel ?? '',
              likeCount: recipe.likesCount,
              commentCount: recipe.commentCount,
              averageRating: recipe.averageRating,
              ratingCount: recipe.ratingCount,
            ),
          )
          .toList(),
      pageNumber: pageNumber,
      pageSize: pageSize,
      totalCount: filtered.length,
      hasNextPage: start + pageSize < filtered.length,
    );
  }

  @override
  Future<AdminRecipeDetail> getAdminRecipeById(int id) async {
    final recipe = await _data.getRecipeById('$id');
    return AdminRecipeDetail(
      id: int.tryParse(recipe.id) ?? id,
      title: recipe.title,
      description: recipe.description,
      imageUrl: recipe.photoUrl.isEmpty ? null : recipe.photoUrl,
      isFeatured: recipe.isFeature,
      isDeleted: false,
      createdAt: recipe.createdAt,
      difficulty: recipe.difficulty,
      prepTimeMinutes: recipe.prepTime,
      cookTimeMinutes: recipe.cookTime,
      servings: recipe.servings,
      categoryId: int.tryParse(recipe.categoryId) ?? 0,
      categoryName: recipe.categoryLabel ?? '',
      authorUsername: recipe.authorUsername ?? '',
      authorId: int.tryParse(recipe.userId) ?? 0,
      tags: recipe.tagLabels,
      likeCount: recipe.likesCount,
      commentCount: recipe.commentCount,
      averageRating: recipe.averageRating,
      ratingCount: recipe.ratingCount,
      comments: const [],
    );
  }

  @override
  Future<PagedResponse<AdminUserListItem>> getAdminUsers({
    int pageNumber = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final users = await getUsersPage(page: pageNumber - 1, pageSize: pageSize, filter: search);
    final all = await _data.getUsers();
    return PagedResponse(
      items: users
          .map(
            (user) => AdminUserListItem(
              id: int.tryParse(user.id) ?? 0,
              username: user.username,
              email: user.email,
              profileImageUrl: user.profileImageUrl.isEmpty ? null : user.profileImageUrl,
              createdAt: DateTime.now(),
              isBlocked: user.isBlocked,
              isDeleted: false,
            ),
          )
          .toList(),
      pageNumber: pageNumber,
      pageSize: pageSize,
      totalCount: all.length,
      hasNextPage: pageNumber * pageSize < all.length,
    );
  }

  @override
  Future<PagedResponse<AdminReportSummary>> getAdminReports({
    int pageNumber = 1,
    int pageSize = 20,
    ReportStatus? status,
  }) async {
    final reports = await getAllReports();
    final filtered = status == null
        ? reports
        : reports.where((report) => report.status == status).toList();
    final start = (pageNumber - 1) * pageSize;
    final slice = start >= filtered.length
        ? const <Report>[]
        : filtered.sublist(
            start,
            start + pageSize > filtered.length ? filtered.length : start + pageSize,
          );
    return PagedResponse(
      items: slice
          .map(
            (report) => AdminReportSummary(
              id: int.tryParse(report.id) ?? 0,
              targetType: report.targetType,
              targetId: int.tryParse(report.targetId) ?? 0,
              reporterUsername: report.reporterUserId,
              reportedUsername: '',
              reason: report.reason,
              description: report.description,
              status: report.status,
              createdAt: report.createdAt,
            ),
          )
          .toList(),
      pageNumber: pageNumber,
      pageSize: pageSize,
      totalCount: filtered.length,
      hasNextPage: start + pageSize < filtered.length,
    );
  }

  @override
  Future<AdminReportDetail> getAdminReportById(int id) async {
    final reports = await getAllReports();
    final report = reports.firstWhere(
      (item) => int.tryParse(item.id) == id,
      orElse: () => throw StateError('Report not found: $id'),
    );
    return AdminReportDetail(
      id: int.tryParse(report.id) ?? id,
      targetType: report.targetType,
      targetId: int.tryParse(report.targetId) ?? 0,
      reporterUsername: report.reporterUserId,
      reporterId: 0,
      reportedUsername: '',
      reportedUserId: 0,
      reason: report.reason,
      description: report.description,
      status: report.status,
      contentAction: AdminAction.none,
      userAction: AdminAction.none,
      createdAt: report.createdAt,
    );
  }

  @override
  Future<void> resolveAdminReport(
    int id, {
    required AdminAction contentAction,
    required AdminAction userAction,
    String? adminNote,
  }) async {
    await updateReportStatus('$id', ReportStatus.resolved);
  }

  @override
  Future<void> dismissAdminReport(int id) async {
    await updateReportStatus('$id', ReportStatus.dismissed);
  }

  @override
  Future<void> updateReportStatus(String reportId, ReportStatus status) async {
    final reports = await _data.getReports();
    Report? found;
    for (final r in reports) {
      if (r.id == reportId) {
        found = r;
        break;
      }
    }
    if (found == null) {
      throw StateError('Report not found: $reportId');
    }
    await _data.replaceReport(found.copyWith(status: status));
  }

  @override
  Future<Map<String, int>> getRecipeCountByCategory() async {
    final categories = await _data.getCategories();
    final recipes = await _data.getRecipes();
    final map = <String, int>{};
    for (final c in categories) {
      map[c.name] =
          recipes.where((r) => r.categoryId == c.id).length;
    }
    return map;
  }

  @override
  Future<void> renameCategory(String categoryId, String newName) async {
    final categories = await _data.getCategories();
    final c = categories.firstWhere(
      (x) => x.id == categoryId,
      orElse: () => throw StateError('Category not found'),
    );
    await _data.upsertCategoryTag(c.copyWith(name: newName.trim()));
  }

  @override
  Future<void> renameTag(String tagId, String newName) async {
    final tags = await _data.getTags();
    final t = tags.firstWhere(
      (x) => x.id == tagId,
      orElse: () => throw StateError('Tag not found'),
    );
    await _data.upsertCategoryTag(t.copyWith(name: newName.trim()));
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _data.deleteCategoryTagById(categoryId, CategoryTagType.category);
  }

  @override
  Future<void> deleteTag(String tagId) async {
    await _data.deleteCategoryTagById(tagId, CategoryTagType.tag);
  }

  @override
  Future<void> mergeTags({
    required String fromTagId,
    required String intoTagId,
  }) async {
    if (fromTagId == intoTagId) return;
    await _data.mergeTagsReplace(fromTagId, intoTagId);
  }
}
