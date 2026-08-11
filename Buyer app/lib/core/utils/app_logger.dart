import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _tag = 'MarketingPro';

  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? ':$tag' : ''}] $message');
    }
  }

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? ':$tag' : ''}] [DEBUG] $message');
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? ':$tag' : ''}] [INFO] $message');
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? ':$tag' : ''}] [WARNING] $message');
    }
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? ':$tag' : ''}] [ERROR] $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  static void network(String method, String endpoint, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      print('[$_tag:NETWORK] $method $endpoint');
      if (data != null) {
        print('Data: $data');
      }
    }
  }

  static void bloc(String blocName, String event, {dynamic state}) {
    if (kDebugMode) {
      print('[$_tag:BLOC] $blocName -> $event');
      if (state != null) {
        print('State: $state');
      }
    }
  }
}
