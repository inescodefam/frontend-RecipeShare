import '../models/models.dart';

/// Contract for sign-in and session. Real backend will call HTTP + secure storage.
abstract class AuthService {
  Future<User?> getCurrentUser();

  Future<User> login({required String email, required String password});

  Future<User> register({
    required String username,
    required String email,
    required String password,
  });

  Future<void> logout();
}
