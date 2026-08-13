/// Centralized application constants.
/// All magic strings, durations, and sizing tokens live here.
class AppConstants {
  AppConstants._(); // prevent instantiation

  // ── App Info ──────────────────────────────────────────────────────────
  static const String appName = 'Task Reward';
  static const String appVersion = '1.0.0';

  // ── API ───────────────────────────────────────────────────────────────
  // 10.0.2.2 = Android Emulator ↔ host machine localhost
  // For physical device on same Wi-Fi, use machine's LAN IP.
  static const String apiBaseUrl = 'http://95.179.178.6:3000/api/v1';

  // ── Task Stages (backend-aligned) ────────────────────────────────────
  static const String stageAccepted = 'assigned';
  static const String stageSubmitted = 'submitted';
  static const String stageUnderReview = 'under-review';
  static const String stageApproved = 'approved';
  static const String stageRejected = 'rejected';

  static const List<String> myTaskStages = [
    stageAccepted,
    stageSubmitted,
    stageUnderReview,
    stageApproved,
    stageRejected,
  ];

  static const List<String> myTaskStageLabels = [
    'Accepted',
    'Submitted',
    'Under Review',
    'Approved',
    'Rejected',
  ];

  // ── Spacing ───────────────────────────────────────────────────────────
  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 20.0;
  static const double paddingXl = 24.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
}
