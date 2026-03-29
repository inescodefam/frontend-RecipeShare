import '../user_service.dart';
import '../../models/models.dart';
import 'mock_data_service.dart';

class MockUserService implements UserService {
  MockUserService(this._data);

  final MockDataService _data;

  @override
  Future<User> getUserById(String id) async {
    return _data.getUserById(id);
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final users = await _data.getUsers();
    return users
        .where((u) => u.username.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<void> follow(String followerId, String followingId) async {
    await _data.addFollow(
      Follow(
        followerId: followerId,
        followingId: followingId,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<void> unfollow(String followerId, String followingId) async {
    await _data.removeFollow(followerId, followingId);
  }

  @override
  Future<bool> isFollowing(String followerId, String followingId) async {
    final list = await _data.getFollowsByFollowerId(followerId);
    return list.any((f) => f.followingId == followingId);
  }
}
