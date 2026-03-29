import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Filter or metadata chip for categories and tags.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? AppColors.primary : AppColors.textPrimary,
            ),
      ),
      selected: selected,
      onSelected: (_) => onTap?.call(),
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.primary : const Color(0xFFE0E0E0),
      ),
    );
  }
}
