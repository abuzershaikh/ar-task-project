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
      final token = await currentUser.getIdToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } else {
      final localStorage = getIt<LocalStorageService>();
      final token = await _secureStorage.getAccessToken() ?? localStorage.getAccessToken();
      final userId = await _secureStorage.getUserId() ?? localStorage.getUserId();
      final userEmail = await _secureStorage.getUserEmail() ?? localStorage.getUserEmail();

      if (userId != null && userId.isNotEmpty) {
        options.headers['x-user-id'] = userId;
      }
      if (userEmail != null && userEmail.isNotEmpty) {
        options.headers['x-user-email'] = userEmail;
      }
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    super.onError(err, handler);
  }
}
