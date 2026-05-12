import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../providers/auth_provider.dart';

Future<bool> showAdminUserDetailDialog(
  BuildContext context, {
  required int userId,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _AdminUserDetailDialog(userId: userId),
  ).then((value) => value ?? false);
}

Future<bool> showAdminUserRecipesDialog(
  BuildContext context, {
  required int userId,
  required String username,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _AdminUserRecipesDialog(
      userId: userId,
      username: username,
    ),
  ).then((value) => value ?? false);
}

Future<bool> showAdminRecipeDetailDialog(
  BuildContext context, {
  required int recipeId,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _AdminRecipeDetailDialog(recipeId: recipeId),
  ).then((value) => value ?? false);
}

class _AdminUserDetailDialog extends StatefulWidget {
  const _AdminUserDetailDialog({required this.userId});

  final int userId;

  @override
  State<_AdminUserDetailDialog> createState() => _AdminUserDetailDialogState();
}

class _AdminUserDetailDialogState extends State<_AdminUserDetailDialog> {
  AdminUserDetail? _user;
  bool _loading = true;
  String? _error;
  bool _changed = false;
  bool _busy = false;

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
      final user = await context.read<RecipeShareServices>().admin.getAdminUserById(widget.userId);
      if (!mounted) return;
      setState(() {
        _user = user;
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

  bool _isCurrentUser(AdminUserDetail user) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    if (currentUserId == null) return false;
    return currentUserId == '${user.id}';
  }

  Future<void> _runAction(Future<void> Function() action, String message) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _changed = true;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showRecipes(AdminUserDetail user) async {
    final changed = await showAdminUserRecipesDialog(
      context,
      userId: user.id,
      username: user.username,
    );
    if (changed) {
      _changed = true;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return AlertDialog(
      title: Text(user == null ? 'User details' : user.username),
      content: SizedBox(
        width: 560,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text(_error!, style: const TextStyle(color: AppColors.error))
                : user == null
                    ? const Text('User not found.')
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.tonal(
                                  onPressed: _busy || _isCurrentUser(user)
                                      ? null
                                      : () => _runAction(
                                            () => context
                                                .read<RecipeShareServices>()
                                                .admin
                                                .toggleUserBlocked('${user.id}'),
                                            user.isBlocked
                                                ? 'User unblocked.'
                                                : 'User blocked.',
                                          ),
                                  child: Text(user.isBlocked ? 'Unblock' : 'Block'),
                                ),
                                FilledButton.tonal(
                                  onPressed: _busy || _isCurrentUser(user)
                                      ? null
                                      : () => _runAction(
                                            () => user.isDeleted
                                                ? context
                                                    .read<RecipeShareServices>()
                                                    .admin
                                                    .restoreUser('${user.id}')
                                                : context
                                                    .read<RecipeShareServices>()
                                                    .admin
                                                    .deleteUser('${user.id}'),
                                            user.isDeleted
                                                ? 'User restored.'
                                                : 'User deleted.',
                                          ),
                                  child: Text(user.isDeleted ? 'Restore' : 'Delete'),
                                ),
                                FilledButton.tonal(
                                  onPressed: _busy ? null : () => _showRecipes(user),
                                  child: const Text('View recipes'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _DetailLine(label: 'Email', value: user.email),
                            _DetailLine(label: 'Recipes', value: '${user.recipeCount}'),
                            _DetailLine(label: 'Comments', value: '${user.commentCount}'),
                            _DetailLine(label: 'Likes', value: '${user.likeCount}'),
                            _DetailLine(label: 'Ratings', value: '${user.ratingCount}'),
                            _DetailLine(label: 'Followers', value: '${user.followerCount}'),
                            _DetailLine(label: 'Following', value: '${user.followingCount}'),
                            _DetailLine(label: 'Blocked', value: user.isBlocked ? 'Yes' : 'No'),
                            _DetailLine(label: 'Deleted', value: user.isDeleted ? 'Yes' : 'No'),
                          ],
                        ),
                      ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, _changed),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _AdminUserRecipesDialog extends StatefulWidget {
  const _AdminUserRecipesDialog({
    required this.userId,
    required this.username,
  });

  final int userId;
  final String username;

  @override
  State<_AdminUserRecipesDialog> createState() => _AdminUserRecipesDialogState();
}

class _AdminUserRecipesDialogState extends State<_AdminUserRecipesDialog> {
  List<AdminRecipeListItem> _recipes = const [];
  bool _loading = true;
  String? _error;
  bool _changed = false;

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
      final recipes = await context
          .read<RecipeShareServices>()
          .admin
          .getAdminRecipesForAuthor(widget.userId);
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
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

  Future<void> _openRecipe(AdminRecipeListItem recipe) async {
    final changed = await showAdminRecipeDetailDialog(context, recipeId: recipe.id);
    if (changed) {
      _changed = true;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.username} recipes'),
      content: SizedBox(
        width: 720,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text(_error!, style: const TextStyle(color: AppColors.error))
                : _recipes.isEmpty
                    ? const Text('This user has no recipes.')
                    : Scrollbar(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _recipes.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final recipe = _recipes[index];
                            return ListTile(
                              title: Text(recipe.title),
                              subtitle: Text(
                                '${recipe.categoryName} • ${recipe.likeCount} likes • '
                                '${recipe.averageRating.toStringAsFixed(1)} rating',
                              ),
                              trailing: recipe.isDeleted
                                  ? const Text('Deleted')
                                  : recipe.isFeatured
                                      ? const Text('Featured')
                                      : null,
                              onTap: () => _openRecipe(recipe),
                            );
                          },
                        ),
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _changed),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _AdminRecipeDetailDialog extends StatefulWidget {
  const _AdminRecipeDetailDialog({required this.recipeId});

  final int recipeId;

  @override
  State<_AdminRecipeDetailDialog> createState() => _AdminRecipeDetailDialogState();
}

class _AdminRecipeDetailDialogState extends State<_AdminRecipeDetailDialog> {
  AdminRecipeDetail? _recipe;
  bool _loading = true;
  String? _error;
  bool _changed = false;
  bool _busy = false;

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
      final recipe =
          await context.read<RecipeShareServices>().admin.getAdminRecipeById(widget.recipeId);
      if (!mounted) return;
      setState(() {
        _recipe = recipe;
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

  Future<void> _runAction(Future<void> Function() action, String message) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _changed = true;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _recipe;

    return AlertDialog(
      title: Text(recipe == null ? 'Recipe details' : recipe.title),
      content: SizedBox(
        width: 720,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text(_error!, style: const TextStyle(color: AppColors.error))
                : recipe == null
                    ? const Text('Recipe not found.')
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Featured',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                Switch(
                                  value: recipe.isFeatured,
                                  onChanged: _busy
                                      ? null
                                      : (_) => _runAction(
                                            () => context
                                                .read<RecipeShareServices>()
                                                .admin
                                                .setRecipeFeatured(
                                                  '${recipe.id}',
                                                  !recipe.isFeatured,
                                                ),
                                            recipe.isFeatured
                                                ? 'Recipe removed from featured.'
                                                : 'Recipe marked as featured.',
                                          ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.tonal(
                                  onPressed: _busy
                                      ? null
                                      : () => _runAction(
                                            () => recipe.isDeleted
                                                ? context
                                                    .read<RecipeShareServices>()
                                                    .admin
                                                    .restoreRecipe('${recipe.id}')
                                                : context
                                                    .read<RecipeShareServices>()
                                                    .admin
                                                    .deleteRecipe('${recipe.id}'),
                                            recipe.isDeleted
                                                ? 'Recipe restored.'
                                                : 'Recipe deleted.',
                                          ),
                                  child: Text(recipe.isDeleted ? 'Restore' : 'Delete'),
                                ),
                              ],
                            ),
                            if (recipe.imageUrl != null && recipe.imageUrl!.trim().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  recipe.imageUrl!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _DetailLine(label: 'Author', value: recipe.authorUsername),
                            _DetailLine(label: 'Category', value: recipe.categoryName),
                            _DetailLine(label: 'Difficulty', value: recipe.difficulty.name),
                            _DetailLine(
                              label: 'Time',
                              value:
                                  '${recipe.prepTimeMinutes} min prep, ${recipe.cookTimeMinutes} min cook',
                            ),
                            _DetailLine(label: 'Servings', value: '${recipe.servings}'),
                            _DetailLine(label: 'Likes', value: '${recipe.likeCount}'),
                            _DetailLine(label: 'Comments', value: '${recipe.commentCount}'),
                            _DetailLine(
                              label: 'Rating',
                              value:
                                  '${recipe.averageRating.toStringAsFixed(1)} (${recipe.ratingCount})',
                            ),
                            _DetailLine(label: 'Deleted', value: recipe.isDeleted ? 'Yes' : 'No'),
                            if (recipe.tags.isNotEmpty)
                              _DetailLine(label: 'Tags', value: recipe.tags.join(', ')),
                            if (recipe.description != null && recipe.description!.trim().isNotEmpty)
                              _DetailLine(label: 'Description', value: recipe.description!),
                            if (recipe.ingredients.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              ...recipe.ingredients.map(
                                (ingredient) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    ingredient.unit.isEmpty
                                        ? '${ingredient.name} — ${ingredient.amount}'
                                        : '${ingredient.name} — ${ingredient.amount} ${ingredient.unit}',
                                  ),
                                ),
                              ),
                            ],
                            if (recipe.steps.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text('Steps', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              ...recipe.steps.map(
                                (step) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text('${step.stepNumber}. ${step.description}'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, _changed),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
