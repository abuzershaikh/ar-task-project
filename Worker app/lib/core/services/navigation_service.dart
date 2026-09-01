import 'package:flutter/material.dart';
import 'api_service.dart';
import '../../features/task_detail/screens/task_detail_premium_screen.dart';
import '../../features/navigation/screens/main_nav_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';

/// Global Navigation Service enabling deep-linking from push notifications,
/// local notifications, and notification history.
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Navigate directly to Task Detail Screen for a specific taskId
  static Future<void> openTaskDetails({
    String? taskId,
    Map<String, dynamic>? initialData,
  }) async {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      debugPrint('⚠️ [NAV SERVICE] Navigator state is null');
      return;
    }

    final id = (taskId != null && taskId.trim().isNotEmpty)
        ? taskId.trim()
        : (initialData?['taskId'] ?? initialData?['id'] ?? initialData?['orderId'])?.toString();

    debugPrint('🚀 [NAV SERVICE] Opening task details for ID: $id');

    // 1. If we have taskId, fetch full task from API
    if (id != null && id.isNotEmpty) {
      try {
        final task = await ApiService.getTaskDetails(id);
        if (task != null) {
          nav.push(
            MaterialPageRoute(
              builder: (_) => TaskDetailPremiumScreen(task: task),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('⚠️ [NAV SERVICE] Error fetching task details: $e');
      }

      // 2. Try fetching from available tasks
      try {
        final available = await ApiService.getAvailableTasks();
        for (final t in available) {
          if (t is Map) {
            final tId = (t['id'] ?? t['_id'] ?? t['taskId'] ?? '').toString();
            final oId = (t['orderId'] ?? t['order_id'] ?? '').toString();
            if (tId == id || oId == id) {
              nav.push(
                MaterialPageRoute(
                  builder: (_) => TaskDetailPremiumScreen(task: Map<String, dynamic>.from(t)),
                ),
              );
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ [NAV SERVICE] Error checking available tasks: $e');
      }
    }

    // 3. If initialData has requirements/title, synthesize task
    if (initialData != null && initialData.isNotEmpty) {
      final taskMap = Map<String, dynamic>.from(initialData);
      if (id != null && id.isNotEmpty) taskMap['id'] = id;
      nav.push(
        MaterialPageRoute(
          builder: (_) => TaskDetailPremiumScreen(task: taskMap),
        ),
      );
      return;
    }

    // 4. Fallback: Open Main Task Feed
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavScreen(initialIndex: 0)),
      (route) => false,
    );
  }

  /// Open Wallet Screen directly
  static void openWallet() {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.push(MaterialPageRoute(builder: (_) => const WalletScreen()));
    }
  }
}
