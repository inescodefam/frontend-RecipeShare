import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../providers/auth_provider.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Future<_DetailVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailVm> _load() async {
    final id = GoRouterState.of(context).pathParameters['id'];
    if (id == null || id.isEmpty) {
      throw StateError('Missing recipe id');
    }

    final currentUserId = context.read<AuthProvider>().user?.id;
    final services = context.read<RecipeShareServices>();
    final recipe = await services.recipes.getRecipeById(id);
    final author = await services.users.getUserById(recipe.userId);

    // MVP: only display recipe details. Future steps: add like/rate/comments.
    return _DetailVm(
      recipe: recipe,
      author: author,
      currentUserId: currentUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipeId = GoRouterState.of(context).pathParameters['id'] ?? '';

    return FutureBuilder<_DetailVm>(
      future: _future,
      builder: (context, snapshot) {
        final appBar = AppBar(
          title: const Text('Recipe'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: appBar, body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: appBar,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                ),
              ),
            ),
          );
        }

        final vm = snapshot.data;
        if (vm == null) {
          return Scaffold(
            appBar: appBar,
            body: Center(
              child: Text('Recipe not found: $recipeId'),
            ),
          );
        }

        final recipe = vm.recipe;
        final author = vm.author;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(recipe.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: recipe.photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFFE8E8E6)),
                    errorWidget: (_, __, ___) =>
                        Container(color: const Color(0xFFE8E8E6), child: const Icon(Icons.restaurant, size: 56, color: AppColors.textSecondary)),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    Row(
                      children: [
                        UserAvatar(
                          imageUrl: author.profileImageUrl,
                          nameForInitials: author.username,
                          radius: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                author.username,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              DifficultyBadge(difficulty: recipe.difficulty),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      recipe.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.favorite_border_rounded, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('${recipe.likesCount}', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(width: 14),
                        RatingStars(rating: recipe.averageRating, size: 18),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Ingredients',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _IngredientsList(ingredients: recipe.ingredients),
                    const SizedBox(height: 20),
                    Text(
                      'Steps',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _StepsList(steps: recipe.steps),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IngredientsList extends StatelessWidget {
  const _IngredientsList({required this.ingredients});

  final List<Ingredient> ingredients;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ingredients.map((ing) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${ing.name} - ${ing.amount} ${ing.unit}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StepsList extends StatelessWidget {
  const _StepsList({required this.steps});

  final List<RecipeStep> steps;

  @override
  Widget build(BuildContext context) {
    final sorted = [...steps]..sort((a, b) => a.stepNumber.compareTo(b.stepNumber));
    return Column(
      children: sorted.map((step) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    step.stepNumber.toString(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DetailVm {
  const _DetailVm({
    required this.recipe,
    required this.author,
    required this.currentUserId,
  });

  final Recipe recipe;
  final User author;
  final String? currentUserId;
}

