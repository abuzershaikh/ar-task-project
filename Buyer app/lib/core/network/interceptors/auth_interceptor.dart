import 'package:dio/dio.dart';
import '../../storage/secure_storage_service.dart';
import '../../constants/app_constants.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Get access token
    final token = await _secureStorage.getAccessToken();
    
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      final refreshed = await _refreshToken();
      
      if (refreshed) {
        // Retry the request
        try {
          final response = await _retry(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      }
    }
    
    super.onError(err, handler);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }
      
      // Call refresh token API
      final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      
      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'];
        final newRefreshToken = response.data['refreshToken'];
        
        await _secureStorage.saveAccessToken(newAccessToken);
        await _secureStorage.saveRefreshToken(newRefreshToken);
        
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _secureStorage.getAccessToken();
    
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );
    
    final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
    
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
