import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service to manage the native Task Review Keyboard (InputMethodService).
/// Strictly restricted to Google Business Review and Play Store Review services.
class ReviewKeyboardService {
  ReviewKeyboardService._();
  static final ReviewKeyboardService instance = ReviewKeyboardService._();

  static const MethodChannel _channel =
      MethodChannel('com.taskearning.earning.money.app/review_keyboard');

  /// Determines whether the given platform/service is eligible for the Review Keyboard.
  /// Strictly ONLY 'google_business' and 'playstore'.
  bool isEligiblePlatform(String? platform) {
    if (platform == null) return false;
    final p = platform.trim().toLowerCase();
    return p == 'google_business' ||
        p == 'google_maps' ||
        p == 'playstore' ||
        p == 'google_play' ||
        p == 'play_store';
  }

  /// Sets the active review text and task ID in shared preferences and notifies native IME.
  /// Only sets if the platform is eligible (Google Business or Play Store).
  Future<bool> setActiveReview({
    required String taskId,
    required String reviewText,
    required String platform,
  }) async {
    final cleanPlatform = platform.trim().toLowerCase();
    if (!isEligiblePlatform(cleanPlatform)) {
      // Strictly ignore non-review services
      return false;
    }

    final cleanText = reviewText.trim();
    if (cleanText.isEmpty) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_task_id', taskId);
      await prefs.setString('active_review_text', cleanText);
      await prefs.setString('active_platform', cleanPlatform);

      // Notify native Android InputMethodService via method channel
      await _channel.invokeMethod('setActiveReview', {
        'taskId': taskId,
        'reviewText': cleanText,
        'platform': cleanPlatform,
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clears the active review text and task ID upon proof submission or task completion.
  Future<bool> clearActiveReview({String? taskId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (taskId != null) {
        final currentTaskId = prefs.getString('active_task_id');
        // Only clear if matching or if taskId not stored
        if (currentTaskId != null && currentTaskId != taskId) {
          return false;
        }
      }

      await prefs.remove('active_task_id');
      await prefs.remove('active_review_text');
      await prefs.remove('active_platform');

      // Notify native Android InputMethodService to wipe clean
      await _channel.invokeMethod('clearActiveReview');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Checks if the Task Review Keyboard is enabled in Android System Settings.
  Future<bool> isKeyboardEnabled() async {
    try {
      final bool? isEnabled = await _channel.invokeMethod<bool>('isKeyboardEnabled');
      return isEnabled ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Checks if the Task Review Keyboard is currently the active selected IME.
  Future<bool> isKeyboardSelected() async {
    try {
      final bool? isSelected = await _channel.invokeMethod<bool>('isKeyboardSelected');
      return isSelected ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android System Keyboard Settings (Manage Keyboards).
  Future<void> openKeyboardSettings() async {
    try {
      await _channel.invokeMethod('openKeyboardSettings');
    } catch (_) {}
  }

  /// Opens Android Input Method Picker dialog so the user can switch keyboards.
  Future<void> openInputMethodPicker() async {
    try {
      await _channel.invokeMethod('openInputMethodPicker');
    } catch (_) {}
  }

  /// Gets the currently loaded review text if any.
  Future<String?> getActiveReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('active_review_text');
    } catch (_) {
      return null;
    }
  }
}
