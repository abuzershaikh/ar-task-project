import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/task_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/navigation/screens/main_nav_screen.dart';

// TODO: Set to false when backend auth is ready
const bool kBypassAuth = true;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
