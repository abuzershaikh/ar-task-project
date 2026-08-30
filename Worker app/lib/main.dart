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
import 'firebase_options.dart';

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
        title: 'Task Reward',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: kBypassAuth
            ? const MainNavScreen()
            : Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (!auth.isInitialized) {
                    return const Scaffold(
                      backgroundColor: Color(0xFF0F172A),
                      body: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00875A),
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
              ),
      ),
    );
  }
}
