import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import 'rating_stars.dart';
import 'user_avatar.dart';

/// Card used on Feed, Explore, and Profile grids.
enum RecipeCardVariant { standard, featured }

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    this.authorUsername,
    this.authorAvatarUrl,
    this.onTap,
    this.variant = RecipeCardVariant.standard,
    this.showCommentIcon = true,
  });

  final Recipe recipe;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final VoidCallback? onTap;
  final RecipeCardVariant variant;
  final bool showCommentIcon;

  double get _imageHeight => variant == RecipeCardVariant.featured ? 220 : 160;

  @override
  Widget build(BuildContext context) {
    final titleStyle = variant == RecipeCardVariant.featured
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.titleMedium;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _imageHeight,
              child: recipe.photoUrl.isEmpty
                  ? Container(
                      color: const Color(0xFFE8E8E6),
                      alignment: Alignment.center,
                      child: const Icon(Icons.restaurant, size: 48, color: AppColors.textSecondary),
                    )
                  : CachedNetworkImage(
                      imageUrl: recipe.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: const Color(0xFFE8E8E6)),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFE8E8E6),
                        alignment: Alignment.center,
                        child: const Icon(Icons.restaurant, size: 48, color: AppColors.textSecondary),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle?.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      UserAvatar(
                        imageUrl: authorAvatarUrl ?? recipe.authorAvatarUrl ?? '',
                        radius: 14,
                        nameForInitials:
                            authorUsername ?? recipe.authorUsername ?? '?',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authorUsername ?? recipe.authorUsername ?? 'User',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.likesCount}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      if (showCommentIcon) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.textSecondary),
                      ],
                      const Spacer(),
                      RatingStars(rating: recipe.averageRating, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
