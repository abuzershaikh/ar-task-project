import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/admin_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AdminUser>> login(String email, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, AdminUser>> getCurrentUser();
  Future<Either<Failure, bool>> isAuthenticated();
  Future<Either<Failure, String>> refreshToken();
}
