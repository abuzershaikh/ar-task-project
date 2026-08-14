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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

// Set to false to enable authentication screens
const bool kBypassAuth = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase core init error: $e');
  }
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
