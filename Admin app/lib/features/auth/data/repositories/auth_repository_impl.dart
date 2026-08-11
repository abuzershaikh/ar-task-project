import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/admin_user_model.dart';
import 'dart:convert';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;
  final LocalStorageService _localStorage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService secureStorage,
    required LocalStorageService localStorage,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage,
        _localStorage = localStorage;

  @override
  Future<Either<Failure, AdminUser>> login(
    String email,
    String password,
  ) async {
    try {
      final loginResponse = await _remoteDataSource.login(email, password);

      // Save tokens securely
      await _secureStorage.write(
        AppConstants.tokenKey,
        loginResponse.accessToken,
      );
      await _secureStorage.write(
        AppConstants.refreshTokenKey,
        loginResponse.refreshToken,
      );

      // Save user data to local storage
      final userJson = jsonEncode(loginResponse.user.toJson());
      await _localStorage.setString(AppConstants.userKey, userJson);

      AppLogger.info('Login successful for user: ${loginResponse.user.email}');

      return Right(loginResponse.user.toEntity());
    } on AuthException catch (e) {
      AppLogger.error('Auth error during login', e);
      return Left(AuthFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      AppLogger.error('Network error during login', e);
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      AppLogger.error('Server error during login', e);
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during login', e, stackTrace);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Call remote logout
      await _remoteDataSource.logout();

      // Clear all local data
      await _secureStorage.deleteAll();
      await _localStorage.remove(AppConstants.userKey);

      AppLogger.info('Logout successful');

      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.error('Server error during logout', e);
      // Even if server call fails, clear local data
      await _secureStorage.deleteAll();
      await _localStorage.remove(AppConstants.userKey);
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      AppLogger.error('Network error during logout', e);
      // Clear local data even on network error
      await _secureStorage.deleteAll();
      await _localStorage.remove(AppConstants.userKey);
      return Left(NetworkFailure(e.message));
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during logout', e, stackTrace);
      // Clear local data
      await _secureStorage.deleteAll();
      await _localStorage.remove(AppConstants.userKey);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminUser>> getCurrentUser() async {
    try {
      // First try to get from local storage
      final userJson = _localStorage.getString(AppConstants.userKey);

      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final userModel = AdminUserModel.fromJson(userMap);
        return Right(userModel.toEntity());
      }

      // If not in local storage, fetch from server
      final userModel = await _remoteDataSource.getCurrentUser();

      // Save to local storage
      final userJsonNew = jsonEncode(userModel.toJson());
      await _localStorage.setString(AppConstants.userKey, userJsonNew);

      return Right(userModel.toEntity());
    } on AuthException catch (e) {
      AppLogger.error('Auth error getting current user', e);
      return Left(AuthFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      AppLogger.error('Network error getting current user', e);
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      AppLogger.error('Server error getting current user', e);
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error getting current user', e, stackTrace);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final token = await _secureStorage.read(AppConstants.tokenKey);
      return Right(token != null && token.isNotEmpty);
    } catch (e, stackTrace) {
      AppLogger.error('Error checking authentication', e, stackTrace);
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    try {
      final newToken = await _remoteDataSource.refreshToken();

      await _secureStorage.write(AppConstants.tokenKey, newToken);

      AppLogger.info('Token refreshed successfully');

      return Right(newToken);
    } on AuthException catch (e) {
      AppLogger.error('Auth error refreshing token', e);
      // Clear tokens on refresh failure
      await _secureStorage.delete(AppConstants.tokenKey);
      await _secureStorage.delete(AppConstants.refreshTokenKey);
      return Left(AuthFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      AppLogger.error('Network error refreshing token', e);
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      AppLogger.error('Server error refreshing token', e);
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error refreshing token', e, stackTrace);
      return Left(UnknownFailure(e.toString()));
    }
  }
}
