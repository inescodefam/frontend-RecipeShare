import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';

const _uuid = Uuid();

class MockDataService {
  late final Future<void> _loadingFuture;

  late final List<User> _users;
  late final List<Recipe> _recipes;
  late final List<CategoryTag> _categories;
  late final List<CategoryTag> _tags;
  late final List<Comment> _comments;
  late final List<Like> _likes;
  late final List<Rating> _ratings;
  late final List<Collection> _collections;
  late final List<Report> _reports;
  late final List<Follow> _follows;

  MockDataService() {
    _loadingFuture = _load();
  }

  Future<void> _ensureLoaded() => _loadingFuture;

  Future<void> _load() async {
    // Load JSON from asset bundle once during service startup.
    final usersJson = await rootBundle.loadString(
      'packages/shared/lib/mock_data/users.json',
    );
    final recipesJson = await rootBundle.loadString(
      'packages/shared/lib/mock_data/recipes.json',
    );
    final categoriesJson = await rootBundle.loadString(
      'packages/shared/lib/mock_data/categories.json',
    );
    final tagsJson = await rootBundle.loadString(
      'packages/shared/lib/mock_data/tags.json',
    );
    final commentsJson = await rootBundle.loadString(
      'packages/shared/lib/mock_data/comments.json',
    );
    final likesJson = await rootBundle.loadString(
      'packages/shared/lib/mock_data/likes.json',
    );
    final ratingsJson = await rootBundle.loadString(
      'packages/shared/lib/mock_data/ratings.json',
    );
    final collectionsJson = await rootBundle.loadString(
      'packages/shared/lib/mock_data/collections.json',
    );
    final reportsJson = await rootBundle.loadString(
      'packages/shared/lib/mock_data/reports.json',
    );
    final followsJson = await rootBundle.loadString(
      'packages/shared/lib/mock_data/follows.json',
    );

    _users = (jsonDecode(usersJson) as List<dynamic>)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();

    _recipes = (jsonDecode(recipesJson) as List<dynamic>)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();

    final categoriesAndTags = (jsonDecode(categoriesJson) as List<dynamic>)
        .map((e) => CategoryTag.fromJson(e as Map<String, dynamic>))
        .toList();

    final tags = (jsonDecode(tagsJson) as List<dynamic>)
        .map((e) => CategoryTag.fromJson(e as Map<String, dynamic>))
        .toList();

    _categories = categoriesAndTags
        .where((c) => c.type == CategoryTagType.category)
        .toList();
    _tags = tags.where((t) => t.type == CategoryTagType.tag).toList();

    _comments = (jsonDecode(commentsJson) as List<dynamic>)
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();

    _likes = (jsonDecode(likesJson) as List<dynamic>)
        .map((e) => Like.fromJson(e as Map<String, dynamic>))
        .toList();

    _ratings = (jsonDecode(ratingsJson) as List<dynamic>)
        .map((e) => Rating.fromJson(e as Map<String, dynamic>))
        .toList();

    _collections = (jsonDecode(collectionsJson) as List<dynamic>)
        .map((e) => Collection.fromJson(e as Map<String, dynamic>))
        .toList();

    _reports = (jsonDecode(reportsJson) as List<dynamic>)
        .map((e) => Report.fromJson(e as Map<String, dynamic>))
        .toList();

    _follows = (jsonDecode(followsJson) as List<dynamic>)
        .map((e) => Follow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<List<User>> getUsers() async {
    await _simulateDelay();
    await _ensureLoaded();
    return List.unmodifiable(_users);
  }

  Future<User> getUserById(String id) async {
    await _simulateDelay();
    await _ensureLoaded();
    final user = _users.where((u) => u.id == id);
    if (user.isEmpty) {
      throw StateError('User not found: $id');
    }
    return user.first;
  }

  Future<List<Recipe>> getRecipes() async {
    await _simulateDelay();
    await _ensureLoaded();
    return List.unmodifiable(_recipes);
  }

  Future<Recipe> getRecipeById(String id) async {
    await _simulateDelay();
    await _ensureLoaded();
    final recipe = _recipes.where((r) => r.id == id);
    if (recipe.isEmpty) {
      throw StateError('Recipe not found: $id');
    }
    return recipe.first;
  }

  Future<List<Recipe>> getRecipesByUserId(String userId) async {
    await _simulateDelay();
    await _ensureLoaded();
    return List.unmodifiable(_recipes.where((r) => r.userId == userId));
  }

  Future<List<Recipe>> getFeaturedRecipes() async {
    await _simulateDelay();
    await _ensureLoaded();
    return List.unmodifiable(_recipes.where((r) => r.isFeature));
  }

  Future<List<CategoryTag>> getCategories() async {
    await _simulateDelay();
    await _ensureLoaded();
    return List.unmodifiable(_categories);
  }

  Future<List<CategoryTag>> getTags() async {
    await _simulateDelay();
    await _ensureLoaded();
    return List.unmodifiable(_tags);
  }

  Future<List<Comment>> getCommentsByRecipeId(String recipeId) async {
    await _simulateDelay();
    await _ensureLoaded();
    return List.unmodifiable(_comments.where((c) => c.recipeId == recipeId));
  }

  Future<List<Like>> getLikesByRecipeId(String recipeId) async {
    await _simulateDelay();
    await _ensureLoaded();
    return List.unmodifiable(_likes.where((l) => l.recipeId == recipeId));
  }

  Future<List<Rating>> getRatingsByRecipeId(String recipeId) async {
    await _simulateDelay();
    await _ensureLoaded();
    return List.unmodifiable(_ratings.where((r) => r.recipeId == recipeId));
  }

  Future<List<Collection>> getCollectionsByUserId(String userId) async {
    await _simulateDelay();
    await _ensureLoaded();
    return List.unmodifiable(
      _collections.where((c) => c.userId == userId),
    );
  }

  Future<List<Collection>> getAllCollections() async {
    await _simulateDelay();
    await _ensureLoaded();
    return List.unmodifiable(_collections);
  }

  Future<Collection?> getCollectionById(String id) async {
    await _simulateDelay();
    await _ensureLoaded();
    try {
      return _collections.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Report>> getReports() async {
    await _simulateDelay();
    await _ensureLoaded();
    return List.unmodifiable(_reports);
  }

  Future<List<Follow>> getFollowsByFollowerId(String followerId) async {
    await _simulateDelay();
    await _ensureLoaded();
    return List.unmodifiable(
      _follows.where((f) => f.followerId == followerId),
    );
  }

  Future<List<Follow>> getFollowsByFollowingId(String followingId) async {
    await _simulateDelay();
    await _ensureLoaded();
    return List.unmodifiable(
      _follows.where((f) => f.followingId == followingId),
    );
  }

  // --- Mutations (mock phase: in-memory only; real API will POST/PATCH instead) ---

  Future<Comment?> getCommentById(String id) async {
    await _simulateDelay();
    await _ensureLoaded();
    try {
      return _comments.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<User?> findUserByEmail(String email) async {
    await _simulateDelay();
    await _ensureLoaded();
    final lower = email.toLowerCase();
    try {
      return _users.firstWhere((u) => u.email.toLowerCase() == lower);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertRecipe(Recipe recipe) async {
    await _simulateDelay();
    await _ensureLoaded();
    final i = _recipes.indexWhere((r) => r.id == recipe.id);
    if (i >= 0) {
      _recipes[i] = recipe;
    } else {
      _recipes.add(recipe);
      final ui = _users.indexWhere((u) => u.id == recipe.userId);
      if (ui >= 0) {
        final u = _users[ui];
        _users[ui] = u.copyWith(recipesCount: u.recipesCount + 1);
      }
    }
  }

  Future<void> deleteRecipeById(String id) async {
    await _simulateDelay();
    await _ensureLoaded();
    _purgeRecipeData(id);
  }

  void _purgeRecipeData(String id) {
    final i = _recipes.indexWhere((r) => r.id == id);
    if (i < 0) return;
    final authorId = _recipes[i].userId;
    _recipes.removeAt(i);
    final ui = _users.indexWhere((u) => u.id == authorId);
    if (ui >= 0) {
      final u = _users[ui];
      _users[ui] = u.copyWith(recipesCount: (u.recipesCount - 1).clamp(0, 1 << 30));
    }
    _likes.removeWhere((l) => l.recipeId == id);
    _ratings.removeWhere((r) => r.recipeId == id);
    _comments.removeWhere((c) => c.recipeId == id);
    for (var ci = 0; ci < _collections.length; ci++) {
      final c = _collections[ci];
      if (c.recipeIds.contains(id)) {
        _collections[ci] = Collection(
          id: c.id,
          userId: c.userId,
          name: c.name,
          recipeIds: c.recipeIds.where((rid) => rid != id).toList(),
        );
      }
    }
  }

  Future<void> addLike(Like like) async {
    await _simulateDelay();
    await _ensureLoaded();
    final exists = _likes.any(
      (l) => l.userId == like.userId && l.recipeId == like.recipeId,
    );
    if (exists) return;
    _likes.add(like);
    final ri = _recipes.indexWhere((r) => r.id == like.recipeId);
    if (ri >= 0) {
      final r = _recipes[ri];
      _recipes[ri] = r.copyWith(likesCount: r.likesCount + 1);
    }
  }

  Future<void> removeLike(String userId, String recipeId) async {
    await _simulateDelay();
    await _ensureLoaded();
    final before = _likes.length;
    _likes.removeWhere(
      (l) => l.userId == userId && l.recipeId == recipeId,
    );
    if (_likes.length == before) return;
    final ri = _recipes.indexWhere((r) => r.id == recipeId);
    if (ri >= 0) {
      final r = _recipes[ri];
      _recipes[ri] = r.copyWith(
        likesCount: (r.likesCount - 1).clamp(0, 1 << 30),
      );
    }
  }

  Future<void> upsertRating(Rating rating) async {
    await _simulateDelay();
    await _ensureLoaded();
    _ratings.removeWhere(
      (r) => r.userId == rating.userId && r.recipeId == rating.recipeId,
    );
    _ratings.add(rating);
    _recalcAverageRating(rating.recipeId);
  }

  void _recalcAverageRating(String recipeId) {
    final list = _ratings.where((r) => r.recipeId == recipeId).toList();
    if (list.isEmpty) return;
    final sum = list.fold<int>(0, (a, r) => a + r.stars);
    final avg = sum / list.length;
    final ri = _recipes.indexWhere((r) => r.id == recipeId);
    if (ri >= 0) {
      final r = _recipes[ri];
      _recipes[ri] = r.copyWith(averageRating: double.parse(avg.toStringAsFixed(2)));
    }
  }

  Future<void> addComment(Comment comment) async {
    await _simulateDelay();
    await _ensureLoaded();
    _comments.add(comment);
  }

  Future<void> deleteCommentById(String id) async {
    await _simulateDelay();
    await _ensureLoaded();
    _comments.removeWhere((c) => c.id == id);
  }

  Future<void> addFollow(Follow follow) async {
    await _simulateDelay();
    await _ensureLoaded();
    final exists = _follows.any(
      (f) =>
          f.followerId == follow.followerId &&
          f.followingId == follow.followingId,
    );
    if (exists) return;
    _follows.add(follow);
    _bumpFollowCounts(follow.followerId, follow.followingId, 1);
  }

  Future<void> removeFollow(String followerId, String followingId) async {
    await _simulateDelay();
    await _ensureLoaded();
    final before = _follows.length;
    _follows.removeWhere(
      (f) => f.followerId == followerId && f.followingId == followingId,
    );
    if (_follows.length == before) return;
    _bumpFollowCounts(followerId, followingId, -1);
  }

  void _bumpFollowCounts(String followerId, String followingId, int delta) {
    final fi = _users.indexWhere((u) => u.id == followerId);
    if (fi >= 0) {
      final u = _users[fi];
      _users[fi] = u.copyWith(
        followingCount: (u.followingCount + delta).clamp(0, 1 << 30),
      );
    }
    final ti = _users.indexWhere((u) => u.id == followingId);
    if (ti >= 0) {
      final u = _users[ti];
      _users[ti] = u.copyWith(
        followersCount: (u.followersCount + delta).clamp(0, 1 << 30),
      );
    }
  }

  Future<void> upsertCollection(Collection collection) async {
    await _simulateDelay();
    await _ensureLoaded();
    final i = _collections.indexWhere((c) => c.id == collection.id);
    if (i >= 0) {
      _collections[i] = collection;
    } else {
      _collections.add(collection);
    }
  }

  Future<void> deleteCollectionById(String id) async {
    await _simulateDelay();
    await _ensureLoaded();
    _collections.removeWhere((c) => c.id == id);
  }

  Future<void> addReport(Report report) async {
    await _simulateDelay();
    await _ensureLoaded();
    _reports.add(report);
  }

  Future<void> replaceReport(Report report) async {
    await _simulateDelay();
    await _ensureLoaded();
    final i = _reports.indexWhere((r) => r.id == report.id);
    if (i >= 0) {
      _reports[i] = report;
    } else {
      _reports.add(report);
    }
  }

  Future<void> replaceUser(User user) async {
    await _simulateDelay();
    await _ensureLoaded();
    final i = _users.indexWhere((u) => u.id == user.id);
    if (i >= 0) {
      _users[i] = user;
    } else {
      _users.add(user);
    }
  }

  /// Removes a user and their content from the in-memory mock store (admin).
  Future<void> deleteUserById(String id) async {
    await _simulateDelay();
    await _ensureLoaded();
    final recipeIds = _recipes.where((r) => r.userId == id).map((r) => r.id).toList();
    for (final rid in recipeIds) {
      _purgeRecipeData(rid);
    }
    _users.removeWhere((u) => u.id == id);
    _follows.removeWhere((f) => f.followerId == id || f.followingId == id);
    _collections.removeWhere((c) => c.userId == id);
    _likes.removeWhere((l) => l.userId == id);
    _ratings.removeWhere((r) => r.userId == id);
    _comments.removeWhere((c) => c.userId == id);
    _reports.removeWhere((r) => r.reporterUserId == id);
  }

  Future<List<Comment>> getAllComments() async {
    await _simulateDelay();
    await _ensureLoaded();
    return List.unmodifiable(_comments);
  }

  Future<void> upsertCategoryTag(CategoryTag tag) async {
    await _simulateDelay();
    await _ensureLoaded();
    if (tag.type == CategoryTagType.category) {
      final i = _categories.indexWhere((c) => c.id == tag.id);
      if (i >= 0) {
        _categories[i] = tag;
      } else {
        _categories.add(tag);
      }
    } else {
      final i = _tags.indexWhere((t) => t.id == tag.id);
      if (i >= 0) {
        _tags[i] = tag;
      } else {
        _tags.add(tag);
      }
    }
  }

  Future<void> deleteCategoryTagById(String id, CategoryTagType type) async {
    await _simulateDelay();
    await _ensureLoaded();
    if (type == CategoryTagType.category) {
      _categories.removeWhere((c) => c.id == id);
    } else {
      _tags.removeWhere((t) => t.id == id);
    }
  }

  /// Rewrites recipe tag lists and drops [fromTagId] from the tag catalog.
  Future<void> mergeTagsReplace(String fromTagId, String intoTagId) async {
    await _simulateDelay();
    await _ensureLoaded();
    for (var i = 0; i < _recipes.length; i++) {
      final r = _recipes[i];
      if (!r.tagIds.contains(fromTagId)) continue;
      final next = <String>{...r.tagIds};
      next.remove(fromTagId);
      next.add(intoTagId);
      _recipes[i] = r.copyWith(tagIds: next.toList());
    }
    _tags.removeWhere((t) => t.id == fromTagId);
  }

  String newId() => _uuid.v4();
}