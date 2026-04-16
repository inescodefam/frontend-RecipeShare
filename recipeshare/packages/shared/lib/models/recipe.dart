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

  final String? categoryLabel;

  final List<String> tagLabels;

  final String? authorUsername;
  final String? authorAvatarUrl;

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
    this.categoryLabel,
    this.tagLabels = const [],
    this.authorUsername,
    this.authorAvatarUrl,
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
      categoryLabel: json['categoryLabel'] as String?,
      tagLabels: json['tagLabels'] != null
          ? (json['tagLabels'] as List<dynamic>).map((e) => e.toString()).toList()
          : const [],
      authorUsername: json['authorUsername'] as String?,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
    );
  }

  static Difficulty _difficultyFromApi(dynamic raw) {
    if (raw is int) {
      final i = raw.clamp(0, Difficulty.values.length - 1);
      return Difficulty.values[i];
    }
    if (raw is String) {
      final lower = raw.toLowerCase();
      return enumFromString(Difficulty.values, lower, fallback: Difficulty.easy);
    }
    return Difficulty.easy;
  }

  factory Recipe.fromApiSummary(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final authorId = author == null ? '0' : '${author['id']}';
    final tags = (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final imageUrl =
        (json['imageUrl'] as String?) ?? (json['photoUrl'] as String?) ?? '';
    return Recipe(
      id: '${json['id']}',
      userId: authorId,
      title: json['title'] as String? ?? '',
      description: '',
      photoUrl: imageUrl,
      prepTime: json['prepTimeMinutes'] as int? ?? 0,
      cookTime: json['cookTimeMinutes'] as int? ?? 0,
      servings: 1,
      difficulty: _difficultyFromApi(json['difficulty']),
      categoryId: '0',
      tagIds: const [],
      isFeature: json['isFeatured'] as bool? ?? false,
      likesCount: 0,
      averageRating: 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      ingredients: const [],
      steps: const [],
      categoryLabel: json['categoryName'] as String?,
      tagLabels: tags,
      authorUsername: author?['username'] as String?,
      authorAvatarUrl: author?['profileImageUrl'] as String?,
    );
  }

  factory Recipe.fromApiDetail(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final authorId = author == null ? '0' : '${author['id']}';
    final rid = '${json['id']}';
    final tagNames =
        (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final imageUrl =
        (json['imageUrl'] as String?) ?? (json['photoUrl'] as String?) ?? '';
    final ingredients = (json['ingredients'] as List<dynamic>? ?? const [])
        .map((e) => Ingredient.fromApiJson(e as Map<String, dynamic>, recipeId: rid))
        .toList();
    final steps = (json['steps'] as List<dynamic>? ?? const [])
        .map((e) => RecipeStep.fromApiJson(e as Map<String, dynamic>, recipeId: rid))
        .toList();
    return Recipe(
      id: rid,
      userId: authorId,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      photoUrl: imageUrl,
      prepTime: json['prepTimeMinutes'] as int? ?? 0,
      cookTime: json['cookTimeMinutes'] as int? ?? 0,
      servings: json['servings'] as int? ?? 1,
      difficulty: _difficultyFromApi(json['difficulty']),
      categoryId: '${json['categoryId']}',
      tagIds: const [],
      isFeature: json['isFeatured'] as bool? ?? false,
      likesCount: 0,
      averageRating: 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      ingredients: ingredients,
      steps: steps,
      categoryLabel: json['categoryName'] as String?,
      tagLabels: tagNames,
      authorUsername: author?['username'] as String?,
      authorAvatarUrl: author?['profileImageUrl'] as String?,
    );
  }

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
    String? categoryLabel,
    List<String>? tagLabels,
    String? authorUsername,
    String? authorAvatarUrl,
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
      categoryLabel: categoryLabel ?? this.categoryLabel,
      tagLabels: tagLabels ?? this.tagLabels,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
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
      'categoryLabel': categoryLabel,
      'tagLabels': tagLabels,
      'authorUsername': authorUsername,
      'authorAvatarUrl': authorAvatarUrl,
    };
  }
}
