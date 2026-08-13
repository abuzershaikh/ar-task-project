import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
      _updateFCMToken();
    }
  }

  Future<void> _updateFCMToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await ApiService.updateDeviceToken(fcmToken);
      }
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);
      if (response['success'] == true) {
        final data = response['data'] ?? response;
        final token = data['token'] ?? data['accessToken'];
        if (token != null) {
          await ApiService.saveToken(token);
          _isAuthenticated = true;
          _user = data['user'];
          _isLoading = false;
          notifyListeners();
          _updateFCMToken();
          return true;
        }
      }
      _errorMessage = response['message'] ?? 'Login failed';
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
      if (response['success'] == true) {
        final data = response['data'] ?? response;
        final token = data['token'] ?? data['accessToken'];
        if (token != null) {
          await ApiService.saveToken(token);
          _isAuthenticated = true;
          _user = data['user'];
          _isLoading = false;
          notifyListeners();
          _updateFCMToken();
          return true;
        }
      }
      _errorMessage = response['message'] ?? 'Google login failed';
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
      if (response['success'] == true) {
        final data = response['data'] ?? response;
        final token = data['token'] ?? data['accessToken'];
        if (token != null) {
          await ApiService.saveToken(token);
          _isAuthenticated = true;
          _user = data['user'];
          _updateFCMToken();
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = response['message'] ?? 'Registration failed';
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchProfile() async {
    try {
      final profileResponse = await ApiService.getProfile();
      if (profileResponse['success'] == true && profileResponse.containsKey('worker')) {
        _user = profileResponse['worker'];
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
