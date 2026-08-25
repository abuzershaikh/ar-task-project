import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/firestore_service.dart';
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
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _isAuthenticated = true;
        await ApiService.saveUserData(
          email: firebaseUser.email ?? 'worker@taskpost.com',
          uid: firebaseUser.uid,
          name: firebaseUser.displayName,
        );
        _user = await FirestoreService.getUserProfile(firebaseUser.uid) ?? {
          'uid': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'name': firebaseUser.displayName ?? '',
          'role': 'WORKER',
        };
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
    }
  }

  Future<void> setFirebaseUser(User firebaseUser, Map<String, dynamic> userData) async {
    _isAuthenticated = true;
    _user = userData;
    await ApiService.saveUserData(
      email: firebaseUser.email ?? userData['email'] ?? 'worker@taskpost.com',
      uid: firebaseUser.uid,
      name: userData['name'] ?? firebaseUser.displayName,
    );
    notifyListeners();
  }

  Future<void> setDirectUser(Map<String, dynamic> userData) async {
    _isAuthenticated = true;
    _user = userData;
    await ApiService.saveUserData(
      email: userData['email'] ?? 'worker@taskpost.com',
      uid: userData['uid'] ?? 'worker_device_user',
      name: userData['name'] ?? 'Worker',
    );
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      final p = await FirestoreService.getUserProfile(firebaseUser.uid);
      if (p != null) {
        _user = p;
        notifyListeners();
      }
    }
  }

  Future<void> logout() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      await FirestoreService.updateLogoutStatus(firebaseUser.uid);
    }
    await ApiService.clearToken();
    await FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
