import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../model/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitializing = false;

  AuthProvider(this._authService);

  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;

  Future<void> init() async {
    try {
      _isInitializing = true;
      final session = await _authService.currentSession;
      _isAuthenticated = session != null;
      if (_isAuthenticated) {
        _currentUser = await _authService.getCurrentUser();
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
    } finally {
      _isInitializing = false;
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _authService.signOut();
      _isAuthenticated = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Регистрация
  Future<({bool success, bool userExists, bool networkError, bool invalidEmail})> signUp(String email, String password) async {
    _isAuthenticated = false;
    notifyListeners();

    try {
      // Регистрация и автоматический вход
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
      );
      _isAuthenticated = true;
      notifyListeners();
      return (success: true, userExists: false, networkError: false, invalidEmail: false);
    } catch (e) {
      if (e.toString().contains('EMAIL_EXISTS')) {
        return (success: false, userExists: true, networkError: false, invalidEmail: false);
      } else if (e.toString().contains('INVALID_EMAIL')) {
        return (success: false, userExists: false, networkError: false, invalidEmail: true);
      }
      return (success: false, userExists: false, networkError: true, invalidEmail: false);
    } finally {
      notifyListeners();
    }
  }

  // Вход
  Future<({bool success, bool userNotFound})> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final user = await _authService.signIn(email: email, password: password);
      _currentUser = user;
      _isAuthenticated = true;
      return (success: true, userNotFound: false);
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
      if (e.toString().contains('INVALID_CREDENTIALS')) {
        return (success: false, userNotFound: true);
      }
      return (success: false, userNotFound: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Обновление профиля
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? imageUrl,
  }) async {
    if (_currentUser == null) return false;

    try {
      _currentUser = await _authService.updateProfile(
        userId: _currentUser!.id,
        fullName: fullName,
        phone: phone,
        imageUrl: imageUrl,
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Ошибка обновления профиля: ${e.toString()}');
      return false;
    }
  }
}
