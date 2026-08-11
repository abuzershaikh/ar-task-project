import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/admin_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(String email, String password);
  Future<void> logout();
  Future<AdminUserModel> getCurrentUser();
  Future<String> refreshToken();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSourceImpl(this._dioClient);

  @override
  Future<LoginResponse> login(String email, String password) async {
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _dioClient.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ServerException(
          apiResponse.message ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw ServerException('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dioClient.post(ApiEndpoints.logout);
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('Logout failed: ${e.toString()}');
    }
  }

  @override
  Future<AdminUserModel> getCurrentUser() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.profile);

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => AdminUserModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ServerException(
          apiResponse.message ?? 'Failed to get user',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw ServerException('Failed to get user: ${e.toString()}');
    }
  }

  @override
  Future<String> refreshToken() async {
    try {
      final response = await _dioClient.post(ApiEndpoints.refreshToken);

      final apiResponse = ApiResponse.fromJson(response.data, null);

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data['accessToken'] as String;
      } else {
        throw AuthException(
          apiResponse.message ?? 'Token refresh failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw AuthException('Token refresh failed: ${e.toString()}');
    }
  }
}
