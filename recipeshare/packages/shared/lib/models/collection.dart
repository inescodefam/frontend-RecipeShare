class Collection {
  final String id;
  final String userId;
  final String name;
  final List<String> recipeIds;

  const Collection({
    required this.id,
    required this.userId,
    required this.name,
    required this.recipeIds,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      recipeIds: (json['recipeIds'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'recipeIds': recipeIds,
    };
  }
}