class Collection {
  final String id;
  final String userId;
  final String name;
  final List<String> recipeIds;
  final int recipeCount;
  final DateTime? createdAt;

  const Collection({
    required this.id,
    required this.userId,
    required this.name,
    required this.recipeIds,
    this.recipeCount = 0,
    this.createdAt,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: '${json['id']}',
      userId: '${json['userId'] ?? ''}',
      name: json['name'] as String,
      recipeIds: (json['recipeIds'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => '$e')
          .toList(),
      recipeCount: json['recipeCount'] as int? ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
    );
  }

  factory Collection.fromApiJson(Map<String, dynamic> json) {
    return Collection(
      id: '${json['id']}',
      userId: '',
      name: json['name'] as String? ?? '',
      recipeIds: const [],
      recipeCount: json['recipeCount'] as int? ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'recipeIds': recipeIds,
      'recipeCount': recipeCount,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}