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

    // Ignore web domains or Google Maps URLs (share.google, maps.google, etc.)
    if (str.contains('maps.google') ||
        str.contains('goo.gl/maps') ||
        str.contains('share.google') ||
        str.contains('maps.app.goo.gl') ||
        str.contains('youtube.com') ||
        str.contains('youtu.be') ||
        str.contains('instagram.com')) {
      return null;
    }

    // Check for 'id=' query parameter in Play Store URLs
    final uri = Uri.tryParse(str);
    if (uri != null && uri.queryParameters.containsKey('id')) {
      final pkg = uri.queryParameters['id']?.trim();
      if (pkg != null && pkg.isNotEmpty) {
        return pkg.split('&').first;
      }
    }

    // If string is a direct Google Play store URL or market:// URI
    if (str.contains('play.google.com') || str.startsWith('market://')) {
      final match = RegExp(r'id=([a-zA-Z0-9._]+)').firstMatch(str);
      if (match != null) return match.group(1);
    }

    // Regex match for standard Android package names (e.g. com.example.app)
    // Only if it doesn't look like a generic web URL
    if (!str.startsWith('http://') && !str.startsWith('https://')) {
      final regExp = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$');
      final match = regExp.firstMatch(str);
      if (match != null) {
        return match.group(0);
      }
    }

    return null;
  }

  /// Determines if a task is an App Install / Play Store task requiring retention tracking.
  static bool isAppInstallTask(Map<String, dynamic> task) {
    final typeUpper = (task['taskType'] ??
            task['task_type'] ??
            task['type'] ??
            task['serviceCode'] ??
            task['service_code'] ??
            '')
        .toString()
        .toUpperCase();

    final platformLower = (task['platform'] ??
            (task['requirements'] is Map
                ? task['requirements']['platform']
                : null) ??
            '')
        .toString()
        .toLowerCase();

    final titleLower = (task['title'] ??
            task['serviceTitle'] ??
            task['serviceName'] ??
            (task['requirements'] is Map
                ? (task['requirements']['serviceName'] ?? task['requirements']['title'])
                : null) ??
            '')
        .toString()
        .toLowerCase();

    final targetUrlLower = (task['targetUrl'] ??
            task['url'] ??
            (task['requirements'] is Map ? task['requirements']['targetUrl'] : null) ??
            '')
        .toString()
        .toLowerCase();

    // 0. STRICT EXCLUSION: Google Maps, Google Business, Review/Rating, YouTube, Instagram tasks are NEVER app install tasks!
    if (typeUpper.contains('MAP') ||
        typeUpper.contains('GMB') ||
        typeUpper.contains('GOOGLE_BUSINESS') ||
        platformLower.contains('maps') ||
        platformLower.contains('business') ||
        platformLower == 'google_maps' ||
        platformLower == 'google_business' ||
        titleLower.contains('google map') ||
        titleLower.contains('google business') ||
        titleLower.contains('rating & review') ||
        targetUrlLower.contains('maps.google') ||
        targetUrlLower.contains('goo.gl/maps') ||
        targetUrlLower.contains('share.google') ||
        targetUrlLower.contains('maps.app.goo.gl') ||
        targetUrlLower.contains('search.google.com/local')) {
      return false;
    }

    if (typeUpper.contains('YOUTUBE') ||
        typeUpper.contains('INSTAGRAM') ||
        typeUpper.contains('FACEBOOK') ||
        typeUpper.contains('TELEGRAM') ||
        platformLower == 'youtube' ||
        platformLower == 'instagram' ||
        platformLower == 'facebook') {
      return false;
    }

    // Exclude general review/rating/comment tasks unless explicitly marked as install
    if ((typeUpper.contains('REVIEW') ||
            typeUpper.contains('RATING') ||
            typeUpper.contains('COMMENT') ||
            typeUpper.contains('FOLLOW') ||
            typeUpper.contains('LIKE') ||
            typeUpper.contains('SUBSCRIBE')) &&
        !typeUpper.contains('INSTALL') &&
        !titleLower.contains('install & open') &&
        !titleLower.contains('app install')) {
      return false;
    }

    // 1. Genuine App Install Tasks
    if (typeUpper.contains('APP_INSTALL') ||
        typeUpper.contains('INSTALL_APP') ||
        typeUpper == 'INSTALL' ||
        typeUpper.startsWith('INSTALL_') ||
        typeUpper.endsWith('_INSTALL') ||
        titleLower.contains('install & open') ||
        titleLower.contains('app install') ||
        titleLower.contains('install app')) {
      return true;
    }

    final req = task['requirements'];
    if (req is Map &&
        (req.containsKey('minRetentionHours') ||
            req.containsKey('min_retention_hours'))) {
      return true;
    }

    return false;
  }
}
