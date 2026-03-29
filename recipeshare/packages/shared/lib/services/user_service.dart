import '../models/models.dart';

abstract class UserService {
  Future<User> getUserById(String id);

  Future<List<User>> searchUsers(String query);

  Future<void> follow(String followerId, String followingId);

  Future<void> unfollow(String followerId, String followingId);

  Future<bool> isFollowing(String followerId, String followingId);
}
