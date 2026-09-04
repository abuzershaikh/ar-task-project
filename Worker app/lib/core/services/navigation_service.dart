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
      debugPrint('⚠️ [NAV SERVICE] Navigator state is null, queuing for later');
      // Delay and retry once after widget tree is built
      await Future.delayed(const Duration(milliseconds: 800));
      final retryNav = navigatorKey.currentState;
      if (retryNav == null) {
        debugPrint('⚠️ [NAV SERVICE] Navigator still null after retry, giving up');
        return;
      }
      return _navigateToTask(retryNav, taskId, initialData);
    }

    return _navigateToTask(nav, taskId, initialData);
  }

  static Future<void> _navigateToTask(
    NavigatorState nav,
    String? taskId,
    Map<String, dynamic>? initialData,
  ) async {
    final id = (taskId != null && taskId.trim().isNotEmpty)
        ? taskId.trim()
        : (initialData?['taskId'] ?? initialData?['id'] ?? initialData?['orderId'])?.toString();
    final orderId = (initialData?['orderId'] ?? initialData?['order_id'])?.toString();

    debugPrint('🚀 [NAV SERVICE] Opening task details for taskId: $id, orderId: $orderId');

    // 1. Direct fetch by taskId from API
    if (id != null && id.isNotEmpty) {
      try {
        final task = await ApiService.getTaskDetails(id);
        if (task != null) {
          debugPrint('✅ [NAV SERVICE] Direct task fetch succeeded for: $id');
          nav.push(
            MaterialPageRoute(
              builder: (_) => TaskDetailPremiumScreen(task: task),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('⚠️ [NAV SERVICE] Direct fetch failed for $id: $e');
      }
    }

    // 2. Search available tasks — match by taskId OR orderId
    try {
      final available = await ApiService.getAvailableTasks();
      final match = _findMatchingTask(available, id, orderId);
      if (match != null) {
        debugPrint('✅ [NAV SERVICE] Found matching available task');
        nav.push(
          MaterialPageRoute(
            builder: (_) => TaskDetailPremiumScreen(task: match),
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('⚠️ [NAV SERVICE] Error checking available tasks: $e');
    }

    // 3. Search assigned/accepted tasks — match by taskId OR orderId
    try {
      final assigned = await ApiService.getMyTasks('assigned');
      final match = _findMatchingTask(assigned, id, orderId);
      if (match != null) {
        debugPrint('✅ [NAV SERVICE] Found matching assigned task');
        nav.push(
          MaterialPageRoute(
            builder: (_) => TaskDetailPremiumScreen(task: match),
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('⚠️ [NAV SERVICE] Error checking assigned tasks: $e');
    }

    // 4. If orderId differs from id, try direct fetch by orderId
    if (orderId != null && orderId.isNotEmpty && orderId != id) {
      try {
        final task = await ApiService.getTaskDetails(orderId);
        if (task != null) {
          debugPrint('✅ [NAV SERVICE] Direct fetch by orderId succeeded: $orderId');
          nav.push(
            MaterialPageRoute(
              builder: (_) => TaskDetailPremiumScreen(task: task),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('⚠️ [NAV SERVICE] Direct fetch by orderId failed: $e');
      }
    }

    // 5. Fallback: Open Main Task Feed so the user can find the task
    debugPrint('📋 [NAV SERVICE] No exact task found, opening task feed');
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavScreen(initialIndex: 0)),
      (route) => false,
    );
  }

  /// Find a task in a list that matches by taskId or orderId
  static Map<String, dynamic>? _findMatchingTask(
    List<dynamic> tasks,
    String? taskId,
    String? orderId,
  ) {
    for (final t in tasks) {
      if (t is Map) {
        final tId = (t['id'] ?? t['_id'] ?? t['taskId'] ?? '').toString();
        final oId = (t['orderId'] ?? t['order_id'] ?? '').toString();
        if ((taskId != null && taskId.isNotEmpty && (tId == taskId || oId == taskId)) ||
            (orderId != null && orderId.isNotEmpty && oId == orderId)) {
          return Map<String, dynamic>.from(t);
        }
      }
    }
    return null;
  }

  /// Open Wallet Screen directly
  static void openWallet() {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.push(MaterialPageRoute(builder: (_) => const WalletScreen()));
    }
  }
}
