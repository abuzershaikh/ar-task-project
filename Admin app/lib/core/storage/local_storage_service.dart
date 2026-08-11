import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // String operations
  Future<bool> setString(String key, String value) async {
    try {
      return await _prefs.setString(key, value);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save string: $key', e, stackTrace);
      return false;
    }
  }

  String? getString(String key) {
    try {
      return _prefs.getString(key);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get string: $key', e, stackTrace);
      return null;
    }
  }

  // Int operations
  Future<bool> setInt(String key, int value) async {
    try {
      return await _prefs.setInt(key, value);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save int: $key', e, stackTrace);
      return false;
    }
  }

  int? getInt(String key) {
    try {
      return _prefs.getInt(key);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get int: $key', e, stackTrace);
      return null;
    }
  }

  // Bool operations
  Future<bool> setBool(String key, bool value) async {
    try {
      return await _prefs.setBool(key, value);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save bool: $key', e, stackTrace);
      return false;
    }
  }

  bool? getBool(String key) {
    try {
      return _prefs.getBool(key);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get bool: $key', e, stackTrace);
      return null;
    }
  }

  // List operations
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      return await _prefs.setStringList(key, value);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save string list: $key', e, stackTrace);
      return false;
    }
  }

  List<String>? getStringList(String key) {
    try {
      return _prefs.getStringList(key);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get string list: $key', e, stackTrace);
      return null;
    }
  }

  // Remove
  Future<bool> remove(String key) async {
    try {
      return await _prefs.remove(key);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to remove key: $key', e, stackTrace);
      return false;
    }
  }

  // Clear all
  Future<bool> clear() async {
    try {
      return await _prefs.clear();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear storage', e, stackTrace);
      return false;
    }
  }

  // Check if key exists
  bool containsKey(String key) {
    try {
      return _prefs.containsKey(key);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check key: $key', e, stackTrace);
      return false;
    }
  }
}
