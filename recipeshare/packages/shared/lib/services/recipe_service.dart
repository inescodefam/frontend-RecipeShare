import '../models/models.dart';

class RecipePage {
  const RecipePage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<Recipe> items;
  final bool hasMore;

  final int? nextCursor;
}

class ToggleLikeResult {
  const ToggleLikeResult({
    required this.isLiked,
    required this.likeCount,
  });

  final bool isLiked;
  final int likeCount;
}

class RatingSummary {
  const RatingSummary({
    required this.myRating,
    required this.averageRating,
    required this.ratingCount,
  });

  final int? myRating;
  final double averageRating;
  final int ratingCount;
}

abstract class RecipeService {
  Future<RecipePage> getFeedPage(
    String userId, {
    int? cursor,
    int pageSize = 10,
  });

  Future<RecipePage> getExplorePage({
    String? search,
    String? categoryId,
    List<String> tagIds = const [],
    int? cursor,
    int pageSize = 10,
  });

  Future<List<Recipe>> getFeatured();

  Future<Recipe> getRecipeById(String id);

  Future<String> createRecipeWithPayload(
    RecipeWritePayload payload, {
    String? ownerUserId,
  });

  Future<void> updateRecipeWithPayload(String id, RecipeWritePayload payload);

  Future<void> deleteRecipe(String id);

  Future<String> uploadRecipeImage(
    String recipeId,
    List<int> bytes, {
    String? filename,
  });

  Future<void> deleteRecipeImage(String recipeId);

  Future<List<CategoryTag>> listRecipeCategories();

  Future<List<CategoryTag>> listRecipeTags();

  Future<ToggleLikeResult> toggleLikeRecipe(String recipeId);

  Future<RatingSummary> rateRecipe(String recipeId, int stars);
}
