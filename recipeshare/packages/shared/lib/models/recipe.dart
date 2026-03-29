import 'enums.dart';
import 'ingredient.dart';
import 'recipe_step.dart';

class Recipe {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String photoUrl;
  final int prepTime;
  final int cookTime;
  final int servings;
  final Difficulty difficulty;
  final String categoryId;
  final List<String> tagIds;
  final bool isFeature;
  final int likesCount;
  final double averageRating;
  final DateTime createdAt;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;

  const Recipe({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.photoUrl,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.difficulty,
    required this.categoryId,
    required this.tagIds,
    required this.isFeature,
    required this.likesCount,
    required this.averageRating,
    required this.createdAt,
    required this.ingredients,
    required this.steps,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      photoUrl: json['photoUrl'] as String,
      prepTime: json['prepTime'] as int,
      cookTime: json['cookTime'] as int,
      servings: json['servings'] as int,
      difficulty: enumFromString(
        Difficulty.values,
        json['difficulty'] as String,
        fallback: Difficulty.easy,
      ),
      categoryId: json['categoryId'] as String,
      tagIds: (json['tagIds'] as List<dynamic>).cast<String>(),
      isFeature: json['isFeature'] as bool,
      likesCount: json['likesCount'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((item) => Ingredient.fromJson(item as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>)
          .map((item) => RecipeStep.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Used by mock services when likes/ratings/feature flags change in memory.
  Recipe copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? photoUrl,
    int? prepTime,
    int? cookTime,
    int? servings,
    Difficulty? difficulty,
    String? categoryId,
    List<String>? tagIds,
    bool? isFeature,
    int? likesCount,
    double? averageRating,
    DateTime? createdAt,
    List<Ingredient>? ingredients,
    List<RecipeStep>? steps,
  }) {
    return Recipe(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      categoryId: categoryId ?? this.categoryId,
      tagIds: tagIds ?? this.tagIds,
      isFeature: isFeature ?? this.isFeature,
      likesCount: likesCount ?? this.likesCount,
      averageRating: averageRating ?? this.averageRating,
      createdAt: createdAt ?? this.createdAt,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'photoUrl': photoUrl,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'difficulty': difficulty.name,
      'categoryId': categoryId,
      'tagIds': tagIds,
      'isFeature': isFeature,
      'likesCount': likesCount,
      'averageRating': averageRating,
      'createdAt': createdAt.toIso8601String(),
      'ingredients': ingredients.map((item) => item.toJson()).toList(),
      'steps': steps.map((item) => item.toJson()).toList(),
    };
  }
}