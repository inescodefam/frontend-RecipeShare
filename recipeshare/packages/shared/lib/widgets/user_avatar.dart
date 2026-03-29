import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular avatar for profile images; shows initials if URL is empty or load fails.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.nameForInitials,
  });

  final String imageUrl;
  final double radius;
  final String? nameForInitials;

  @override
  Widget build(BuildContext context) {
    final letter = _initial(nameForInitials);
    final size = radius * 2;
    final placeholder = Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: _initialsWidget(letter),
    );

    return ClipOval(
      child: imageUrl.isEmpty
          ? placeholder
          : CachedNetworkImage(
              imageUrl: imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            ),
    );
  }

  String _initial(String? name) {
    final t = name?.trim() ?? '';
    if (t.isEmpty) return '?';
    return t.substring(0, 1).toUpperCase();
  }

  Widget _initialsWidget(String letter) {
    return Text(
      letter,
      style: TextStyle(
        fontSize: radius * 0.9,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }
}
