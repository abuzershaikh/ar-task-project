import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;

  AuthProvider() {
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    final token = await ApiService.getToken();
    if (token != null && token.isNotEmpty) {
      _isAuthenticated = true;
      notifyListeners();
      fetchProfile();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);
      if (response['token'] != null || response['accessToken'] != null) {
        final token = response['token'] ?? response['accessToken'];
        await ApiService.saveToken(token);
        _isAuthenticated = true;
        _user = response['user'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Login failed';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> loginWithGoogle(String idToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.googleLogin(idToken);
      final data = response['data'];
      if (data != null && (data['token'] != null || data['accessToken'] != null)) {
        final token = data['token'] ?? data['accessToken'];
        await ApiService.saveToken(token);
        _isAuthenticated = true;
        _user = data['user'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Google login failed';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.register(email, password, name);
      if (response['token'] != null || response['accessToken'] != null || response['id'] != null) {
        // Auto login if token returned
        if (response['token'] != null) {
          await ApiService.saveToken(response['token']);
          _isAuthenticated = true;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Registration failed';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchProfile() async {
    try {
      final dashboard = await ApiService.getDashboard();
      if (dashboard.containsKey('worker')) {
        _user = dashboard['worker'];
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
