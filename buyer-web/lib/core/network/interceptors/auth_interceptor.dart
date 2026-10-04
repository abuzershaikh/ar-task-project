import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../storage/secure_storage_service.dart';
import '../../storage/local_storage_service.dart';
import '../../di/injection.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      if (currentUser.email != null) {
        options.headers['x-user-email'] = currentUser.email;
      }
      options.headers['x-user-id'] = currentUser.uid;
      options.headers['x-user-role'] = 'BUYER';
      final token = await currentUser.getIdToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } else {
      final localStorage = getIt<LocalStorageService>();
      final token = await _secureStorage.getAccessToken() ?? localStorage.getAccessToken();
      final userId = await _secureStorage.getUserId() ?? localStorage.getUserId();
      final userEmail = await _secureStorage.getUserEmail() ?? localStorage.getUserEmail();

      if (token != null && token.isNotEmpty) {
        options.headers['x-user-role'] = 'BUYER';
        if (userId != null && userId.isNotEmpty) {
          options.headers['x-user-id'] = userId;
        }
        if (userEmail != null && userEmail.isNotEmpty) {
          options.headers['x-user-email'] = userEmail;
        }
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final localStorage = getIt<LocalStorageService>();
        await localStorage.saveIsLoggedIn(false);
        await localStorage.remove('access_token');
        await _secureStorage.deleteAccessToken();
      } catch (_) {}
    }
    super.onError(err, handler);
  }
}
