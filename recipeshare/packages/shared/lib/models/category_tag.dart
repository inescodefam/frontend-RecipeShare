import 'enums.dart';

class CategoryTag {
  final String id;
  final String name;
  final CategoryTagType type;
  final int recipeCount;

  const CategoryTag({
    required this.id,
    required this.name,
    required this.type,
    required this.recipeCount,
  });

  factory CategoryTag.fromJson(Map<String, dynamic> json) {
    return CategoryTag(
      id: json['id'] as String,
      name: json['name'] as String,
      type: enumFromString(
        CategoryTagType.values,
        json['type'] as String,
        fallback: CategoryTagType.category,
      ),
      recipeCount: json['recipeCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'recipeCount': recipeCount,
    };
  }
}