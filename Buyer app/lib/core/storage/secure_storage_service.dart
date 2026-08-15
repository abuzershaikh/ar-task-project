import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  // Access Token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: AppConstants.accessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.accessToken);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: AppConstants.accessToken);
  }

  // Refresh Token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.refreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.refreshToken);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: AppConstants.refreshToken);
  }

  // User Data
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: AppConstants.userId, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: AppConstants.userId);
  }

  // User Name, Email & Photo URL
  Future<void> saveUserName(String name) async {
    await _storage.write(key: 'user_name', value: name);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: 'user_name');
  }

  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: AppConstants.userEmail, value: email);
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: AppConstants.userEmail);
  }

  Future<void> saveUserPhoto(String photoUrl) async {
    await _storage.write(key: 'user_photo', value: photoUrl);
  }

  Future<String?> getUserPhoto() async {
    return await _storage.read(key: 'user_photo');
  }

  // Clear All
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
