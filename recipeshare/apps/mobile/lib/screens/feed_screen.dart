import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../providers/auth_provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, this.refreshToken});

  final String? refreshToken;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _scrollController = ScrollController();
  final List<Recipe> _recipes = [];
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
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FeedScreen oldWidget) {
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
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      setState(() {
        _error = 'Feed is only available when logged in';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _recipes.clear();
      _nextCursor = null;
      _hasMore = true;
    });
    try {
      final services = context.read<RecipeShareServices>();
      final page = await services.recipes.getFeedPage(user.id, pageSize: 12);
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
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    setState(() => _loadingMore = true);
    try {
      final services = context.read<RecipeShareServices>();
      final page = await services.recipes.getFeedPage(
        user.id,
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
        icon: Icons.restaurant,
        message: 'No recipes in your feed yet. Follow cooks to see their recipes here.',
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
}
