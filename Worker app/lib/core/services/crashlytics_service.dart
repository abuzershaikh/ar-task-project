import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Initialize Crashlytics with global Flutter and async error handlers
  static Future<void> initialize() async {
    try {
      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError = (FlutterErrorDetails errorDetails) {
        _crashlytics.recordFlutterFatalError(errorDetails);
      };

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };

      await _crashlytics.setCrashlyticsCollectionEnabled(true);
      debugPrint('✅ [CRASHLYTICS] Worker App Crashlytics initialized successfully');
    } catch (e) {
      debugPrint('⚠️ [CRASHLYTICS] Worker App init error: $e');
    }
  }

  /// Associate user identity with crash reports
  static Future<void> setUser({
    required String id,
    String? email,
    String? name,
    String role = 'WORKER',
  }) async {
    try {
      await _crashlytics.setUserIdentifier(id);
      if (email != null && email.isNotEmpty) {
        await _crashlytics.setCustomKey('user_email', email);
      }
      if (name != null && name.isNotEmpty) {
        await _crashlytics.setCustomKey('user_name', name);
      }
      await _crashlytics.setCustomKey('user_role', role);
    } catch (_) {}
  }

  /// Log API timeouts, no-responses, and 5xx failures to Crashlytics
  static Future<void> recordApiError({
    required String endpoint,
    required String method,
    int? statusCode,
    required dynamic error,
    StackTrace? stackTrace,
    String? responseSnippet,
  }) async {
    try {
      await _crashlytics.setCustomKey('api_endpoint', endpoint);
      await _crashlytics.setCustomKey('api_method', method);
      if (statusCode != null) {
        await _crashlytics.setCustomKey('api_status_code', statusCode);
      }
      if (responseSnippet != null && responseSnippet.isNotEmpty) {
        final safeSnippet = responseSnippet.length > 500
            ? responseSnippet.substring(0, 500)
            : responseSnippet;
        await _crashlytics.setCustomKey('api_response_snippet', safeSnippet);
      }

      final reason = statusCode == null
          ? 'API_NO_RESPONSE_TIMEOUT: $method $endpoint'
          : 'API_ERROR_$statusCode: $method $endpoint';

      await _crashlytics.recordError(
        error,
        stackTrace ?? StackTrace.current,
        reason: reason,
        fatal: false,
      );
      debugPrint('🚨 [WORKER CRASHLYTICS API REPORT] Logged: $reason');
    } catch (_) {}
  }

  /// General non-fatal error logging
  static Future<void> recordNonFatal(
    dynamic exception, [
    StackTrace? stackTrace,
    String? reason,
  ]) async {
    try {
      await _crashlytics.recordError(
        exception,
        stackTrace ?? StackTrace.current,
        reason: reason,
        fatal: false,
      );
    } catch (_) {}
  }

  /// Breadcrumb log
  static void log(String message) {
    try {
      _crashlytics.log(message);
    } catch (_) {}
  }
}
