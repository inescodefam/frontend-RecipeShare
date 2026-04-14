import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_session_storage.dart';

class IoAuthSessionStorage implements AuthSessionStorage {
  IoAuthSessionStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> clear() async {
    for (final k in const [
      AuthSessionKeys.jwt,
      AuthSessionKeys.refresh,
      AuthSessionKeys.email,
    ]) {
      await _storage.delete(key: k);
    }
  }

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

AuthSessionStorage createAuthSessionStorage() => IoAuthSessionStorage();
