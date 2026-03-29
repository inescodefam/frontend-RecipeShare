import '../models/models.dart';

/// Recipe browsing and mutations. Matches the shape your .NET API will expose later.
abstract class RecipeService {
  Future<List<Recipe>> getFeed(String userId);

  Future<List<Recipe>> getExplore();

  Future<List<Recipe>> getFeatured();

  Future<Recipe> getRecipeById(String id);

  Future<void> createRecipe(Recipe recipe);

  Future<void> updateRecipe(Recipe recipe);

  Future<void> deleteRecipe(String id);

  Future<void> likeRecipe(String recipeId, String userId);

  Future<void> unlikeRecipe(String recipeId, String userId);

  Future<void> rateRecipe(String recipeId, String userId, int stars);
}
