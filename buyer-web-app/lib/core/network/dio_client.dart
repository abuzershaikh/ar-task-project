import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../services/crashlytics_service.dart';

class DioClient {
  final Dio _dio;

  DioClient(this._dio) {
    _dio.options = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  // GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST Request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT Request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH Request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE Request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error Handler
  Exception _handleError(DioException error) {
    final endpoint = error.requestOptions.path;
    final method = error.requestOptions.method;
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data?.toString();

    // Log to Crashlytics
    CrashlyticsService.recordApiError(
      endpoint: endpoint,
      method: method,
      statusCode: statusCode,
      error: error,
      stackTrace: error.stackTrace,
      responseSnippet: responseData,
    );

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout. Please check your internet connection.');
      
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);
      
      case DioExceptionType.cancel:
        return NetworkException('Request cancelled');
      
      default:
        return NetworkException('Network error occurred. No response received from server.');
    }
  }

  Exception _handleResponseError(Response? response) {
    if (response == null) {
      return ServerException('Unknown server error');
    }

    switch (response.statusCode) {
      case 400:
        return BadRequestException(
          response.data is Map ? (response.data['message'] ?? 'Bad request') : 'Bad request',
        );
      case 401:
        return UnauthorizedException('Unauthorized access');
      case 403:
        return ForbiddenException('Access forbidden');
      case 404:
        return NotFoundException('Resource not found');
      case 422:
        return ValidationException(
          response.data is Map ? (response.data['message'] ?? 'Validation failed') : 'Validation failed',
          response.data is Map ? response.data['errors'] : null,
        );
      case 500:
      case 502:
      case 503:
        return ServerException('Server error (${response.statusCode})');
      default:
        return ServerException('Unknown error occurred (${response.statusCode})');
    }
  }
}
