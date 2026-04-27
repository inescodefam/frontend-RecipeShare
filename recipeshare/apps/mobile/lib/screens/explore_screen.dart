import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.refreshToken});

  final String? refreshToken;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final List<Recipe> _recipes = [];
  List<CategoryTag> _categories = const [];
  List<CategoryTag> _tags = const [];
  String? _selectedCategoryId;
  final Set<String> _selectedTagIds = <String>{};
  int? _nextCursor;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadInitial();
    }
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore) return;
    final pos = _scrollController.position;
    if (pos.pixels > pos.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _recipes.clear();
      _nextCursor = null;
      _hasMore = true;
    });
    try {
      final services = context.read<RecipeShareServices>();
      if (_categories.isEmpty && _tags.isEmpty) {
        _categories = await services.recipes.listRecipeCategories();
        _tags = await services.recipes.listRecipeTags();
      }
      final page = await services.recipes.getExplorePage(
        search: _searchController.text,
        categoryId: _selectedCategoryId,
        tagIds: _selectedTagIds.toList(),
        pageSize: 12,
      );
      if (!mounted) return;
      setState(() {
        _recipes.addAll(page.items);
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
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

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final services = context.read<RecipeShareServices>();
      final page = await services.recipes.getExplorePage(
        search: _searchController.text,
        categoryId: _selectedCategoryId,
        tagIds: _selectedTagIds.toList(),
        cursor: _nextCursor,
        pageSize: 12,
      );
      if (!mounted) return;
      setState(() {
        _recipes.addAll(page.items);
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search recipes by name',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: _openFilters,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadInitial(),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: LoadingShimmerList());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                ),
          ),
        ),
      );
    }
    if (_recipes.isEmpty) {
      return const EmptyState(
        icon: Icons.explore_rounded,
        message: 'No recipes to explore yet.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _recipes.length + (_loadingMore ? 1 : 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (context, index) {
          if (index >= _recipes.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final recipe = _recipes[index];
          return RecipeCard(
            recipe: recipe,
            authorUsername: recipe.authorUsername,
            authorAvatarUrl: recipe.authorAvatarUrl,
            variant: RecipeCardVariant.standard,
            onTap: () async {
              await context.push('/recipes/${recipe.id}');
              if (mounted) _loadInitial();
            },
          );
        },
      ),
    );
  }

  Future<void> _openFilters() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        String? selectedCategory = _selectedCategoryId;
        final selectedTags = <String>{..._selectedTagIds};
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 72),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All categories'),
                          ),
                          ..._categories.map(
                            (c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (value) => setModalState(() => selectedCategory = value),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags
                            .map(
                              (tag) => FilterChip(
                                label: Text(tag.name),
                                selected: selectedTags.contains(tag.id),
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (selected) {
                                      selectedTags.add(tag.id);
                                    } else {
                                      selectedTags.remove(tag.id);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategoryId = null;
                                _selectedTagIds.clear();
                              });
                              Navigator.of(ctx).pop();
                              _loadInitial();
                            },
                            child: const Text('Reset'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategoryId = selectedCategory;
                                _selectedTagIds
                                  ..clear()
                                  ..addAll(selectedTags);
                              });
                              Navigator.of(ctx).pop();
                              _loadInitial();
                            },
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
