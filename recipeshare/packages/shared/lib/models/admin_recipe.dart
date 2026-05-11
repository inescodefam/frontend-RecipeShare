import 'enums.dart';

class AdminRecipeListItem {
  const AdminRecipeListItem({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.isFeatured,
    required this.isDeleted,
    this.deletedAt,
    required this.createdAt,
    required this.difficulty,
    required this.authorUsername,
    required this.authorId,
    required this.categoryName,
    required this.likeCount,
    required this.commentCount,
    required this.averageRating,
    required this.ratingCount,
  });

  final int id;
  final String title;
  final String? imageUrl;
  final bool isFeatured;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final Difficulty difficulty;
  final String authorUsername;
  final int authorId;
  final String categoryName;
  final int likeCount;
  final int commentCount;
  final double averageRating;
  final int ratingCount;

  factory AdminRecipeListItem.fromJson(Map<String, dynamic> json) {
    return AdminRecipeListItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      difficulty: _difficultyFromApi(json['difficulty']),
      authorUsername: json['authorUsername'] as String? ?? '',
      authorId: json['authorId'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['ratingCount'] as int? ?? 0,
    );
  }
}

class AdminRecipeCommentItem {
  const AdminRecipeCommentItem({
    required this.id,
    required this.content,
    required this.isDeleted,
    this.deletedAt,
    required this.createdAt,
    this.updatedAt,
    required this.authorUsername,
    required this.authorId,
    this.authorProfileImageUrl,
  });

  final int id;
  final String content;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String authorUsername;
  final int authorId;
  final String? authorProfileImageUrl;

  factory AdminRecipeCommentItem.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    return AdminRecipeCommentItem(
      id: json['id'] as int,
      content: json['content'] as String? ?? '',
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      authorUsername: author?['username'] as String? ?? '',
      authorId: author?['id'] as int? ?? 0,
      authorProfileImageUrl: author?['profileImageUrl'] as String?,
    );
  }
}

class AdminRecipeDetail {
  const AdminRecipeDetail({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    required this.isFeatured,
    required this.isDeleted,
    this.deletedAt,
    required this.createdAt,
    this.updatedAt,
    required this.difficulty,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.categoryId,
    required this.categoryName,
    required this.authorUsername,
    required this.authorId,
    required this.tags,
    required this.likeCount,
    required this.commentCount,
    required this.averageRating,
    required this.ratingCount,
    required this.comments,
  });

  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final bool isFeatured;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Difficulty difficulty;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final int categoryId;
  final String categoryName;
  final String authorUsername;
  final int authorId;
  final List<String> tags;
  final int likeCount;
  final int commentCount;
  final double averageRating;
  final int ratingCount;
  final List<AdminRecipeCommentItem> comments;

  factory AdminRecipeDetail.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final comments = (json['comments'] as List<dynamic>? ?? const [])
        .map((e) => AdminRecipeCommentItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return AdminRecipeDetail(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      difficulty: _difficultyFromApi(json['difficulty']),
      prepTimeMinutes: json['prepTimeMinutes'] as int? ?? 0,
      cookTimeMinutes: json['cookTimeMinutes'] as int? ?? 0,
      servings: json['servings'] as int? ?? 1,
      categoryId: json['categoryId'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      authorUsername: author?['username'] as String? ?? '',
      authorId: author?['id'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      comments: comments,
    );
  }
}

Difficulty _difficultyFromApi(dynamic raw) {
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
