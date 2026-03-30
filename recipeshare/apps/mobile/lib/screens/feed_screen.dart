import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../providers/auth_provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late Future<_FeedVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_FeedVm> _load() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      throw StateError('Feed is only available when logged in');
    }

    final services = context.read<RecipeShareServices>();
    final recipes = await services.recipes.getFeed(user.id);

    final authorIds = recipes.map((r) => r.userId).toSet();
    final authorsById = <String, User>{};

    // Sequential loads are OK for MVP; can be optimized with parallel later.
    for (final authorId in authorIds) {
      authorsById[authorId] = await services.users.getUserById(authorId);
    }

    return _FeedVm(recipes: recipes, authorsById: authorsById);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FeedVm>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingShimmerList());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                snapshot.error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ),
          );
        }
        final vm = snapshot.data;
        if (vm == null || vm.recipes.isEmpty) {
          return const EmptyState(
            icon: Icons.restaurant,
            message: 'No recipes in your feed yet.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _future = _load();
            });
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vm.recipes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (context, index) {
              final recipe = vm.recipes[index];
              final author = vm.authorsById[recipe.userId];

              return RecipeCard(
                recipe: recipe,
                authorUsername: author?.username,
                authorAvatarUrl: author?.profileImageUrl,
                variant: RecipeCardVariant.standard,
                onTap: () => context.push('/recipes/${recipe.id}'),
              );
            },
          ),
        );
      },
    );
  }
}

class _FeedVm {
  const _FeedVm({
    required this.recipes,
    required this.authorsById,
  });

  final List<Recipe> recipes;
  final Map<String, User> authorsById;
}

