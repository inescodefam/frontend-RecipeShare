import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

class AdminStatisticsTab extends StatefulWidget {
  const AdminStatisticsTab({super.key});

  @override
  State<AdminStatisticsTab> createState() => _AdminStatisticsTabState();
}

class _AdminStatisticsTabState extends State<AdminStatisticsTab> {
  AdminDashboardStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await context.read<RecipeShareServices>().admin.getAdminDashboard();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final stats = _stats;
    if (stats == null) {
      return const Center(child: Text('No statistics available.'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _MetricCard(
                label: 'Total users',
                value: '${stats.totalUsers}',
                icon: Icons.people_outline,
              ),
              _MetricCard(
                label: 'Total recipes',
                value: '${stats.totalRecipes}',
                icon: Icons.restaurant_menu_outlined,
              ),
              _MetricCard(
                label: 'Pending reports',
                value: '${stats.pendingReports}',
                icon: Icons.flag_outlined,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Most active users',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Ranked by recipes, likes, and ratings.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          if (stats.mostActiveUsers.isEmpty)
            const Text('No active users yet.')
          else
            _UsersTable(users: stats.mostActiveUsers),
          const SizedBox(height: 32),
          Text(
            'Most popular recipes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Ranked by likes and ratings.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          if (stats.mostPopularRecipes.isEmpty)
            const Text('No recipes yet.')
          else
            _RecipesTable(recipes: stats.mostPopularRecipes),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.users});

  final List<AdminUserDetail> users;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Username')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Recipes')),
                  DataColumn(label: Text('Comments')),
                  DataColumn(label: Text('Likes')),
                  DataColumn(label: Text('Followers')),
                ],
                rows: users.map((user) {
                  return DataRow(
                    cells: [
                      DataCell(Text(user.username)),
                      DataCell(Text(user.email)),
                      DataCell(Text('${user.recipeCount}')),
                      DataCell(Text('${user.commentCount}')),
                      DataCell(Text('${user.likeCount}')),
                      DataCell(Text('${user.followerCount}')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecipesTable extends StatelessWidget {
  const _RecipesTable({required this.recipes});

  final List<AdminRecipeListItem> recipes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Author')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Likes')),
                  DataColumn(label: Text('Comments')),
                  DataColumn(label: Text('Rating')),
                ],
                rows: recipes.map((recipe) {
                  return DataRow(
                    cells: [
                      DataCell(Text(recipe.title)),
                      DataCell(Text(recipe.authorUsername)),
                      DataCell(Text(recipe.categoryName)),
                      DataCell(Text('${recipe.likeCount}')),
                      DataCell(Text('${recipe.commentCount}')),
                      DataCell(
                        Text(
                          '${recipe.averageRating.toStringAsFixed(1)} (${recipe.ratingCount})',
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
