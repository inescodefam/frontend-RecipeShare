import 'package:flutter/material.dart';

/// Food-inspired palette used across mobile and admin apps.
abstract final class AppColors {
  static const Color primary = Color(0xFFE8652A);
  static const Color secondary = Color(0xFF2D6A4F);
  static const Color background = Color(0xFFFAFAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD62839);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);

  /// Easy / medium / hard accents for [DifficultyBadge].
  static const Color difficultyEasy = Color(0xFF2D6A4F);
  static const Color difficultyMedium = Color(0xFFE8652A);
  static const Color difficultyHard = Color(0xFFD62839);
}
