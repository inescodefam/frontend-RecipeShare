
class AdminCatalogRow {
  const AdminCatalogRow({
    required this.id,
    required this.name,
    required this.recipeCount,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final int recipeCount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory AdminCatalogRow.fromJson(Map<String, dynamic> json) {
    return AdminCatalogRow(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      recipeCount: (json['recipeCount'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? false,
      createdAt: _parseDate(json['createdaAt'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}
