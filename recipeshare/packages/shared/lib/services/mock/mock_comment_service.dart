import '../comment_service.dart';
import '../../models/models.dart';
import 'mock_data_service.dart';

class MockCommentService implements CommentService {
  MockCommentService(this._data);

  final MockDataService _data;

  @override
  Future<List<Comment>> getCommentsForRecipe(String recipeId) async {
    return _data.getCommentsByRecipeId(recipeId);
  }

  @override
  Future<Comment> addComment({
    required String recipeId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    final comment = Comment(
      id: 'cmt_${_data.newId()}',
      userId: userId,
      recipeId: recipeId,
      content: content,
      createdAt: DateTime.now().toUtc(),
      parentCommentId: parentCommentId,
    );
    await _data.addComment(comment);
    return comment;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _data.deleteCommentById(commentId);
  }
}
