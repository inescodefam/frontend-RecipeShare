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
  Future<void> deleteComment(String commentId) async {
    await _data.deleteCommentById(commentId);
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
