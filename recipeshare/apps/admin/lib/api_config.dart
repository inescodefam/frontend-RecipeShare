/// Backend base URL (no trailing slash). Override with `--dart-define=API_BASE_URL=...`.
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  return 'http://localhost:5285';
}

/// Set `--dart-define=USE_MOCK_DATA=true` to use bundled JSON mock auth instead of the API.
bool get useMockServices {
  const v = String.fromEnvironment('USE_MOCK_DATA', defaultValue: 'false');
  return v == 'true' || v == '1';
}
