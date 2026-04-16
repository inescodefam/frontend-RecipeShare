class Ingredient {
  final String id;
  final String recipeId;
  final String name;
  final double amount;
  final String unit;

  const Ingredient({
    required this.id,
    required this.recipeId,
    required this.name,
    required this.amount,
    required this.unit,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }

  /// Backend recipe detail uses quantity (string) and optional unit enum index.
  factory Ingredient.fromApiJson(
    Map<String, dynamic> json, {
    required String recipeId,
  }) {
    final qty = json['quantity']?.toString() ?? '';
    final amount = double.tryParse(qty) ?? 0.0;
    final unitEnum = json['unit'];
    final unitStr = unitEnum == null ? '' : unitEnum.toString();
    return Ingredient(
      id: '',
      recipeId: recipeId,
      name: json['name'] as String? ?? '',
      amount: amount,
      unit: unitStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeId': recipeId,
      'name': name,
      'amount': amount,
      'unit': unit,
    };
  }
}