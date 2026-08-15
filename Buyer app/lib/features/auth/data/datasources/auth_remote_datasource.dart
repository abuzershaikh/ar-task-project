import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_data_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthDataModel> login(String email, String password);
  Future<AuthDataModel> loginWithGoogle(String idToken);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient client;

  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<AuthDataModel> login(String email, String password) async {
    try {
      final response = await client.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'role': 'buyer',
        },
      );
      if (response.data != null) {
        final dataMap = response.data['data'] ?? response.data;
        return AuthDataModel.fromJson(dataMap as Map<String, dynamic>);
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('[AUTH DATA LOG] /auth/login exception: $e');
      rethrow;
    }
  }

  @override
  Future<AuthDataModel> loginWithGoogle(String idToken) async {
    try {
      debugPrint('[AUTH DATA] POST /auth/google with Google token.');
      final response = await client.post(
        '/auth/google',
        data: {
          'idToken': idToken,
          'role': 'buyer',
        },
      );
      if (response.data != null) {
        final dataMap = response.data['data'] ?? response.data;
        return AuthDataModel.fromJson(dataMap as Map<String, dynamic>);
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('[AUTH DATA LOG] /auth/google exception: $e');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await client.post('/auth/logout');
    } catch (_) {}
  }
}
