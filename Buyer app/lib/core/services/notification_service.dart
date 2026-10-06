import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/di/injection.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/routes/app_router.dart';
import '../../features/support/data/buyer_chat_service.dart';

@pragma('vm:entry-point')
Future<void> buyerFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('🔔 [BUYER FCM BACKGROUND] Received: ${message.messageId} | ${message.data}');
  } catch (e) {
    debugPrint('⚠️ [BUYER FCM BACKGROUND] Init error: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String chatChannelId = 'buyer_support_chat';
  static const String chatChannelName = 'Support Desk & Chat Alerts';
  static const String chatChannelDesc =
      'Instant push notifications when dedicated support desk responds';

  static const AndroidNotificationChannel _chatChannel = AndroidNotificationChannel(
    chatChannelId,
    chatChannelName,
    description: chatChannelDesc,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static const AndroidNotificationChannel _campaignChannel = AndroidNotificationChannel(
    'buyer_campaign_notifications',
    'Campaign & Order Alerts',
    description: 'Updates on order progress, task reviews, and escrow balance',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  bool _initialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Global flag toggled by BuyerChatPage to prevent duplicate popups while actively in conversation
  static bool isChatPageOpen = false;

  final Set<String> _recentNotificationKeys = {};

  /// Initialize Firebase Cloud Messaging and Local Notification Engine for Buyer
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('🔔 [BUYER NOTIF] Initializing notification service...');

      // 1. Request OS level permissions
      await _requestPermissions();

      // 2. Initialize Local Notifications Plugin with high priority channel
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationPayload(response.payload);
        },
      );

      // 3. Create Android notification channels with max priority
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_chatChannel);
        await androidPlugin.createNotificationChannel(_campaignChannel);
      }

      // 4. Set FCM Foreground Presentation Options
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Subscribe to Buyer Broadcast Topics
      await _subscribeToBuyerTopics();

      // 6. Retrieve & Save FCM Token
      await _retrieveAndStoreToken();

      // 7. Setup FCM Stream Listeners
      _setupListeners();

      _initialized = true;
      debugPrint('✅ [BUYER NOTIF] Buyer Notification Engine initialized successfully');

      // Auto-sync token if user is already logged in
      syncUserToken();
    } catch (e) {
      debugPrint('⚠️ [BUYER NOTIF] Init warning: $e');
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
      ).timeout(const Duration(seconds: 4));
      debugPrint('🔔 [BUYER FCM PERMISSION] Status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        if (await Permission.notification.isDenied) {
          await Permission.notification.request().timeout(const Duration(seconds: 4));
        }
      }
    } catch (e) {
      debugPrint('⚠️ [BUYER FCM PERMISSION ERROR]: $e');
    }
  }

  /// Subscribe buyer to global topic
  Future<void> _subscribeToBuyerTopics() async {
    try {
      await _fcm.subscribeToTopic('buyers').timeout(const Duration(seconds: 3));
      debugPrint('🔔 [BUYER FCM TOPIC] Subscribed to topic: buyers');
    } catch (e) {
      debugPrint('⚠️ [BUYER FCM TOPIC] Subscription error: $e');
    }
  }

  /// Fetch FCM Token and register locally
  Future<void> _retrieveAndStoreToken() async {
    try {
      _fcmToken = await _fcm.getToken().timeout(const Duration(seconds: 4));
      if (_fcmToken != null) {
        debugPrint('🔑 [BUYER FCM TOKEN] Retrieved: ${_fcmToken!.substring(0, 15)}...');
      }

      // Listen to token refresh events
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔑 [BUYER FCM TOKEN REFRESHED]');
        syncUserToken();
      });
    } catch (e) {
      debugPrint('⚠️ [BUYER FCM TOKEN ERROR]: $e');
    }
  }

  /// Sync device FCM token to support-chat-engine & Task engine database
  Future<void> syncUserToken([String? explicitBuyerId]) async {
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      try {
        _fcmToken = await _fcm.getToken();
      } catch (_) {}
    }

    if (_fcmToken == null || _fcmToken!.isEmpty) return;

    // Resolve buyer identifier
    String buyerId = explicitBuyerId ?? '';
    if (buyerId.isEmpty) {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser?.uid != null && authUser!.uid.isNotEmpty) {
        buyerId = authUser.uid;
      } else {
        final storageId = getIt<LocalStorageService>().getUserId();
        if (storageId != null && storageId.isNotEmpty) {
          buyerId = storageId;
        } else if (authUser?.email != null) {
          buyerId = 'buyer_${authUser!.email!.split('@')[0]}';
        }
      }
    }

    if (buyerId.isEmpty) return;

    debugPrint('🔄 [BUYER FCM SYNC] Syncing token for buyer: $buyerId');

    // 1. Sync to support-chat-engine (Port 3005 on VPS)
    try {
      await BuyerChatService.instance.registerFcmToken(buyerId, _fcmToken!);
    } catch (e) {
      debugPrint('⚠️ [BUYER FCM SYNC] Chat engine sync error: $e');
    }

    // 2. Subscribe to personal buyer topic for guaranteed background delivery
    try {
      final cleanTopic = 'buyer_${buyerId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_')}';
      await _fcm.subscribeToTopic(cleanTopic);
      debugPrint('🔔 [BUYER FCM TOPIC] Subscribed to personal topic: $cleanTopic');
    } catch (e) {
      debugPrint('⚠️ [BUYER FCM SYNC] Personal topic error: $e');
    }

    // 3. Sync to Task Engine (users table metadata)
    try {
      final dioClient = getIt<DioClient>();
      await dioClient.put(
        ApiEndpoints.updateDeviceToken,
        data: {'deviceToken': _fcmToken},
      );
      debugPrint('✅ [BUYER FCM SYNC] Token synced to Task Engine for buyer: $buyerId');
    } catch (_) {
      // Non-critical if user is unauthenticated or endpoint busy
    }
  }

  /// Setup foreground & background message listeners
  void _setupListeners() {
    // 1. Foreground Message Handler (App is open and active)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 [BUYER FCM FOREGROUND] Title: ${message.notification?.title} | Body: ${message.notification?.body} | Data: ${message.data}');

      // If user is actively inside the chat screen, don't show annoying popup banner
      final isChatMsg = message.data['type'] == 'BUYER_SUPPORT_CHAT' ||
          message.notification?.title == 'Support Team' ||
          (message.data['title']?.toString() ?? '').contains('Support');

      if (isChatMsg && isChatPageOpen) {
        debugPrint('💬 [BUYER NOTIF] User is currently looking at chat page. Suppressing banner.');
        return;
      }

      _showLocalNotification(message);
    });

    // 2. Background Message Click Handler (User taps notification in system tray)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 [BUYER FCM OPENED APP] Clicked: ${message.data}');
      _handleNotificationPayload(jsonEncode(message.data));
    });

    // 3. Terminated State Click Handler (App launched from cold start via notification)
    _fcm.getInitialMessage().then((RemoteMessage? message) async {
      if (message != null) {
        debugPrint('🔔 [BUYER FCM COLD START] Cold start notification: ${message.data}');
        await Future.delayed(const Duration(milliseconds: 1200));
        _handleNotificationPayload(jsonEncode(message.data));
      }
    });

    // 4. Local Notification Click Handler
    _localNotifications.getNotificationAppLaunchDetails().then((details) async {
      if (details != null && details.didNotificationLaunchApp) {
        final payload = details.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint('🔔 [BUYER LOCAL NOTIF COLD START] Payload: $payload');
          await Future.delayed(const Duration(milliseconds: 1200));
          _handleNotificationPayload(payload);
        }
      }
    });
  }

  /// Display a heads-up floating notification banner with sound and vibration
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ??
        message.data['title'] ??
        'Support Team';
    final body = notification?.body ??
        message.data['body'] ??
        'You have a new message from support';

    final dedupeKey = '${message.messageId}_${title}_$body';
    if (_recentNotificationKeys.contains(dedupeKey)) return;
    _recentNotificationKeys.add(dedupeKey);
    if (_recentNotificationKeys.length > 50) {
      _recentNotificationKeys.remove(_recentNotificationKeys.first);
    }

    final notificationId = dedupeKey.hashCode.abs();

    final isChatMsg = message.data['type'] == 'BUYER_SUPPORT_CHAT' ||
        title == 'Support Team' ||
        (message.data['title']?.toString() ?? '').contains('Support');

    final androidDetails = AndroidNotificationDetails(
      isChatMsg ? chatChannelId : 'buyer_campaign_notifications',
      isChatMsg ? chatChannelName : 'Campaign & Order Alerts',
      channelDescription: isChatMsg ? chatChannelDesc : 'Campaign updates',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: isChatMsg ? 'VIP Support' : 'Review Gateway',
      ),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    final payloadMap = Map<String, dynamic>.from(message.data);
    payloadMap['title'] = title;
    payloadMap['body'] = body;

    await _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: jsonEncode(payloadMap),
    );
  }

  /// Handle Notification Click Actions (Navigates to chat, campaigns, or wallet)
  void _handleNotificationPayload(String? payloadStr) {
    if (payloadStr == null || payloadStr.isEmpty) return;
    try {
      final Map<String, dynamic> data = (payloadStr.startsWith('{'))
          ? Map<String, dynamic>.from(jsonDecode(payloadStr))
          : {'type': payloadStr};

      debugPrint('🎯 [BUYER NOTIF ACTION] Routing data: $data');

      final type = (data['type'] ?? '').toString().toUpperCase();
      final title = (data['title'] ?? '').toString();

      if (type == 'BUYER_SUPPORT_CHAT' ||
          type.contains('CHAT') ||
          type.contains('SUPPORT') ||
          title.contains('Support')) {
        AppRouter.openChat();
      } else if (type.contains('WALLET') || type.contains('ESCROW')) {
        AppRouter.openWallet();
      } else {
        AppRouter.openNotifications();
      }
    } catch (e) {
      debugPrint('⚠️ [BUYER NOTIF ACTION ERROR]: $e');
    }
  }
}
