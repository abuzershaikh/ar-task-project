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
    final response = await client.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        'role': 'buyer',
      },
    );
    return AuthDataModel.fromJson(response.data['data']);
  }

  @override
  Future<AuthDataModel> loginWithGoogle(String idToken) async {
    debugPrint('[AUTH DATA] POST /auth/google with Google token.');
    final response = await client.post(
      '/auth/google',
      data: {
        'idToken': idToken,
        'role': 'buyer',
      },
    );
    debugPrint('[AUTH DATA] /auth/google response received.');
    return AuthDataModel.fromJson(response.data['data']);
  }

  @override
  Future<void> logout() async {
    await client.post('/auth/logout');
  }
}
