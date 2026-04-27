class Comment {
  final String id;
  final String userId;
  final String recipeId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? authorUsername;
  final String? authorAvatarUrl;

  const Comment({
    required this.id,
    required this.userId,
    required this.recipeId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.authorUsername,
    this.authorAvatarUrl,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      recipeId: json['recipeId'] as String? ?? '',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'] as String),
      authorUsername: json['authorUsername'] as String?,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
    );
  }

  factory Comment.fromApiJson(Map<String, dynamic> json, {required String recipeId}) {
    final author = json['author'] as Map<String, dynamic>?;
    return Comment(
      id: '${json['id']}',
      userId: '${author?['id'] ?? ''}',
      recipeId: recipeId,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'] as String),
      authorUsername: author?['username'] as String?,
      authorAvatarUrl: author?['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'recipeId': recipeId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'authorUsername': authorUsername,
      'authorAvatarUrl': authorAvatarUrl,
    };
  }
}