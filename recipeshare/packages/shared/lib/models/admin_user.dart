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
