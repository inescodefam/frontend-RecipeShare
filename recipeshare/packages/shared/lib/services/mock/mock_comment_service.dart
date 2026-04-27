import '../comment_service.dart';
import '../../models/models.dart';
import 'mock_data_service.dart';

class MockCommentService implements CommentService {
  MockCommentService(this._data);

  final MockDataService _data;

  @override
  Future<CommentPage> getCommentsForRecipe(
    String recipeId, {
    int? cursor,
    int pageSize = 10,
  }) async {
    final items = await _data.getCommentsByRecipeId(recipeId);
    return CommentPage(items: items, hasMore: false);
  }

  @override
  Future<Comment> addComment({
    required String recipeId,
    required String content,
  }) async {
    final comment = Comment(
      id: 'cmt_${_data.newId()}',
      userId: 'mock-user',
      recipeId: recipeId,
      content: content,
      createdAt: DateTime.now().toUtc(),
    );
    await _data.addComment(comment);
    return comment;
  }

  @override
  Future<Comment> updateComment({
    required String commentId,
    required String content,
  }) async {
    final existing = await _data.getCommentById(commentId);
    if (existing == null) throw StateError('Comment not found');
    final updated = Comment(
      id: existing.id,
      userId: existing.userId,
      recipeId: existing.recipeId,
      content: content,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toUtc(),
      authorUsername: existing.authorUsername,
      authorAvatarUrl: existing.authorAvatarUrl,
    );
    await _data.deleteCommentById(commentId);
    await _data.addComment(updated);
    return updated;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _data.deleteCommentById(commentId);
  }
}
