class Rating {
  final String id;
  final String userId;
  final String recipeId;
  final int stars;
  final DateTime createdAt;

  const Rating({
    required this.id,
    required this.userId,
    required this.recipeId,
    required this.stars,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as String,
      userId: json['userId'] as String,
      recipeId: json['recipeId'] as String,
      stars: json['stars'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'recipeId': recipeId,
      'stars': stars,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}