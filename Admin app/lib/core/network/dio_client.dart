import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import '../utils/logger.dart';
import '../errors/exceptions.dart';

class DioClient {
  late final Dio _dio;
  final SecureStorageService _secureStorage;

  DioClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConstants.baseUrl}${AppConstants.apiPrefix}',
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Request Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _secureStorage.read(AppConstants.tokenKey);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            AppLogger.debug(
              'Request: ${options.method} ${options.path}',
            );
            return handler.next(options);
          } catch (e, stackTrace) {
            AppLogger.error('Request interceptor error', e, stackTrace);
            return handler.next(options);
          }
        },
        onResponse: (response, handler) {
          AppLogger.debug(
            'Response: ${response.statusCode} ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (error, handler) async {
          AppLogger.error(
            'API Error: ${error.requestOptions.path}',
            error,
          );

          if (error.response?.statusCode == 401) {
            // Token expired, clear auth data
            await _secureStorage.delete(AppConstants.tokenKey);
            await _secureStorage.delete(AppConstants.refreshTokenKey);
          }

          return handler.next(error);
        },
      ),
    );

    // Logging Interceptor (only in debug mode)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (object) => AppLogger.debug(object.toString()),
      ),
    );
  }

  Dio get dio => _dio;

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in GET request', e, stackTrace);
      throw ServerException('An unexpected error occurred');
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in POST request', e, stackTrace);
      throw ServerException('An unexpected error occurred');
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in PUT request', e, stackTrace);
      throw ServerException('An unexpected error occurred');
    }
  }

  // PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in PATCH request', e, stackTrace);
      throw ServerException('An unexpected error occurred');
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in DELETE request', e, stackTrace);
      throw ServerException('An unexpected error occurred');
    }
  }

  // Handle Dio errors
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout. Please try again.');

      case DioExceptionType.connectionError:
        return NetworkException(
          'No internet connection. Please check your network.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        String? message;
        
        final responseData = error.response?.data;
        if (responseData is Map) {
          if (responseData['error'] is Map) {
            message = responseData['error']['message'];
          } else if (responseData['message'] != null) {
            message = responseData['message'];
          }
        }
        message ??= 'Server error occurred';

        if (statusCode == 401) {
          return AuthException(message, statusCode: statusCode);
        } else if (statusCode == 403) {
          return AuthException(message, statusCode: statusCode);
        } else if (statusCode == 404) {
          return ServerException('Resource not found.', statusCode: statusCode);
        } else if (statusCode == 422) {
          return ServerException('Validation error: $message', statusCode: statusCode);
        } else if (statusCode! >= 500) {
          return ServerException('Server error. Please try again later.', statusCode: statusCode);
        }
        return ServerException(message, statusCode: statusCode);

      case DioExceptionType.cancel:
        return ServerException('Request cancelled.');

      case DioExceptionType.badCertificate:
        return NetworkException('SSL certificate error.');

      case DioExceptionType.unknown:
      default:
        return ServerException(
          error.message ?? 'An unexpected error occurred',
        );
    }
  }
}
