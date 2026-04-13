import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Backend base URL (no trailing slash). Override with `--dart-define=API_BASE_URL=...`.
///
/// Android emulator: default uses `10.0.2.2` to reach the host machine's localhost.
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kIsWeb) return 'http://localhost:5285';
  if (Platform.isAndroid) return 'http://10.0.2.2:5285';
  return 'http://localhost:5285';
}

/// Set `--dart-define=USE_MOCK_DATA=true` to use bundled JSON mock auth instead of the API.
bool get useMockServices {
  const v = String.fromEnvironment('USE_MOCK_DATA', defaultValue: 'false');
  return v == 'true' || v == '1';
}
