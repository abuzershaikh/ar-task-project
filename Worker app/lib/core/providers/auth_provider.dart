import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import '../services/api_service.dart';
import '../services/crashlytics_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;

  AuthProvider() {
    _checkInitialAuth();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null && !_isAuthenticated) {
        _isAuthenticated = true;
        final email = firebaseUser.email ?? 'worker@taskpost.com';
        final uid = firebaseUser.uid;
        final name = firebaseUser.displayName ?? 'Worker';
        final photoUrl = firebaseUser.photoURL;
        _user = {
          'uid': uid,
          'email': email,
          'name': name,
          'role': 'WORKER',
          'photoUrl': photoUrl,
        };
        await ApiService.saveUserData(email: email, uid: uid, name: name, photoUrl: photoUrl);
        notifyListeners();
      }
    });
  }

  Future<void> _checkInitialAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString('user_id');
      final savedEmail = prefs.getString('user_email');
      final savedName = prefs.getString('user_name');
      final savedPhoto = prefs.getString('user_photo_url');

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _isAuthenticated = true;
        final email = firebaseUser.email ?? savedEmail ?? 'worker@taskpost.com';
        final uid = firebaseUser.uid;
        final name = firebaseUser.displayName ?? savedName ?? 'Worker';
        final photoUrl = firebaseUser.photoURL ?? savedPhoto;
        _user = {
          'uid': uid,
          'email': email,
          'name': name,
          'role': 'WORKER',
          'photoUrl': photoUrl,
        };
        await ApiService.saveUserData(email: email, uid: uid, name: name, photoUrl: photoUrl);
        try {
          final idToken = await firebaseUser.getIdToken();
          if (idToken != null && idToken.isNotEmpty) {
            await ApiService.saveToken(idToken);
          }
        } catch (_) {}
        NotificationService.instance.syncUserToken(uid);
      } else if (savedUid != null && savedUid.isNotEmpty && savedEmail != null && savedEmail.isNotEmpty) {
        // Persistent session from local SharedPreferences
        _isAuthenticated = true;
        _user = {
          'uid': savedUid,
          'email': savedEmail,
          'name': savedName ?? 'Worker',
          'role': 'WORKER',
          'photoUrl': savedPhoto,
        };
        NotificationService.instance.syncUserToken(savedUid);
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setFirebaseUser(User firebaseUser, Map<String, dynamic> userData) async {
    _isAuthenticated = true;
    final email = firebaseUser.email ?? userData['email'] ?? 'worker@taskpost.com';
    final uid = firebaseUser.uid;
    final name = userData['name'] ?? firebaseUser.displayName ?? 'Worker';
    final photoUrl = firebaseUser.photoURL ?? userData['photoUrl'] ?? userData['photoURL'];
    
    _user = {
      ...userData,
      'photoUrl': photoUrl,
    };

    await ApiService.saveUserData(
      email: email,
      uid: uid,
      name: name,
      photoUrl: photoUrl,
    );
    try {
      final idToken = await firebaseUser.getIdToken();
      if (idToken != null && idToken.isNotEmpty) {
        await ApiService.saveToken(idToken);
      }
    } catch (_) {}
    await CrashlyticsService.setUser(
      id: uid,
      email: email,
      name: name,
      role: 'WORKER',
    );
    // Sync FCM Token for Worker Push Notifications
    await NotificationService.instance.syncUserToken(uid);
    notifyListeners();
  }

  Future<void> setDirectUser(Map<String, dynamic> userData) async {
    _isAuthenticated = true;
    _user = userData;
    final email = userData['email'] ?? 'worker@taskpost.com';
    final uid = userData['uid'] ?? 'worker_device_user';
    final name = userData['name'] ?? 'Worker';

    await ApiService.saveUserData(
      email: email,
      uid: uid,
      name: name,
    );
    await CrashlyticsService.setUser(
      id: uid,
      email: email,
      name: name,
      role: 'WORKER',
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
