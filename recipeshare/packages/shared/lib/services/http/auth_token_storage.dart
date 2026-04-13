import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract final class AuthTokenStorage {
  static const jwtKey = 'jwt_token';
  static const refreshKey = 'refresh_token';
  static const emailKey = 'user_email';

  static Future<void> writeAll(
    FlutterSecureStorage storage, {
    required String token,
    required String refreshToken,
    required String email,
  }) async {
    await storage.write(key: jwtKey, value: token);
    await storage.write(key: refreshKey, value: refreshToken);
    await storage.write(key: emailKey, value: email);
  }

  static Future<void> clear(FlutterSecureStorage storage) async {
    await storage.delete(key: jwtKey);
    await storage.delete(key: refreshKey);
    await storage.delete(key: emailKey);
  }
}
