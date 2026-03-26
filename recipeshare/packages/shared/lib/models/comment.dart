class Comment {
  final String id;
  final String userId;
  final String recipeId;
  final String content;
  final DateTime createdAt;
  final String? parentCommentId;

  const Comment({
    required this.id,
    required this.userId,
    required this.recipeId,
    required this.content,
    required this.createdAt,
    this.parentCommentId,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      recipeId: json['recipeId'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      parentCommentId: json['parentCommentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'recipeId': recipeId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'parentCommentId': parentCommentId,
    };
  }
}