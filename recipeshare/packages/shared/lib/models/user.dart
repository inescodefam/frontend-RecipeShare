class User {
  final String id;
  final String username;
  final String email;
  final String passwordHash;
  final String bio;
  final String profileImageUrl;
  final bool isBlocked;
  final bool isAdmin;
  final int followersCount;
  final int followingCount;
  final int recipesCount;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.bio,
    required this.profileImageUrl,
    required this.isBlocked,
    required this.isAdmin,
    required this.followersCount,
    required this.followingCount,
    required this.recipesCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      bio: json['bio'] as String,
      profileImageUrl: json['profileImageUrl'] as String,
      isBlocked: json['isBlocked'] as bool,
      isAdmin: json['isAdmin'] as bool,
      followersCount: json['followersCount'] as int,
      followingCount: json['followingCount'] as int,
      recipesCount: json['recipesCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'passwordHash': passwordHash,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'isBlocked': isBlocked,
      'isAdmin': isAdmin,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'recipesCount': recipesCount,
    };
  }
}