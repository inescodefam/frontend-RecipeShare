import '../../models/models.dart';
import '../recipe_service.dart';
import 'mock_data_service.dart';

class MockRecipeService implements RecipeService {
  MockRecipeService(this._data);

  final MockDataService _data;

  Future<List<Recipe>> _feedRecipesAsync(String userId) async {
    final follows = await _data.getFollowsByFollowerId(userId);
    final authorIds = follows.map((f) => f.followingId).toSet();
    final recipes = await _data.getRecipes();
    final filtered =
        recipes.where((r) => authorIds.contains(r.userId)).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  @override
  Future<RecipePage> getFeedPage(
    String userId, {
    int? cursor,
    int pageSize = 10,
  }) async {
    final all = await _feedRecipesAsync(userId);
    return RecipePage(
      items: all,
      hasMore: false,
      nextCursor: null,
    );
  }

  @override
  Future<RecipePage> getExplorePage({
    String? search,
    String? categoryId,
    List<String> tagIds = const [],
    int? cursor,
    int pageSize = 10,
  }) async {
    final recipes = await _data.getRecipes();
    final sorted = recipes.where((r) {
      final searchOk = search == null ||
          search.trim().isEmpty ||
          r.title.toLowerCase().contains(search.trim().toLowerCase());
      final categoryOk = categoryId == null || categoryId.isEmpty || r.categoryId == categoryId;
      final tagsOk = tagIds.isEmpty || tagIds.any(r.tagIds.contains);
      return searchOk && categoryOk && tagsOk;
    }).toList();
    double score(Recipe r) => r.likesCount + r.averageRating * 10;
    sorted.sort((a, b) => score(b).compareTo(score(a)));
    return RecipePage(
      items: sorted,
      hasMore: false,
      nextCursor: null,
    );
  }

  @override
  Future<List<Recipe>> getFeatured() async {
    return _data.getFeaturedRecipes();
  }

  @override
  Future<Recipe> getRecipeById(String id) async {
    return _data.getRecipeById(id);
  }

  Ingredient _ingredientFromInput(RecipeIngredientInput i, String recipeId) {
    final amount = double.tryParse(i.quantity) ?? 0;
    return Ingredient(
      id: 'ing_${_data.newId()}',
      recipeId: recipeId,
      name: i.name,
      amount: amount,
      unit: i.unit?.toString() ?? '',
    );
  }

  RecipeStep _stepFromInput(RecipeStepInput s, String recipeId) {
    return RecipeStep(
      id: 'st_${_data.newId()}',
      recipeId: recipeId,
      stepNumber: s.order,
      description: s.description,
    );
  }

  @override
  Future<String> createRecipeWithPayload(
    RecipeWritePayload payload, {
    String? ownerUserId,
  }) async {
    final id = _data.newId();
    final recipeId = 'recipe_$id';
    final recipe = Recipe(
      id: recipeId,
      userId: ownerUserId ?? 'user_0001_admin',
      title: payload.title,
      description: payload.description ?? '',
      photoUrl: '',
      prepTime: payload.prepTimeMinutes,
      cookTime: payload.cookTimeMinutes,
      servings: payload.servings,
      difficulty: payload.difficulty,
      categoryId: payload.categoryId,
      tagIds: [...payload.tagIds],
      isFeature: false,
      likesCount: 0,
      averageRating: 0,
      createdAt: DateTime.now().toUtc(),
      ingredients: payload.ingredients
          .map((e) => _ingredientFromInput(e, recipeId))
          .toList(),
      steps: payload.steps.map((e) => _stepFromInput(e, recipeId)).toList(),
      categoryLabel: null,
      tagLabels: const [],
    );
    await _data.upsertRecipe(recipe);
    return recipeId;
  }

  @override
  Future<void> updateRecipeWithPayload(String id, RecipeWritePayload payload) async {
    final existing = await _data.getRecipeById(id);
    final updated = Recipe(
      id: existing.id,
      userId: existing.userId,
      title: payload.title,
      description: payload.description ?? '',
      photoUrl: existing.photoUrl,
      prepTime: payload.prepTimeMinutes,
      cookTime: payload.cookTimeMinutes,
      servings: payload.servings,
      difficulty: payload.difficulty,
      categoryId: payload.categoryId,
      tagIds: [...payload.tagIds],
      isFeature: existing.isFeature,
      likesCount: existing.likesCount,
      averageRating: existing.averageRating,
      createdAt: existing.createdAt,
      ingredients: payload.ingredients
          .map((e) => _ingredientFromInput(e, id))
          .toList(),
      steps: payload.steps.map((e) => _stepFromInput(e, id)).toList(),
      categoryLabel: existing.categoryLabel,
      tagLabels: existing.tagLabels,
    );
    await _data.upsertRecipe(updated);
  }

  @override
  Future<void> deleteRecipe(String id) async {
    await _data.deleteRecipeById(id);
  }

  @override
  Future<String> uploadRecipeImage(
    String recipeId,
    List<int> bytes, {
    String? filename,
  }) async {
    final current = await _data.getRecipeById(recipeId);
    final next = current.copyWith(
      photoUrl: 'https://picsum.photos/seed/${recipeId}_${bytes.length}/800/600',
    );
    await _data.upsertRecipe(next);
    return next.photoUrl;
  }

  @override
  Future<void> deleteRecipeImage(String recipeId) async {
    final current = await _data.getRecipeById(recipeId);
    await _data.upsertRecipe(current.copyWith(photoUrl: ''));
  }

  @override
  Future<List<CategoryTag>> listRecipeCategories() async {
    final all = await _data.getCategories();
    return all.where((c) => c.type == CategoryTagType.category).toList();
  }

  @override
  Future<List<CategoryTag>> listRecipeTags() async {
    final all = await _data.getTags();
    return all.where((t) => t.type == CategoryTagType.tag).toList();
  }

  @override
  Future<ToggleLikeResult> toggleLikeRecipe(String recipeId) async {
    const userId = 'mock-user';
    final existing = await _data.getLikesByRecipeId(recipeId);
    final liked = existing.any((like) => like.userId == userId);
    if (liked) {
      await _data.removeLike(userId, recipeId);
    } else {
      await _data.addLike(
        Like(
          id: 'like_${_data.newId()}',
          userId: userId,
          recipeId: recipeId,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
    final latest = await _data.getRecipeById(recipeId);
    return ToggleLikeResult(
      isLiked: !liked,
      likeCount: latest.likesCount,
    );
  }

  @override
  Future<RatingSummary> rateRecipe(String recipeId, int stars) async {
    const userId = 'mock-user';
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
    final ratings = await _data.getRatingsByRecipeId(recipeId);
    final avg = ratings.isEmpty
        ? 0.0
        : ratings.fold<int>(0, (sum, r) => sum + r.stars) / ratings.length;
    return RatingSummary(
      myRating: clamped,
      averageRating: avg,
      ratingCount: ratings.length,
    );
  }

}
