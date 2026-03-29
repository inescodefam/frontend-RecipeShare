import '../models/models.dart';

abstract class CommentService {
  Future<List<Comment>> getCommentsForRecipe(String recipeId);

  Future<Comment> addComment({
    required String recipeId,
    required String userId,
    required String content,
    String? parentCommentId,
  });

  Future<void> deleteComment(String commentId);
}
