import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message, 'SERVER_FAILURE');
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message, 'NETWORK_FAILURE');
}

class AuthFailure extends Failure {
  const AuthFailure(String message) : super(message, 'AUTH_FAILURE');
}

class ValidationFailure extends Failure {
  final Map<String, dynamic>? errors;

  const ValidationFailure(String message, [this.errors])
      : super(message, 'VALIDATION_FAILURE');

  @override
  List<Object?> get props => [message, code, errors];
}

class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message, 'CACHE_FAILURE');
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message, 'NOT_FOUND_FAILURE');
}
