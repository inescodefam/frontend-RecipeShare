import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';

/// Holds the signed-in [User] and talks to [AuthService] (mock now, HTTP later).
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth);

  final AuthService _auth;

  User? _user;
  bool _loading = false;
  String? _errorMessage;

  User? get user => _user;

  bool get isLoggedIn => _user != null;

  bool get isLoading => _loading;

  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _auth.getCurrentUser();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _auth.login(email: email.trim(), password: password);
    } catch (e) {
      _errorMessage = _messageFromError(e);
      _user = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _auth.register(
        username: username.trim(),
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      _errorMessage = _messageFromError(e);
      _user = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();
    await _auth.logout();
    _user = null;
    _errorMessage = null;
    _loading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _messageFromError(Object e) {
    if (e is StateError) return e.message;
    return e.toString();
  }
}
