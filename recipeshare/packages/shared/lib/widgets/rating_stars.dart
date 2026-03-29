import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';

/// Display-only or tappable star rating. Uses [flutter_rating_bar] for accessibility.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.size = 18,
    this.interactive = false,
    this.onRatingUpdate,
  }) : assert(!interactive || onRatingUpdate != null);

  final double rating;
  final int maxStars;
  final double size;
  final bool interactive;
  final void Function(double)? onRatingUpdate;

  @override
  Widget build(BuildContext context) {
    if (interactive) {
      return RatingBar.builder(
        initialRating: rating.clamp(0, maxStars.toDouble()),
        minRating: 1,
        allowHalfRating: false,
        itemCount: maxStars,
        itemSize: size,
        unratedColor: AppColors.textSecondary.withValues(alpha: 0.35),
        itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: AppColors.primary),
        onRatingUpdate: onRatingUpdate!,
      );
    }

    return RatingBarIndicator(
      rating: rating.clamp(0, maxStars.toDouble()),
      itemCount: maxStars,
      itemSize: size,
      unratedColor: AppColors.textSecondary.withValues(alpha: 0.35),
      itemBuilder: (context, index) => const Icon(Icons.star_rounded, color: AppColors.primary),
    );
  }
}
