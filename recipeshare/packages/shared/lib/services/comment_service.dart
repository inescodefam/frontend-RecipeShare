import '../models/models.dart';

class CommentPage {
  const CommentPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<Comment> items;
  final bool hasMore;
  final int? nextCursor;
}

abstract class CommentService {
  Future<CommentPage> getCommentsForRecipe(
    String recipeId, {
    int? cursor,
    int pageSize = 10,
  });

  Future<Comment> addComment({
    required String recipeId,
    required String content,
  });

  Future<Comment> updateComment({
    required String commentId,
    required String content,
  });

  Future<void> deleteComment(String commentId);
}
