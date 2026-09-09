import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';

import 'navigation_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint(
    '🔔 [FCM BACKGROUND] Received message: ${message.messageId} | ${message.data}',
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'task_notifications';
  static const String channelName = 'Task Alerts & New Tasks';
  static const String channelDescription =
      'Instant push notifications for newly available tasks and rewards';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDescription,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  bool _initialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Cloud Messaging and Local Notification Engine
  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_initialized) return;

    try {
      // 1. Request OS level permissions
      await _requestPermissions();

      // 2. Initialize Local Notifications Plugin with high priority channel
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationPayload(response.payload);
        },
      );

      // 3. Create Android notification channel with max priority
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
      }

      // 4. Set FCM Foreground Presentation Options
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Subscribe to Worker Broadcast Topics
      await _subscribeToWorkerTopics();

      // 6. Retrieve & Save FCM Token
      await _retrieveAndStoreToken();

      // 7. Setup FCM Stream Listeners
      _setupListeners();

      _initialized = true;
      debugPrint(
        '✅ [NOTIFICATION SERVICE] Worker Notification Engine initialized successfully',
      );
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION SERVICE] Init warning: $e');
    }
  }

  /// Request Notification Permissions (Android 13+ support)
  Future<void> _requestPermissions() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('🔔 [FCM PERMISSION] Status: ${settings.authorizationStatus}');

      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('⚠️ [FCM PERMISSION ERROR]: $e');
    }
  }

  final Set<String> _recentNotificationKeys = {};

  /// Subscribe worker to global and task topics
  Future<void> _subscribeToWorkerTopics() async {
    try {
      await _fcm.subscribeToTopic('workers');
      debugPrint('🔔 [FCM TOPIC] Subscribed to topic: workers');
    } catch (e) {
      debugPrint('⚠️ [FCM TOPIC] Subscription error: $e');
    }
  }

  /// Fetch FCM Token and register locally
  Future<void> _retrieveAndStoreToken() async {
    try {
      _fcmToken = await _fcm.getToken();
      if (_fcmToken != null) {
        debugPrint(
          '🔑 [FCM TOKEN] Retrieved: ${_fcmToken!.substring(0, 15)}...',
        );
      }

      // Listen to token refresh events
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔑 [FCM TOKEN REFRESHED]');
        syncUserToken();
      });
    } catch (e) {
      debugPrint('⚠️ [FCM TOKEN ERROR]: $e');
    }
  }

  /// Sync device FCM token to Firestore and Backend database
  Future<void> syncUserToken([String? uid]) async {
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      _fcmToken = await _fcm.getToken();
    }

    if (_fcmToken == null || _fcmToken!.isEmpty) return;

    try {
      // 1. Update Backend API
      await ApiService.updateDeviceToken(_fcmToken!);

      // 2. Update Firestore user document if user is logged in
      if (uid != null && uid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': _fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'platform': 'android',
          'role': 'WORKER',
        }, SetOptions(merge: true));
        debugPrint('✅ [FCM SYNC] Token synced to Firestore for user: $uid');
      }
    } catch (e) {
      debugPrint('⚠️ [FCM SYNC ERROR]: $e');
    }
  }

  /// Setup foreground & background message listeners
  void _setupListeners() {
    // 1. Foreground Message Handler (App is open and active)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '🔔 [FCM FOREGROUND] Title: ${message.notification?.title} | Body: ${message.notification?.body}',
      );
      _showLocalNotification(message);
    });

    // 2. Background Message Click Handler (User taps notification from system tray)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '🔔 [FCM OPENED APP] User clicked notification: ${message.data}',
      );
      _handleNotificationPayload(jsonEncode(message.data));
    });

    // 3. Terminated State Click Handler (App launched from cold start via notification)
    _fcm.getInitialMessage().then((RemoteMessage? message) async {
      if (message != null) {
        debugPrint(
          '🔔 [FCM COLD START] App opened from notification: ${message.data}',
        );
        // Wait for widget tree and auth to initialize before navigating
        await Future.delayed(const Duration(milliseconds: 1500));
        _handleNotificationPayload(jsonEncode(message.data));
      }
    });

    // 4. Local Notification Terminated State Click Handler
    _localNotifications.getNotificationAppLaunchDetails().then((details) async {
      if (details != null && details.didNotificationLaunchApp) {
        final payload = details.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint(
            '🔔 [LOCAL NOTIF COLD START] App opened from local notification: $payload',
          );
          await Future.delayed(const Duration(milliseconds: 1500));
          _handleNotificationPayload(payload);
        }
      }
    });
  }

  /// Helper to download and cache remote icon for rich notifications
  Future<String?> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }
    } catch (e) {
      debugPrint('⚠️ [NOTIF ICON DOWNLOAD ERROR] $e');
    }
    return null;
  }

  /// Resolve the best high-res icon URL for the task
  String _resolveNotificationIconUrl(Map<String, dynamic> data) {
    // 1. Direct explicit appIcon / imageUrl / icon from backend
    final explicitIcon = (data['appIcon'] ?? data['icon'] ?? data['imageUrl'])
        ?.toString()
        .trim();

    // 2. Fallback: resolve using self-hosted VPS icon assets
    const assetBaseUrl = 'http://65.20.77.112:3000/api/v1/assets/icons';

    final serviceCode = (data['serviceCode'] ?? data['category'] ?? data['type'] ?? '')
        .toString()
        .toLowerCase();
    final title = (data['title'] ?? '').toString().toLowerCase();
    final body = (data['body'] ?? data['message'] ?? '').toString().toLowerCase();
    final targetUrl = (data['targetUrl'] ?? data['url'] ?? data['link'] ?? '').toString().toLowerCase();
    final combined = '$serviceCode $title $body $targetUrl';

    final isAppInstallOrPlayStore = combined.contains('install') ||
        combined.contains('app_install') ||
        combined.contains('playstore') ||
        combined.contains('play.google') ||
        combined.contains('google_play');

    // If explicitIcon is a real high-res app icon (e.g. from Play Store CDN), always use it!
    if (explicitIcon != null && explicitIcon.startsWith('http')) {
      // If it was wrongly tagged as the fallback instagram icon due to 'install' matching 'insta', fix it
      if (isAppInstallOrPlayStore && explicitIcon.contains('instagram')) {
        return '$assetBaseUrl/playstore';
      }
      return explicitIcon;
    }

    // 1. App Install / Google Play Store (Checked FIRST to avoid 'install' matching 'insta')
    if (isAppInstallOrPlayStore) {
      return '$assetBaseUrl/playstore';
    }

    // 2. YouTube
    if (combined.contains('youtube') || combined.contains('yt')) {
      return '$assetBaseUrl/youtube';
    }

    // 3. Instagram (Strict check: ensure word does not contain 'install')
    if (combined.contains('instagram') || (combined.contains('insta') && !combined.contains('install'))) {
      return '$assetBaseUrl/instagram';
    }

    // 4. Facebook
    if (combined.contains('facebook') || combined.contains('fb')) {
      return '$assetBaseUrl/facebook';
    }

    // 5. Telegram
    if (combined.contains('telegram')) {
      return '$assetBaseUrl/telegram';
    }

    // 6. Twitter / X
    if (combined.contains('twitter') || combined.contains(' x ') || combined.contains('x.com')) {
      return '$assetBaseUrl/twitter';
    }

    return '$assetBaseUrl/playstore';
  }

  /// Display a heads-up floating notification banner with sound and vibration
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title =
        notification?.title ??
        message.data['title'] ??
        '🎉 New Task Available!';
    final body =
        notification?.body ??
        message.data['body'] ??
        'A new reward task is available for you.';

    // Client-side Deduplication: Prevent duplicate popups within short timeframe
    final dedupeKey = '${message.messageId}_${message.data['orderId']}_$title';
    if (_recentNotificationKeys.contains(dedupeKey)) {
      debugPrint(
        '⚠️ [FCM DEDUPE] Suppressed duplicate local notification popup: $dedupeKey',
      );
      return;
    }
    _recentNotificationKeys.add(dedupeKey);
    if (_recentNotificationKeys.length > 50) {
      _recentNotificationKeys.remove(_recentNotificationKeys.first);
    }

    final notificationId = dedupeKey.hashCode.abs();

    // 🖼️ Download & attach rich icon (App icon, Instagram logo, YouTube logo, etc.)
    String iconUrl = _resolveNotificationIconUrl(message.data);
    final notifImageUrl = message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl;
    if (iconUrl.isEmpty && notifImageUrl != null && notifImageUrl.isNotEmpty) {
      iconUrl = notifImageUrl;
    }

    // If it is an App Install / Play Store task and we don't have a high-res app CDN icon yet, try quick scrape
    final combinedStr = '${message.data} $title $body'.toLowerCase();
    final isAppInstall = combinedStr.contains('install') ||
        combinedStr.contains('app_install') ||
        combinedStr.contains('play.google') ||
        combinedStr.contains('playstore');

    if (isAppInstall && (iconUrl.isEmpty || iconUrl.contains('/assets/icons/playstore') || iconUrl.contains('instagram'))) {
      final target = (message.data['targetUrl'] ?? message.data['url'] ?? message.data['link'] ?? '').toString();
      if (target.contains('play.google.com') || target.contains('id=') || target.contains('market://')) {
        try {
          final res = await http.post(
            Uri.parse('http://65.20.77.112:3000/api/v1/buyer/orders/playstore-app-info'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': target}),
          ).timeout(const Duration(milliseconds: 3000));
          if (res.statusCode == 200) {
            final parsed = jsonDecode(res.body);
            if (parsed['appIcon'] != null && parsed['appIcon'].toString().startsWith('http')) {
              iconUrl = parsed['appIcon'].toString().trim();
            }
          }
        } catch (_) {}
      }
    }

    String? localIconPath;
    if (iconUrl.isNotEmpty) {
      final safeExt = iconUrl.contains('.jpg') ? 'jpg' : 'png';
      localIconPath = await _downloadAndSaveFile(
        iconUrl,
        'notif_icon_${notificationId}.$safeExt',
      );
    }

    AndroidBitmap<Object>? largeIconBitmap;
    if (localIconPath != null && localIconPath.isNotEmpty) {
      largeIconBitmap = FilePathAndroidBitmap(localIconPath);
    }

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: largeIconBitmap,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: message.data['category'] ?? message.data['serviceCode'] ?? 'New Task',
      ),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    final payloadMap = Map<String, dynamic>.from(message.data);
    payloadMap['title'] = title;
    payloadMap['body'] = body;
    if (iconUrl.isNotEmpty) {
      payloadMap['icon'] ??= iconUrl;
      payloadMap['imageUrl'] ??= iconUrl;
      payloadMap['appIcon'] ??= iconUrl;
    }
    final payload = jsonEncode(payloadMap);

    await _localNotifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Handle Notification Click Actions (Navigates to task details or wallet)
  void _handleNotificationPayload(String? payloadStr) {
    if (payloadStr == null || payloadStr.isEmpty) return;
    try {
      final Map<String, dynamic> data = (payloadStr.startsWith('{'))
          ? Map<String, dynamic>.from(jsonDecode(payloadStr))
          : {'taskId': payloadStr};

      debugPrint('🎯 [NOTIFICATION ACTION] Clicked data: $data');

      final type = (data['type'] ?? '').toString().toUpperCase();
      final taskId =
          (data['taskId'] ?? data['id'] ?? data['orderId'] ?? data['entityId'])
              ?.toString();

      if (type.contains('EARNING') ||
          type.contains('WITHDRAWAL') ||
          type.contains('PAYOUT')) {
        NavigationService.openWallet();
      } else {
        NavigationService.openTaskDetails(taskId: taskId, initialData: data);
      }
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION ACTION ERROR]: $e');
    }
  }
}
