import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  // Write
  Future<bool> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to write secure data: $key', e, stackTrace);
      return false;
    }
  }

  // Read
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to read secure data: $key', e, stackTrace);
      return null;
    }
  }

  // Delete
  Future<bool> delete(String key) async {
    try {
      await _storage.delete(key: key);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete secure data: $key', e, stackTrace);
      return false;
    }
  }

  // Delete all
  Future<bool> deleteAll() async {
    try {
      await _storage.deleteAll();
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete all secure data', e, stackTrace);
      return false;
    }
  }

  // Check if key exists
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check secure key: $key', e, stackTrace);
      return false;
    }
  }

  // Read all
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to read all secure data', e, stackTrace);
      return {};
    }
  }
}
