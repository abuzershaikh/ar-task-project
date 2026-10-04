// Base Exception
class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

// Network Exceptions
class NetworkException extends AppException {
  NetworkException(String message) : super(message, 'NETWORK_ERROR');
}

class ServerException extends AppException {
  ServerException(String message) : super(message, 'SERVER_ERROR');
}

// Authentication Exceptions
class UnauthorizedException extends AppException {
  UnauthorizedException(String message) : super(message, 'UNAUTHORIZED');
}

class ForbiddenException extends AppException {
  ForbiddenException(String message) : super(message, 'FORBIDDEN');
}

// Request Exceptions
class BadRequestException extends AppException {
  BadRequestException(String message) : super(message, 'BAD_REQUEST');
}

class NotFoundException extends AppException {
  NotFoundException(String message) : super(message, 'NOT_FOUND');
}

class ValidationException extends AppException {
  final Map<String, dynamic>? errors;

  ValidationException(String message, [this.errors])
      : super(message, 'VALIDATION_ERROR');
}

// Cache Exception
class CacheException extends AppException {
  CacheException(String message) : super(message, 'CACHE_ERROR');
}

// Storage Exception
class StorageException extends AppException {
  StorageException(String message) : super(message, 'STORAGE_ERROR');
}
