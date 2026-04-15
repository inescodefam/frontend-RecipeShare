import '../models/models.dart';

abstract class AuthService {
  Future<User?> getCurrentUser();

  Future<User> login({required String email, required String password});

  Future<User> register({
    required String username,
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<User> updateProfile({
    required String username,
    required String bio,
  });

  Future<User> changeEmail({
    required String newEmail,
    required String currentPassword,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<User> uploadProfileImage({
    required List<int> imageBytes,
    String? filename,
  });

  Future<User> removeProfileImage();
}
