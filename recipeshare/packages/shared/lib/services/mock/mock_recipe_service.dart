import '../recipe_service.dart';
import '../../models/models.dart';
import 'mock_data_service.dart';

class MockRecipeService implements RecipeService {
  MockRecipeService(this._data);

  final MockDataService _data;

  @override
  Future<List<Recipe>> getFeed(String userId) async {
    final follows = await _data.getFollowsByFollowerId(userId);
    final authorIds = follows.map((f) => f.followingId).toSet();
    final recipes = await _data.getRecipes();
    final filtered =
        recipes.where((r) => authorIds.contains(r.userId)).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  @override
  Future<List<Recipe>> getExplore() async {
    final recipes = await _data.getRecipes();
    final sorted = [...recipes];
    double score(Recipe r) => r.likesCount + r.averageRating * 10;
    sorted.sort((a, b) => score(b).compareTo(score(a)));
    return sorted;
  }

  @override
  Future<List<Recipe>> getFeatured() async {
    return _data.getFeaturedRecipes();
  }

  @override
  Future<Recipe> getRecipeById(String id) async {
    return _data.getRecipeById(id);
  }

  @override
  Future<void> createRecipe(Recipe recipe) async {
    await _data.upsertRecipe(recipe);
  }

  @override
  Future<void> updateRecipe(Recipe recipe) async {
    await _data.upsertRecipe(recipe);
  }

  @override
  Future<void> deleteRecipe(String id) async {
    await _data.deleteRecipeById(id);
  }

  @override
  Future<void> likeRecipe(String recipeId, String userId) async {
    await _data.addLike(
      Like(
        id: 'like_${_data.newId()}',
        userId: userId,
        recipeId: recipeId,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<void> unlikeRecipe(String recipeId, String userId) async {
    await _data.removeLike(userId, recipeId);
  }

  @override
  Future<void> rateRecipe(String recipeId, String userId, int stars) async {
    final clamped = stars < 1 ? 1 : (stars > 5 ? 5 : stars);
    await _data.upsertRating(
      Rating(
        id: 'rating_${_data.newId()}',
        userId: userId,
        recipeId: recipeId,
        stars: clamped,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }
}
