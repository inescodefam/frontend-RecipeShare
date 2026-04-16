import '../models/models.dart';
import '../models/recipe_write_payload.dart';

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

abstract class RecipeService {
  Future<RecipePage> getFeedPage(
    String userId, {
    int? cursor,
    int pageSize = 10,
  });

  Future<RecipePage> getExplorePage({
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

  Future<void> likeRecipe(String recipeId, String userId);

  Future<void> unlikeRecipe(String recipeId, String userId);

  Future<void> rateRecipe(String recipeId, String userId, int stars);
}
