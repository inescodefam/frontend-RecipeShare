class RecipeStep {
  final String id;
  final String recipeId;
  final int stepNumber;
  final String description;

  const RecipeStep({
    required this.id,
    required this.recipeId,
    required this.stepNumber,
    required this.description,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String,
      stepNumber: json['stepNumber'] as int,
      description: json['description'] as String,
    );
  }

  factory RecipeStep.fromApiJson(
    Map<String, dynamic> json, {
    required String recipeId,
  }) {
    return RecipeStep(
      id: '',
      recipeId: recipeId,
      stepNumber: json['order'] as int? ?? 0,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeId': recipeId,
      'stepNumber': stepNumber,
      'description': description,
    };
  }
}