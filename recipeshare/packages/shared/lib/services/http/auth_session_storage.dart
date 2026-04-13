/// Pluggable persistence for JWT session data.
///
/// Web: browser cookies (client-set; not HttpOnly unless the server sets cookies).
/// IO (mobile/desktop): [FlutterSecureStorage] via [IoAuthSessionStorage].
///
/// Use [createAuthSessionStorage] from `auth_session_storage_factory.dart` (exported by package).
abstract class AuthSessionStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> clear();
}

abstract final class AuthSessionKeys {
  static const jwt = 'jwt_token';
  static const refresh = 'refresh_token';
  static const email = 'user_email';
}

extension AuthSessionStorageTokens on AuthSessionStorage {
  Future<void> writeSessionTokens({
    required String token,
    required String refreshToken,
    required String email,
  }) async {
    await write(AuthSessionKeys.jwt, token);
    await write(AuthSessionKeys.refresh, refreshToken);
    await write(AuthSessionKeys.email, email);
  }
}
