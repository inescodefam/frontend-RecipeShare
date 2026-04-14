// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'auth_session_storage.dart';

class WebCookieAuthSessionStorage implements AuthSessionStorage {
  static const int _maxAgeSeconds = 7 * 24 * 60 * 60;

  bool get _secure => html.window.location.protocol == 'https:';

  @override
  Future<void> clear() async {
    for (final name in const [
      AuthSessionKeys.jwt,
      AuthSessionKeys.refresh,
      AuthSessionKeys.email,
    ]) {
      _deleteCookie(name);
    }
  }

  @override
  Future<String?> read(String key) async => _getCookie(key);

  @override
  Future<void> write(String key, String value) async {
    _setCookie(key, value, maxAgeSeconds: _maxAgeSeconds, secure: _secure);
  }

  String? _getCookie(String name) {
    final raw = html.document.cookie ?? '';
    if (raw.isEmpty) return null;
    for (final part in raw.split(';')) {
      final idx = part.indexOf('=');
      if (idx <= 0) continue;
      final k = part.substring(0, idx).trim();
      if (k == name) {
        final v = part.substring(idx + 1).trim();
        return Uri.decodeComponent(v);
      }
    }
    return null;
  }

  void _setCookie(
    String name,
    String value, {
    required int maxAgeSeconds,
    required bool secure,
  }) {
    final enc = Uri.encodeComponent(value);
    final buf = StringBuffer(
      '$name=$enc; Path=/; Max-Age=$maxAgeSeconds; SameSite=Lax',
    );
    if (secure) buf.write('; Secure');
    html.document.cookie = buf.toString();
  }

  void _deleteCookie(String name) {
    final buf = StringBuffer('$name=; Path=/; Max-Age=0; SameSite=Lax');
    if (_secure) buf.write('; Secure');
    html.document.cookie = buf.toString();
  }
}

AuthSessionStorage createAuthSessionStorage() => WebCookieAuthSessionStorage();
