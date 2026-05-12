import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared/shared.dart';

import '../api_config.dart';

String buildRecipeShareMessage(
  Recipe recipe, {
  String? authorName,
  String? link,
}) {
  final buffer = StringBuffer()..writeln('Check out "${recipe.title}" on RecipeShare!');

  if (authorName != null && authorName.isNotEmpty) {
    buffer.writeln('By $authorName');
  }

  final category = recipe.categoryLabel;
  if (category != null && category.isNotEmpty) {
    buffer.writeln('Category: $category');
  }

  buffer.writeln(
    '${recipe.prepTime} min prep, ${recipe.cookTime} min cook | '
    '${recipe.servings} servings | ${_difficultyLabel(recipe.difficulty)}',
  );

  final description = recipe.description.trim();
  if (description.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln(description);
  }

  if (link != null && link.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln(link);
  }

  return buffer.toString().trim();
}

Future<void> shareRecipe(
  Recipe recipe, {
  String? authorName,
  Rect? sharePositionOrigin,
}) {
  final link = resolveRecipeShareLink(recipe.id);
  final text = buildRecipeShareMessage(
    recipe,
    authorName: authorName,
    link: link,
  );

  return SharePlus.instance.share(
    ShareParams(
      text: text,
      subject: recipe.title,
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}

String _difficultyLabel(Difficulty difficulty) {
  switch (difficulty) {
    case Difficulty.easy:
      return 'Easy';
    case Difficulty.medium:
      return 'Medium';
    case Difficulty.hard:
      return 'Hard';
  }
}
