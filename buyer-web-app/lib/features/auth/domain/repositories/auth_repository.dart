import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_data.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthData>> login(String email, String password);
  Future<Either<Failure, AuthData>> loginWithGoogle(String idToken);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, AuthData>> register(Map<String, dynamic> data);
  Future<Either<Failure, void>> forgotPassword(String email);
}
