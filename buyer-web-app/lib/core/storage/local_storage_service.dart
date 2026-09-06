import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // User Email
  Future<void> saveUserEmail(String email) async {
    await _prefs.setString(AppConstants.userEmail, email);
  }

  String? getUserEmail() {
    return _prefs.getString(AppConstants.userEmail);
  }

  // Business Name
  Future<void> saveBusinessName(String name) async {
    await _prefs.setString(AppConstants.businessName, name);
  }

  String? getBusinessName() {
    return _prefs.getString(AppConstants.businessName);
  }

  // Generic String
  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  // Generic Int
  Future<void> saveInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // Generic Bool
  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // Remove
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  // Authentication & Session Persistence
  Future<void> saveIsLoggedIn(bool value) async {
    await _prefs.setBool('is_logged_in', value);
  }

  bool isLoggedIn() {
    return _prefs.getBool('is_logged_in') ?? false;
  }

  Future<void> saveUserId(String userId) async {
    await _prefs.setString(AppConstants.userId, userId);
  }

  String? getUserId() {
    return _prefs.getString(AppConstants.userId);
  }

  Future<void> saveAccessToken(String token) async {
    await _prefs.setString(AppConstants.accessToken, token);
  }

  String? getAccessToken() {
    return _prefs.getString(AppConstants.accessToken);
  }

  Future<void> saveUserName(String name) async {
    await _prefs.setString('user_name', name);
  }

  String? getUserName() {
    return _prefs.getString('user_name');
  }

  Future<void> saveUserPhoto(String photoUrl) async {
    await _prefs.setString('user_photo', photoUrl);
  }

  String? getUserPhoto() {
    return _prefs.getString('user_photo');
  }

  // Clear All
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
