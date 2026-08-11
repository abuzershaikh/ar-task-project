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

  // Clear All
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
