import '../models/models.dart';

/// Admin dashboard and moderation. Mock uses the same JSON-backed store as the app.
abstract class AdminService {
  Future<int> getTotalUsers();

  Future<int> getTotalRecipes();

  Future<int> getPendingReportCount();

  Future<int> getFeaturedRecipeCount();

  Future<List<User>> getUsersPage({
    required int page,
    required int pageSize,
    String? filter,
  });

  Future<List<Recipe>> getAllRecipes();

  Future<List<Comment>> getAllComments();

  Future<List<Report>> getAllReports();

  Future<void> setUserBlocked(String userId, bool blocked);

  Future<void> deleteUser(String userId);

  Future<void> setRecipeFeatured(String recipeId, bool featured);

  Future<void> deleteRecipe(String recipeId);

  Future<void> deleteComment(String commentId);

  Future<void> updateReportStatus(String reportId, ReportStatus status);

  Future<Map<String, int>> getRecipeCountByCategory();

  Future<void> renameCategory(String categoryId, String newName);

  Future<void> renameTag(String tagId, String newName);

  Future<void> deleteCategory(String categoryId);

  Future<void> deleteTag(String tagId);

  /// Combine [fromTagId] into [intoTagId] (updates recipes, then removes the old tag).
  Future<void> mergeTags({required String fromTagId, required String intoTagId});
}
