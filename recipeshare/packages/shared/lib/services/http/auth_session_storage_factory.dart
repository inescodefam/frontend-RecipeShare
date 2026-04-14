import 'auth_session_storage.dart';
import 'auth_session_storage_io.dart'
    if (dart.library.html) 'auth_session_storage_web.dart' as impl;

/// Platform-specific storage: cookies on web, secure storage on IO.
AuthSessionStorage createAuthSessionStorage() => impl.createAuthSessionStorage();
