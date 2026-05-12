import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../providers/auth_provider.dart';
import '../utils/recipe_share.dart';
import '../widgets/report_content_dialog.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
  });

  final String recipeId;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Future<_DetailVm> _future;
  final Set<String> _sessionReportedTargetKeys = {};

  void _goBackOrFeed() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home/feed');
    }
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<_DetailVm> _load() async {
    final id = widget.recipeId;
    if (id.isEmpty) {
      throw StateError('Missing recipe id');
    }

    final currentUserId = context.read<AuthProvider>().user?.id;
    final services = context.read<RecipeShareServices>();
    final recipe = await services.recipes.getRecipeById(id);
    final commentPage = await services.comments.getCommentsForRecipe(id, pageSize: 20);
    final collections = await services.collections.getMyCollections();

    final User author;
    if (recipe.authorUsername != null && recipe.authorUsername!.isNotEmpty) {
      author = User(
        id: recipe.userId,
        username: recipe.authorUsername!,
        email: '',
        passwordHash: '',
        bio: '',
        profileImageUrl: recipe.authorAvatarUrl ?? '',
        isBlocked: false,
        isAdmin: false,
        followersCount: 0,
        followingCount: 0,
        recipesCount: 0,
      );
    } else {
      author = await services.users.getUserById(recipe.userId);
    }

    final reportedTargetKeys = await _reportedTargetKeysForContent(
      services: services,
      currentUserId: currentUserId,
      recipe: recipe,
      comments: commentPage.items,
    );

    return _DetailVm(
      recipe: recipe,
      author: author,
      comments: commentPage.items,
      collections: collections,
      currentUserId: currentUserId,
      reportedTargetKeys: reportedTargetKeys,
    );
  }

  String _contentReportKey(ReportTargetType targetType, String targetId) {
    return '${targetType.name}:$targetId';
  }

  Future<Set<String>> _reportedTargetKeysForContent({
    required RecipeShareServices services,
    required String? currentUserId,
    required Recipe recipe,
    required List<Comment> comments,
  }) async {
    if (currentUserId == null) return const {};

    final keys = <String>{};
    final recipeTargetId = int.tryParse(recipe.id);
    if (recipeTargetId != null &&
        await services.reports.hasReported(
          reporterUserId: currentUserId,
          targetType: ReportTargetType.recipe,
          targetId: recipeTargetId,
        )) {
      keys.add(_contentReportKey(ReportTargetType.recipe, recipe.id));
    }

    for (final comment in comments) {
      final commentTargetId = int.tryParse(comment.id);
      if (commentTargetId == null) continue;
      if (await services.reports.hasReported(
        reporterUserId: currentUserId,
        targetType: ReportTargetType.comment,
        targetId: commentTargetId,
      )) {
        keys.add(_contentReportKey(ReportTargetType.comment, comment.id));
      }
    }

    return keys;
  }

  bool _hasReportedContent(
    ReportTargetType targetType,
    String targetId,
    Set<String> reportedTargetKeys,
  ) {
    final key = _contentReportKey(targetType, targetId);
    return reportedTargetKeys.contains(key) || _sessionReportedTargetKeys.contains(key);
  }

  void _markContentReported(ReportTargetType targetType, String targetId) {
    setState(() {
      _sessionReportedTargetKeys.add(_contentReportKey(targetType, targetId));
    });
  }

  String _messageFromError(Object error) {
    if (error is StateError) return error.message;
    return error.toString();
  }

  bool _isDuplicateReportError(Object error) {
    return _messageFromError(error).toLowerCase().contains('already reported');
  }

  Future<void> _shareRecipe(Recipe recipe, String authorName, BuildContext buttonContext) async {
    try {
      final box = buttonContext.findRenderObject() as RenderBox?;
      final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
      await shareRecipe(
        recipe,
        authorName: authorName,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _confirmDeleteRecipe(RecipeShareServices services, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await services.recipes.deleteRecipe(id);
      if (!mounted) return;
      _goBackOrFeed();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _removeImage(RecipeShareServices services, String id) async {
    try {
      await services.recipes.deleteRecipeImage(id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _toggleLike(Recipe recipe) async {
    final services = context.read<RecipeShareServices>();
    try {
      await services.recipes.toggleLikeRecipe(recipe.id);
      if (!mounted) return;
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _rateRecipe(Recipe recipe, double value) async {
    final services = context.read<RecipeShareServices>();
    try {
      await services.recipes.rateRecipe(recipe.id, value.toInt());
      if (!mounted) return;
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _addComment(Recipe recipe) async {
    final controller = TextEditingController();
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add comment'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Write your comment'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Post')),
        ],
      ),
    );
    if (shouldAdd != true || controller.text.trim().isEmpty) return;
    try {
      await context.read<RecipeShareServices>().comments.addComment(
            recipeId: recipe.id,
            content: controller.text.trim(),
          );
      if (!mounted) return;
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _submitReport({
    required ReportTargetType targetType,
    required String targetId,
    required String title,
    required Set<String> reportedTargetKeys,
  }) async {
    final parsedTargetId = int.tryParse(targetId);
    if (parsedTargetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to report this content.')),
      );
      return;
    }

    if (_hasReportedContent(targetType, targetId, reportedTargetKeys)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ReportService.duplicateReportMessage)),
      );
      return;
    }

    final request = await showReportContentDialog(context, title: title);
    if (request == null || !mounted) return;

    final currentUserId = context.read<AuthProvider>().user?.id;
    try {
      await context.read<RecipeShareServices>().reports.submitContentReport(
            targetType: targetType,
            targetId: parsedTargetId,
            reason: request.reason,
            description: request.description,
            reporterUserId: currentUserId,
          );
      if (!mounted) return;
      _markContentReported(targetType, targetId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted. Thank you.')),
      );
    } catch (e) {
      if (!mounted) return;
      if (_isDuplicateReportError(e)) {
        _markContentReported(targetType, targetId);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFromError(e))),
      );
    }
  }

  Future<void> _reportRecipe(
    Recipe recipe,
    Set<String> reportedTargetKeys,
  ) async {
    await _submitReport(
      targetType: ReportTargetType.recipe,
      targetId: recipe.id,
      title: 'Report recipe',
      reportedTargetKeys: reportedTargetKeys,
    );
  }

  Future<void> _reportComment(
    Comment comment,
    Set<String> reportedTargetKeys,
  ) async {
    await _submitReport(
      targetType: ReportTargetType.comment,
      targetId: comment.id,
      title: 'Report comment',
      reportedTargetKeys: reportedTargetKeys,
    );
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await context.read<RecipeShareServices>().comments.deleteComment(commentId);
      if (!mounted) return;
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _saveToCollection(Recipe recipe, List<Collection> collections) async {
    if (collections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a collection first from profile page')),
      );
      return;
    }
    final selected = await showModalBottomSheet<Collection>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: collections
              .map(
                (collection) => ListTile(
                  title: Text(collection.name),
                  subtitle: Text('${collection.recipeCount} recipes'),
                  onTap: () => Navigator.pop(ctx, collection),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected == null) return;
    try {
      await context.read<RecipeShareServices>().collections.addRecipeToCollection(
            selected.id,
            recipe.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to ${selected.name}')),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeId = widget.recipeId;

    return FutureBuilder<_DetailVm>(
      future: _future,
      builder: (context, snapshot) {
        final appBar = AppBar(
          title: const Text('Recipe'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _goBackOrFeed,
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
        final comments = vm.comments;
        final collections = vm.collections;
        final reportedTargetKeys = vm.reportedTargetKeys;
        final services = context.read<RecipeShareServices>();
        final isOwner =
            vm.currentUserId != null && vm.currentUserId == recipe.userId;
        final canReportRecipe = vm.currentUserId != null &&
            !isOwner &&
            !_hasReportedContent(
              ReportTargetType.recipe,
              recipe.id,
              reportedTargetKeys,
            );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(recipe.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: _goBackOrFeed,
            ),
            actions: [
              Builder(
                builder: (buttonContext) => IconButton(
                  tooltip: 'Share recipe',
                  onPressed: () => _shareRecipe(recipe, author.username, buttonContext),
                  icon: const Icon(Icons.ios_share_rounded),
                ),
              ),
              if (canReportRecipe)
                IconButton(
                  tooltip: 'Report recipe',
                  onPressed: () => _reportRecipe(recipe, reportedTargetKeys),
                  icon: const Icon(Icons.flag_outlined),
                ),
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        final changed = await context.push<bool>('/recipes/${recipe.id}/edit');
                        if (changed == true && mounted) {
                          _reload();
                        }
                        break;
                      case 'deleteImage':
                        await _removeImage(services, recipe.id);
                        break;
                      case 'deleteRecipe':
                        await _confirmDeleteRecipe(services, recipe.id);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit recipe')),
                    if (recipe.photoUrl.trim().isNotEmpty)
                      const PopupMenuItem(value: 'deleteImage', child: Text('Remove image')),
                    const PopupMenuItem(value: 'deleteRecipe', child: Text('Delete recipe')),
                  ],
                ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: recipe.photoUrl.trim().isEmpty
                      ? Container(
                          color: const Color(0xFFE8E8E6),
                          alignment: Alignment.center,
                          child: const Icon(Icons.restaurant, size: 56, color: AppColors.textSecondary),
                        )
                      : CachedNetworkImage(
                          imageUrl: recipe.photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: const Color(0xFFE8E8E6)),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFE8E8E6),
                            child: const Icon(Icons.restaurant, size: 56, color: AppColors.textSecondary),
                          ),
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
                        IconButton(
                          onPressed: () => _toggleLike(recipe),
                          icon: Icon(
                            recipe.isLikedByMe
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: recipe.isLikedByMe ? AppColors.error : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('${recipe.likesCount}', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(width: 14),
                        RatingStars(
                          rating: (recipe.myRating ?? recipe.averageRating).toDouble(),
                          size: 18,
                          interactive: true,
                          onRatingUpdate: (value) => _rateRecipe(recipe, value),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${recipe.averageRating.toStringAsFixed(1)} (${recipe.ratingCount})',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _saveToCollection(recipe, collections),
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: const Text('Save'),
                        ),
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
                    Row(
                      children: [
                        Text('Comments', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _addComment(recipe),
                          icon: const Icon(Icons.add_comment_outlined),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (comments.isEmpty)
                      const Text('No comments yet.')
                    else
                      ...comments.map(
                        (comment) => Card(
                          child: ListTile(
                            leading: UserAvatar(
                              imageUrl: comment.authorAvatarUrl ?? '',
                              nameForInitials: comment.authorUsername ?? 'U',
                              radius: 16,
                            ),
                            title: Text(comment.authorUsername ?? 'Unknown user'),
                            subtitle: Text(comment.content),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (vm.currentUserId != null &&
                                    vm.currentUserId != comment.userId &&
                                    !_hasReportedContent(
                                      ReportTargetType.comment,
                                      comment.id,
                                      reportedTargetKeys,
                                    ))
                                  IconButton(
                                    tooltip: 'Report comment',
                                    icon: const Icon(Icons.flag_outlined),
                                    onPressed: () =>
                                        _reportComment(comment, reportedTargetKeys),
                                  ),
                                if (vm.currentUserId == comment.userId)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    onPressed: () => _deleteComment(comment.id),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
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
                  ing.unit.isEmpty
                      ? '${ing.name} — ${ing.amount}'
                      : '${ing.name} — ${ing.amount} ${ing.unit}',
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
    required this.comments,
    required this.collections,
    required this.currentUserId,
    required this.reportedTargetKeys,
  });

  final Recipe recipe;
  final User author;
  final List<Comment> comments;
  final List<Collection> collections;
  final String? currentUserId;
  final Set<String> reportedTargetKeys;
}

