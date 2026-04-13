import 'auth_session_storage.dart';
import 'auth_session_storage_io.dart'
    if (dart.library.html) 'auth_session_storage_web.dart' as _impl;

AuthSessionStorage createAuthSessionStorage() => _impl.createAuthSessionStorage();
