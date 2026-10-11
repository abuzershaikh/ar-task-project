import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';

/// ReviewAutoApproveConfigService
/// Manages review auto-approval timeframe caching for Buyer App.
/// - Caches the admin-configured review auto-approve hours in SharedPreferences.
/// - Only fetches from server ONCE EVERY 7 DAYS to avoid server load.
/// - Returns 24.0 hours default fallback if server does not respond or on error.
class ReviewAutoApproveConfigService {
  static const String _prefKeyHours = 'review_auto_approve_hours_cached';
  static const String _prefKeyLastFetched = 'review_auto_approve_last_fetched_ms';
  static const double defaultHours = 24.0;
  static const int cacheDurationDays = 7;

  /// Retrieves the review auto-approve timeframe in hours.
  /// Uses cached value if fetched within the last 7 days.
  /// Falls back to 24.0 hours if network/server is unavailable.
  static Future<double> getAutoApproveHours({bool forceRefresh = false}) async {
    try {
      final prefs = getIt<SharedPreferences>();

      final cachedHours = prefs.getDouble(_prefKeyHours);
      final lastFetchedMs = prefs.getInt(_prefKeyLastFetched) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      const sevenDaysMs = cacheDurationDays * 24 * 60 * 60 * 1000;

      // 1. If cached within 7 days and not forcing refresh, return cached value immediately
      if (!forceRefresh && cachedHours != null && (nowMs - lastFetchedMs) < sevenDaysMs) {
        return cachedHours;
      }

      // 2. Cache expired (or never fetched) -> Fetch from server
      try {
        final dio = getIt<DioClient>();
        final response = await dio.get('/buyer/reviews/auto-approve-settings');

        if (response.statusCode == 200 && response.data != null) {
          final rawHours = response.data['autoApproveHours'];
          if (rawHours != null) {
            final parsedHours = double.tryParse(rawHours.toString()) ?? defaultHours;
            // Save to SharedPreferences with current timestamp
            await prefs.setDouble(_prefKeyHours, parsedHours);
            await prefs.setInt(_prefKeyLastFetched, nowMs);
            return parsedHours;
          }
        }
      } catch (networkError) {
        debugPrint('ReviewAutoApproveConfigService: Network fetch failed, using fallback: $networkError');
      }

      // 3. Fallback: return cached value if present, else 24.0 hours default
      return cachedHours ?? defaultHours;
    } catch (e) {
      debugPrint('ReviewAutoApproveConfigService error: $e');
      return defaultHours;
    }
  }

  /// Synchronous quick read from SharedPreferences cache (or 24.0 fallback)
  static double getCachedHoursSync() {
    try {
      final prefs = getIt<SharedPreferences>();
      return prefs.getDouble(_prefKeyHours) ?? defaultHours;
    } catch (_) {
      return defaultHours;
    }
  }
}
