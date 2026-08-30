import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 [FCM BACKGROUND] Received message: ${message.messageId} | ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String channelId = 'task_notifications';
  static const String channelName = 'Task Alerts & New Tasks';
  static const String channelDescription = 'Instant push notifications for newly available tasks and rewards';

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
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationPayload(response.payload);
        },
      );

      // 3. Create Android notification channel with max priority
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
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
      debugPrint('✅ [NOTIFICATION SERVICE] Worker Notification Engine initialized successfully');
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

  /// Subscribe worker to global and task topics
  Future<void> _subscribeToWorkerTopics() async {
    try {
      await _fcm.subscribeToTopic('workers');
      await _fcm.subscribeToTopic('all_workers');
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
        debugPrint('🔑 [FCM TOKEN] Retrieved: ${_fcmToken!.substring(0, 15)}...');
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
      debugPrint('🔔 [FCM FOREGROUND] Title: ${message.notification?.title} | Body: ${message.notification?.body}');
      _showLocalNotification(message);
    });

    // 2. Background Message Click Handler (User taps notification from system tray)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 [FCM OPENED APP] User clicked notification: ${message.data}');
      _handleNotificationPayload(jsonEncode(message.data));
    });

    // 3. Terminated State Click Handler (App launched from cold start via notification)
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🔔 [FCM COLD START] App opened from notification: ${message.data}');
        _handleNotificationPayload(jsonEncode(message.data));
      }
    });
  }

  /// Display a heads-up floating notification banner with sound and vibration
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? '🎉 New Task Available!';
    final body = notification?.body ?? message.data['body'] ?? 'A new reward task is available for you.';

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payload = jsonEncode(message.data);

    await _localNotifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Handle Notification Click Actions (Navigates to task feed / task details)
  void _handleNotificationPayload(String? payloadStr) {
    if (payloadStr == null || payloadStr.isEmpty) return;
    try {
      final Map<String, dynamic> data = jsonDecode(payloadStr);
      debugPrint('🎯 [NOTIFICATION ACTION] Payload: $data');
      // Navigation hooks can read 'taskId' or type 'NEW_TASK'
    } catch (_) {}
  }
}
