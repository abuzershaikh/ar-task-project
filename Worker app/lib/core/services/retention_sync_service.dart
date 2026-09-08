import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'api_service.dart';
import 'package_tracker_service.dart';

/// RetentionSyncService:
/// Periodically checks all active App Install / Play Store retention tasks.
/// If an app is uninstalled before the required retention deadline,
/// sends the verification report to the backend so the task reward is revoked/deducted.
class RetentionSyncService {
  static Timer? _syncTimer;
  static bool _isSyncing = false;

  /// Start periodic retention monitoring (every 10 minutes when app is active)
  static void startMonitoring(BuildContext context) {
    _syncTimer?.cancel();
    // Initial sync shortly after launch
    Future.delayed(const Duration(seconds: 5), () {
      if (context.mounted) {
        syncRetentionStatus(context: context);
      } else {
        syncRetentionStatus();
      }
    });

    _syncTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      if (context.mounted) {
        syncRetentionStatus(context: context);
      } else {
        syncRetentionStatus();
      }
    });
  }

  static void stopMonitoring() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Syncs retention status of all active app install tasks for the logged in worker
  static Future<void> syncRetentionStatus({BuildContext? context}) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        _isSyncing = false;
        return;
      }

      final trackedTasks = await ApiService.getRetentionTrackedTasks();
      if (trackedTasks.isEmpty) {
        _isSyncing = false;
        return;
      }

      final List<Map<String, dynamic>> reports = [];

      for (final t in trackedTasks) {
        if (t is! Map) continue;
        final taskId = (t['id'] ?? t['taskId'] ?? '').toString();
        if (taskId.isEmpty) continue;

        final packageName = PackageTrackerService.extractPackageName(t['requirements']) ??
            PackageTrackerService.extractPackageName(t['metadata']) ??
            PackageTrackerService.extractPackageName(t['targetUrl'] ?? t['url']);

        if (packageName == null || packageName.isEmpty) continue;

        final isInstalled = await PackageTrackerService.isAppInstalled(packageName);

        reports.add({
          'taskId': taskId,
          'packageName': packageName,
          'isInstalled': isInstalled,
          'checkedAt': DateTime.now().toIso8601String(),
        });
      }

      if (reports.isNotEmpty) {
        final res = await ApiService.reportRetentionStatus(reports);
        debugPrint('📦 [RetentionSyncService] Reported ${reports.length} retention checks: $res');

        // If any penalty was applied or task was breached, refresh wallet and tasks
        if (res['deductionApplied'] == true || res['breachedCount'] != null) {
          if (context != null && context.mounted) {
            try {
              final taskProvider = Provider.of<TaskProvider>(context, listen: false);
              taskProvider.fetchWalletData();
              taskProvider.fetchMyTasks(taskProvider.selectedStage, forceRefresh: true);
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [RetentionSyncService] Error during retention check: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
