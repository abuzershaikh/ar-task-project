import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/auth_data.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;

  AuthRepositoryImpl(this.remoteDataSource, this.secureStorage);

  @override
  Future<Either<Failure, AuthData>> login(String email, String password) async {
    try {
      final result = await remoteDataSource.login(email, password);
      
      // Save tokens
      await secureStorage.saveAccessToken(result.accessToken);
      await secureStorage.saveRefreshToken(result.refreshToken);
      await secureStorage.saveUserId(result.userId);
      
      return Right(result);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, AuthData>> loginWithGoogle(String idToken) async {
    try {
      debugPrint('[AUTH REPO] Sending Google token to backend.');
      final result = await remoteDataSource.loginWithGoogle(idToken);
      debugPrint('[AUTH REPO] Backend returned Google auth data for userId=${result.userId}');
      
      await secureStorage.saveAccessToken(result.accessToken);
      await secureStorage.saveRefreshToken(result.refreshToken);
      await secureStorage.saveUserId(result.userId);
      
      return Right(result);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('[AUTH REPO] Unexpected Google login error: $e');
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await secureStorage.clearAll();
      return const Right(null);
    } catch (e) {
      await secureStorage.clearAll();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, AuthData>> register(Map<String, dynamic> data) async {
    // To be implemented
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    // To be implemented
    throw UnimplementedError();
  }
}
