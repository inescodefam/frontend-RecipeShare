import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/models.dart';

class MockDataService {
  final Future<void> _loadingFuture;

  bool _loaded = false;

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

  MockDataService() : _loadingFuture = _load();

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

    _loaded = true;
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
}