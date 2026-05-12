import 'ingredient.dart';
import 'recipe_step.dart';

class AdminUserListItem {
  const AdminUserListItem({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    required this.createdAt,
    required this.isBlocked,
    required this.isDeleted,
    this.deletedAt,
  });

  final int id;
  final String username;
  final String email;
  final String? profileImageUrl;
  final DateTime createdAt;
  final bool isBlocked;
  final bool isDeleted;
  final DateTime? deletedAt;

  factory AdminUserListItem.fromJson(Map<String, dynamic> json) {
    return AdminUserListItem(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isBlocked: json['isBlocked'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );
  }
}

class AdminUserRecipeItem {
  const AdminUserRecipeItem({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.createdAt,
    required this.isFeatured,
    required this.isDeleted,
    this.deletedAt,
  });

  final int id;
  final String title;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isFeatured;
  final bool isDeleted;
  final DateTime? deletedAt;

  factory AdminUserRecipeItem.fromJson(Map<String, dynamic> json) {
    return AdminUserRecipeItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isFeatured: json['isFeatured'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );
  }
}

class AdminUserDetail {
  const AdminUserDetail({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    required this.createdAt,
    required this.isBlocked,
    required this.isDeleted,
    required this.recipeCount,
    required this.commentCount,
    required this.likeCount,
    required this.ratingCount,
    required this.followerCount,
    required this.followingCount,
    this.recentRecipes = const [],
  });

  final int id;
  final String username;
  final String email;
  final String? profileImageUrl;
  final DateTime createdAt;
  final bool isBlocked;
  final bool isDeleted;
  final int recipeCount;
  final int commentCount;
  final int likeCount;
  final int ratingCount;
  final int followerCount;
  final int followingCount;
  final List<AdminUserRecipeItem> recentRecipes;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final recentRecipes = (json['recentRecipes'] as List<dynamic>? ?? const [])
        .map((e) => AdminUserRecipeItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return AdminUserDetail(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isBlocked: json['isBlocked'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      recipeCount: json['recipeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      followerCount: json['followerCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      recentRecipes: recentRecipes,
    );
  }
}
