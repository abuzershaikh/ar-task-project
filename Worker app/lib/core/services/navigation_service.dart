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
    NavigatorState? nav = navigatorKey.currentState;
    int attempts = 0;
    while (nav == null && attempts < 12) {
      debugPrint('⏳ [NAV SERVICE] Waiting for navigator key (attempt $attempts)...');
      await Future.delayed(const Duration(milliseconds: 300));
      nav = navigatorKey.currentState;
      attempts++;
    }

    if (nav == null) {
      debugPrint('⚠️ [NAV SERVICE] Navigator still null after retry, giving up');
      return;
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

    final serviceCode = (initialData?['serviceCode'] ?? initialData?['category'] ?? '').toString().toLowerCase();
    final title = (initialData?['title'] ?? '').toString().toLowerCase();
    final body = (initialData?['body'] ?? initialData?['message'] ?? '').toString().toLowerCase();

    final isInstagram = serviceCode.contains('instagram') ||
        serviceCode.contains('insta') ||
        title.contains('instagram') ||
        body.contains('instagram');

    final isAppInstall = serviceCode.contains('install') ||
        serviceCode.contains('app') ||
        title.contains('install') ||
        title.contains('app install') ||
        body.contains('install');

    debugPrint('🚀 [NAV SERVICE] Opening task details: id=$id, orderId=$orderId, isInstagram=$isInstagram, isAppInstall=$isAppInstall');

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

    // 2. If orderId differs from id, try direct fetch by orderId
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

    // 3. Search available tasks — match by taskId OR orderId OR category
    try {
      final available = await ApiService.getAvailableTasks();
      var match = _findMatchingTask(available, id, orderId);
      if (match == null && (isInstagram || isAppInstall)) {
        match = _findCategoryMatchingTask(available, isInstagram: isInstagram, isAppInstall: isAppInstall);
      }
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

    // 4. Search assigned/accepted tasks — match by taskId OR orderId OR category
    try {
      final assigned = await ApiService.getMyTasks('assigned');
      var match = _findMatchingTask(assigned, id, orderId);
      if (match == null && (isInstagram || isAppInstall)) {
        match = _findCategoryMatchingTask(assigned, isInstagram: isInstagram, isAppInstall: isAppInstall);
      }
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

    // 5. Guaranteed Action: Build synthetic task from notification payload and open details
    debugPrint('✨ [NAV SERVICE] Opening TaskDetailPremiumScreen with task payload');
    final syntheticTask = _buildSyntheticTask(
      id: id ?? (orderId ?? 'task_${DateTime.now().millisecondsSinceEpoch}'),
      orderId: orderId ?? id,
      initialData: initialData,
      isInstagram: isInstagram,
      isAppInstall: isAppInstall,
    );

    nav.push(
      MaterialPageRoute(
        builder: (_) => TaskDetailPremiumScreen(task: syntheticTask),
      ),
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
            (orderId != null && orderId.isNotEmpty && (oId == orderId || tId == orderId))) {
          return Map<String, dynamic>.from(t);
        }
      }
    }
    return null;
  }

  /// Find a task matching category (Instagram or App Install)
  static Map<String, dynamic>? _findCategoryMatchingTask(
    List<dynamic> tasks, {
    required bool isInstagram,
    required bool isAppInstall,
  }) {
    for (final t in tasks) {
      if (t is Map) {
        final code = (t['serviceCode'] ?? t['taskType'] ?? t['type'] ?? '').toString().toLowerCase();
        final plat = (t['platform'] ?? '').toString().toLowerCase();
        final title = (t['title'] ?? '').toString().toLowerCase();
        final combined = '$code $plat $title';
        if (isInstagram && (combined.contains('instagram') || combined.contains('insta'))) {
          return Map<String, dynamic>.from(t);
        }
        if (isAppInstall && (combined.contains('install') || combined.contains('app') || combined.contains('play'))) {
          return Map<String, dynamic>.from(t);
        }
      }
    }
    return null;
  }

  /// Build a complete task Map from notification data
  static Map<String, dynamic> _buildSyntheticTask({
    required String id,
    String? orderId,
    Map<String, dynamic>? initialData,
    required bool isInstagram,
    required bool isAppInstall,
  }) {
    final rawData = initialData ?? {};
    final platform = isInstagram
        ? 'instagram'
        : (isAppInstall ? 'playstore' : (rawData['platform'] ?? 'playstore'));

    final defaultTitle = isInstagram
        ? 'Instagram Engagement Task (Follow & Like)'
        : (isAppInstall ? 'Install & Review App on Play Store ⭐⭐⭐⭐⭐' : 'New Reward Task');

    final defaultDesc = isInstagram
        ? 'Open Instagram profile, follow the account, like the latest post and submit screenshot proof.'
        : (isAppInstall
            ? 'Install app from Google Play Store, open it for 30 seconds, write a 5-star rating and upload screenshot proof.'
            : 'Complete the required action and upload verification proof to earn cash reward.');

    final rewardVal = double.tryParse(rawData['reward']?.toString() ?? '5.0') ?? 5.0;
    final icon = (rawData['icon'] ?? rawData['imageUrl'] ?? rawData['appIcon'])?.toString() ?? '';
    final appIcon = (rawData['appIcon'] ?? rawData['icon'] ?? rawData['imageUrl'])?.toString() ?? '';
    final appName = (rawData['appName'] ?? '').toString();

    return {
      'id': id,
      '_id': id,
      'taskId': id,
      'orderId': orderId ?? id,
      'order_id': orderId ?? id,
      'platform': platform,
      'title': rawData['title'] ?? defaultTitle,
      'description': rawData['body'] ?? rawData['message'] ?? defaultDesc,
      'serviceCode': rawData['serviceCode'] ?? (isInstagram ? 'INSTAGRAM_TASK' : (isAppInstall ? 'APP_INSTALL' : 'TASK')),
      'taskType': rawData['serviceCode'] ?? (isInstagram ? 'INSTAGRAM_TASK' : (isAppInstall ? 'APP_INSTALL' : 'TASK')),
      'appIcon': appIcon,
      'icon': icon,
      'imageUrl': icon,
      'appName': appName,
      'reward': rewardVal,
      'rewardAmount': rewardVal,
      'status': 'AVAILABLE',
      'requirements': {
        'appName': appName.isNotEmpty ? appName : (isAppInstall ? 'Featured Android App' : ''),
        'appIcon': appIcon,
        'icon': icon,
        'targetUrl': rawData['targetUrl'] ?? rawData['url'] ?? rawData['link'] ?? (isInstagram ? 'https://instagram.com' : 'https://play.google.com/store'),
        'topic': rawData['topic'] ?? rawData['comment'] ?? '',
      },
      'metadata': {
        'appName': appName,
        'appIcon': appIcon,
        'icon': icon,
      },
      ...rawData,
    };
  }

  /// Open Wallet Screen directly
  static void openWallet() {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.push(MaterialPageRoute(builder: (_) => const WalletScreen()));
    }
  }
}

