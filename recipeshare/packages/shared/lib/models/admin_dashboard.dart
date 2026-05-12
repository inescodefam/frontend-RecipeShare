import 'admin_recipe.dart';
import 'admin_user.dart';

class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.totalUsers,
    required this.totalRecipes,
    required this.mostActiveUserIds,
    required this.mostPopularRecipeIds,
  });

  final int totalUsers;
  final int totalRecipes;
  final List<int> mostActiveUserIds;
  final List<int> mostPopularRecipeIds;

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSummary(
      totalUsers: json['totalUsers'] as int? ?? 0,
      totalRecipes: json['totalRecipes'] as int? ?? 0,
      mostActiveUserIds: (json['mostActiveUsersIds'] as List<dynamic>? ?? const [])
          .map((id) => id as int)
          .toList(),
      mostPopularRecipeIds: (json['mostPopularRecipesIds'] as List<dynamic>? ?? const [])
          .map((id) => id as int)
          .toList(),
    );
  }
}

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.totalUsers,
    required this.totalRecipes,
    required this.pendingReports,
    required this.mostActiveUsers,
    required this.mostPopularRecipes,
  });

  final int totalUsers;
  final int totalRecipes;
  final int pendingReports;
  final List<AdminUserDetail> mostActiveUsers;
  final List<AdminRecipeListItem> mostPopularRecipes;
}
