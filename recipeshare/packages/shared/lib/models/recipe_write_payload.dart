import 'enums.dart';

/// Input for creating or updating a recipe via the HTTP API (matches backend DTOs).
class RecipeIngredientInput {
  const RecipeIngredientInput({
    required this.name,
    required this.quantity,
    this.unit,
    required this.order,
  });

  final String name;
  final String quantity;
  final int? unit;
  final int order;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'order': order,
      };
}

class RecipeStepInput {
  const RecipeStepInput({
    required this.description,
    required this.order,
  });

  final String description;
  final int order;

  Map<String, dynamic> toJson() => {
        'description': description,
        'order': order,
      };
}

class RecipeWritePayload {
  const RecipeWritePayload({
    required this.title,
    this.description,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.difficulty,
    required this.categoryId,
    required this.tagIds,
    required this.ingredients,
    required this.steps,
  });

  final String title;
  final String? description;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final Difficulty difficulty;

  /// Category id as returned by `/api/categories` or mock data (numeric or `cat_*` strings).
  final String categoryId;

  /// Tag ids as returned by `/api/tags` or mock data.
  final List<String> tagIds;
  final List<RecipeIngredientInput> ingredients;
  final List<RecipeStepInput> steps;

  Map<String, dynamic> toCreateJson() => {
        'title': title,
        'description': description,
        'prepTimeMinutes': prepTimeMinutes,
        'cookTimeMinutes': cookTimeMinutes,
        'servings': servings,
        'difficulty': difficulty.index,
        'categoryId': int.parse(categoryId),
        'tagIds': tagIds.map(int.parse).toList(),
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'steps': steps.map((e) => e.toJson()).toList(),
      };

  Map<String, dynamic> toUpdateJson() => toCreateJson();
}
