import 'package:flutter/services.dart';

/// Service to query installed application status on Android via native MethodChannel.
class PackageTrackerService {
  static const MethodChannel _channel =
      MethodChannel('com.taskearning.earning.money.app/package_tracker');

  /// Check if a specific package is currently installed on the device.
  static Future<bool> isAppInstalled(String packageName) async {
    final cleanPkg = packageName.trim();
    if (cleanPkg.isEmpty) return false;
    try {
      final bool? result = await _channel.invokeMethod<bool>(
        'isAppInstalled',
        {'packageName': cleanPkg},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Batch check multiple packages.
  static Future<Map<String, bool>> checkInstalledPackages(
      List<String> packages) async {
    if (packages.isEmpty) return {};
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'checkInstalledPackages',
        {'packages': packages},
      );
      if (result == null) return {};
      return result.map((key, value) =>
          MapEntry(key.toString(), value == true || value == 1));
    } catch (_) {
      return {};
    }
  }

  /// Extracts package name from requirements, metadata, or Google Play URLs.
  /// Handles formats like:
  /// - https://play.google.com/store/apps/details?id=com.example.app
  /// - market://details?id=com.example.app
  /// - com.example.app
  static String? extractPackageName(dynamic rawInput) {
    if (rawInput == null) return null;

    if (rawInput is Map) {
      final fromMap = rawInput['packageName'] ??
          rawInput['package_name'] ??
          rawInput['packageId'] ??
          rawInput['package_id'] ??
          rawInput['targetPackage'] ??
          rawInput['target_package'];
      if (fromMap != null && fromMap.toString().trim().isNotEmpty) {
        return extractPackageName(fromMap.toString());
      }
      final link = rawInput['link'] ??
          rawInput['url'] ??
          rawInput['targetUrl'] ??
          rawInput['target_url'];
      if (link != null && link.toString().trim().isNotEmpty) {
        return extractPackageName(link.toString());
      }
    }

    final str = rawInput.toString().trim();
    if (str.isEmpty) return null;

    // Check for 'id=' query parameter in Play Store URLs
    final uri = Uri.tryParse(str);
    if (uri != null && uri.queryParameters.containsKey('id')) {
      final pkg = uri.queryParameters['id']?.trim();
      if (pkg != null && pkg.isNotEmpty) {
        return pkg.split('&').first;
      }
    }

    // Regex match for standard Android package names (e.g. com.example.app)
    final regExp = RegExp(r'[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+');
    final match = regExp.firstMatch(str);
    if (match != null) {
      return match.group(0);
    }

    return null;
  }

  /// Determines if a task is an App Install / Play Store task requiring retention tracking.
  static bool isAppInstallTask(Map<String, dynamic> task) {
    final type = (task['taskType'] ??
            task['task_type'] ??
            task['type'] ??
            task['serviceCode'] ??
            task['service_code'] ??
            '')
        .toString()
        .toUpperCase();

    final platform = (task['platform'] ??
            (task['requirements'] is Map
                ? task['requirements']['platform']
                : null) ??
            '')
        .toString()
        .toLowerCase();

    if (type.contains('INSTALL') ||
        type.contains('PLAYSTORE') ||
        platform.contains('playstore') ||
        platform.contains('google')) {
      return true;
    }

    final req = task['requirements'];
    if (req is Map &&
        (req.containsKey('packageName') ||
            req.containsKey('package_name') ||
            req.containsKey('minRetentionHours') ||
            req.containsKey('min_retention_hours'))) {
      return true;
    }

    return false;
  }
}
