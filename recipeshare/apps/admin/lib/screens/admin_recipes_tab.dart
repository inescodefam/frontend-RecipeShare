import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../widgets/admin_moderation_detail_dialogs.dart';

class AdminRecipesTab extends StatefulWidget {
  const AdminRecipesTab({super.key});

  @override
  State<AdminRecipesTab> createState() => _AdminRecipesTabState();
}

class _AdminRecipesTabState extends State<AdminRecipesTab> {
  final _search = TextEditingController();
  List<AdminRecipeListItem> _recipes = const [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  final int _pageSize = 10;
  int _totalCount = 0;
  bool _hasNextPage = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    final nextPage = page ?? _page;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<RecipeShareServices>().admin.getAdminRecipes(
            pageNumber: nextPage,
            pageSize: _pageSize,
            search: _search.text.trim().isEmpty ? null : _search.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _recipes = result.items;
        _page = result.pageNumber;
        _totalCount = result.totalCount;
        _hasNextPage = result.hasNextPage;
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

  Future<void> _toggleFeatured(AdminRecipeListItem recipe) async {
    try {
      await context
          .read<RecipeShareServices>()
          .admin
          .setRecipeFeatured('${recipe.id}', !recipe.isFeatured);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            recipe.isFeatured
                ? 'Recipe removed from featured.'
                : 'Recipe marked as featured.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _setDeleted(AdminRecipeListItem recipe, bool delete) async {
    try {
      final admin = context.read<RecipeShareServices>().admin;
      if (delete) {
        await admin.deleteRecipe('${recipe.id}');
      } else {
        await admin.restoreRecipe('${recipe.id}');
      }
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(delete ? 'Recipe deleted.' : 'Recipe restored.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openRecipeDetail(AdminRecipeListItem recipe) async {
    final updated = await showAdminRecipeDetailDialog(context, recipeId: recipe.id);
    if (updated && mounted) {
      await _load(page: _page);
    }
  }

  Future<void> _showComments(AdminRecipeListItem recipe) async {
    try {
      final detail = await context
          .read<RecipeShareServices>()
          .admin
          .getAdminRecipeById(recipe.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => _RecipeCommentsDialog(
          recipeTitle: detail.title,
          comments: detail.comments,
          onDelete: (comment) async {
            await context.read<RecipeShareServices>().admin.deleteComment('${comment.id}');
          },
          onRestore: (comment) async {
            await context.read<RecipeShareServices>().admin.restoreComment('${comment.id}');
          },
          reload: () => context.read<RecipeShareServices>().admin.getAdminRecipeById(recipe.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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

    return RefreshIndicator(
      onRefresh: () => _load(page: _page),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _search,
            onSubmitted: (_) => _load(page: 1),
            decoration: InputDecoration(
              labelText: 'Search recipes',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Search',
                onPressed: () => _load(page: 1),
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
          const SizedBox(height: 16),
          PagerBar(
            page: _page,
            pageSize: _pageSize,
            totalCount: _totalCount,
            hasNextPage: _hasNextPage,
            onPrevious: _page > 1 ? () => _load(page: _page - 1) : null,
            onNext: _hasNextPage ? () => _load(page: _page + 1) : null,
          ),
          const SizedBox(height: 16),
          if (_recipes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No recipes found.'),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('View details')),
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Title')),
                          DataColumn(label: Text('Author')),
                          DataColumn(label: Text('Deleted')),
                          DataColumn(label: Text('Featured')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _recipes.map((recipe) {
                          return DataRow(
                            cells: [
                              DataCell(
                                TextButton(
                                  onPressed: () => _openRecipeDetail(recipe),
                                  child: const Text('View'),
                                ),
                              ),
                              DataCell(Text('${recipe.id}')),
                              DataCell(Text(recipe.title)),
                              DataCell(Text(recipe.authorUsername)),
                              DataCell(Text(recipe.isDeleted ? 'Yes' : 'No')),
                              DataCell(
                                Switch(
                                  value: recipe.isFeatured,
                                  onChanged: (_) => _toggleFeatured(recipe),
                                ),
                              ),
                              DataCell(
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: () => _showComments(recipe),
                                      child: const Text('Comments'),
                                    ),
                                    TextButton(
                                      onPressed: () => _setDeleted(recipe, !recipe.isDeleted),
                                      child: Text(recipe.isDeleted ? 'Restore' : 'Delete'),
                                    ),
                                  ],
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
            ),
        ],
      ),
    );
  }
}

class _RecipeCommentsDialog extends StatefulWidget {
  const _RecipeCommentsDialog({
    required this.recipeTitle,
    required this.comments,
    required this.onDelete,
    required this.onRestore,
    required this.reload,
  });

  final String recipeTitle;
  final List<AdminRecipeCommentItem> comments;
  final Future<void> Function(AdminRecipeCommentItem comment) onDelete;
  final Future<void> Function(AdminRecipeCommentItem comment) onRestore;
  final Future<AdminRecipeDetail> Function() reload;

  @override
  State<_RecipeCommentsDialog> createState() => _RecipeCommentsDialogState();
}

class _RecipeCommentsDialogState extends State<_RecipeCommentsDialog> {
  late List<AdminRecipeCommentItem> _comments = widget.comments;
  bool _busy = false;

  Future<void> _refresh() async {
    setState(() => _busy = true);
    try {
      final detail = await widget.reload();
      if (!mounted) return;
      setState(() {
        _comments = detail.comments;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _toggleComment(AdminRecipeCommentItem comment) async {
    setState(() => _busy = true);
    try {
      if (comment.isDeleted) {
        await widget.onRestore(comment);
      } else {
        await widget.onDelete(comment);
      }
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Comments for ${widget.recipeTitle}'),
      content: SizedBox(
        width: 640,
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : _comments.isEmpty
                ? const Text('No comments on this recipe.')
                : SingleChildScrollView(
                    child: Column(
                      children: _comments
                          .map(
                            (comment) => ListTile(
                              title: Text(comment.content),
                              subtitle: Text(
                                '${comment.authorUsername} • '
                                '${comment.isDeleted ? 'Deleted' : 'Active'}',
                              ),
                              trailing: TextButton(
                                onPressed: () => _toggleComment(comment),
                                child: Text(comment.isDeleted ? 'Restore' : 'Delete'),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

class PagerBar extends StatelessWidget {
  const PagerBar({
    super.key,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasNextPage,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasNextPage;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final start = totalCount == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final end = totalCount == 0 ? 0 : (start + pageSize - 1).clamp(0, totalCount);
    return Row(
      children: [
        Text('Showing $start-$end of $totalCount'),
        const Spacer(),
        TextButton(onPressed: onPrevious, child: const Text('Previous')),
        Text('Page $page'),
        TextButton(onPressed: onNext, child: const Text('Next')),
      ],
    );
  }
}
