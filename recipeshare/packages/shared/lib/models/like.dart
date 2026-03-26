class Like {
  final String id;
  final String userId;
  final String recipeId;
  final DateTime createdAt;

  const Like({
    required this.id,
    required this.userId,
    required this.recipeId,
    required this.createdAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'] as String,
      userId: json['userId'] as String,
      recipeId: json['recipeId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'recipeId': recipeId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}