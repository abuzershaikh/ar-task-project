import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/task_provider.dart';
import 'core/providers/profile_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/navigation/screens/main_nav_screen.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/services/crashlytics_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/navigation_service.dart';
import 'firebase_options.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'core/services/api_service.dart';
import 'features/update/screens/app_update_screen.dart';

// Set to false to enable authentication screens
const bool kBypassAuth = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase core init error: $e');
  }

  // Initialize Firebase Crashlytics & Global Error Reporting
  await CrashlyticsService.initialize();

  // Initialize Firebase Messaging Background Handler & Push Engine
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase messaging init error: $e');
  }
  runApp(const TaskRewardApp());
}

class TaskRewardApp extends StatelessWidget {
  const TaskRewardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        navigatorKey: NavigationService.navigatorKey,
        title: 'Task Reward',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppBootstrapWrapper(),
      ),
    );
  }
}

class AppBootstrapWrapper extends StatefulWidget {
  const AppBootstrapWrapper({super.key});

  @override
  State<AppBootstrapWrapper> createState() => _AppBootstrapWrapperState();
}

class _AppBootstrapWrapperState extends State<AppBootstrapWrapper> {
  bool _isCheckingUpdate = true;
  bool _updateRequired = false;
  Map<String, dynamic>? _updateInfo;
  String _currentVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _checkForAppUpdate();
  }

  Future<void> _checkForAppUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _currentVersion = info.version.isNotEmpty ? info.version : '1.0.0';
    } catch (_) {
      _currentVersion = '1.0.0';
    }

    try {
      final res = await ApiService.checkAppUpdate(_currentVersion);
      if (res != null && res['updateRequired'] == true) {
        if (mounted) {
          setState(() {
            _updateRequired = true;
            _updateInfo = res;
            _isCheckingUpdate = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [UPDATE CHECK ERROR] $e');
    }

    if (mounted) {
      setState(() => _isCheckingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingUpdate) {
      return const Scaffold(
        backgroundColor: Color(0xFF04130D),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF22C55E),
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (_updateRequired && _updateInfo != null) {
      return AppUpdateScreen(
        currentVersion: _currentVersion,
        latestVersion: _updateInfo!['latestVersion']?.toString() ?? '1.0.1',
        downloadUrl: _updateInfo!['downloadUrl']?.toString() ??
            'https://raw.githubusercontent.com/abuzershaikh/ar-task-project/main/Worker_App_Release.apk',
        message: _updateInfo!['message']?.toString() ??
            'A new version of Task Reward Worker is available. Please update your app to continue.',
        releaseNotes: _updateInfo!['releaseNotes']?.toString() ??
            '• New task execution engine\n• Real-time notification deep linking\n• Improved stability and security',
      );
    }

    if (kBypassAuth) {
      return const MainNavScreen();
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isInitialized) {
          return const Scaffold(
            backgroundColor: Color(0xFF04130D),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF22C55E),
                strokeWidth: 3,
              ),
            ),
          );
        }
        if (auth.isAuthenticated) {
          return const MainNavScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
