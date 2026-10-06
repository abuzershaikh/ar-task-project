import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/bloc/dashboard_bloc.dart';
import 'features/wallet/presentation/bloc/wallet_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';

import 'core/services/crashlytics_service.dart';
import 'core/services/currency_service.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safe Firebase Initialization
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    // Initialize Firebase Crashlytics & Global Error Reporting
    await CrashlyticsService.initialize();

    // Register Background FCM Handler
    FirebaseMessaging.onBackgroundMessage(buyerFirebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️ [FIREBASE] Core initialization warning: $e');
  }
  
  // Initialize dependencies
  try {
    await initializeDependencies();
  } catch (e) {
    debugPrint('⚠️ [DI] Dependencies initialization warning: $e');
  }

  // Initialize Global Pricing Currency Service (INR / USD switch engine)
  try {
    await CurrencyService.instance.init();
  } catch (e) {
    debugPrint('⚠️ [CURRENCY SERVICE] Init warning: $e');
  }

  // Initialize Buyer Notification Engine & Push Services
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('⚠️ [NOTIFICATION SERVICE] Init warning: $e');
  }
  
  // Set system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const ReviewGatewayApp());
}

class ReviewGatewayApp extends StatelessWidget {
  const ReviewGatewayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()..add(CheckAuthStatusEvent())),
        BlocProvider(create: (_) => getIt<DashboardBloc>()),
        BlocProvider(create: (_) => getIt<WalletBloc>()),
        BlocProvider(create: (_) => getIt<ProfileBloc>()..add(LoadProfileEvent())),
      ],
      child: MaterialApp(
        title: 'Review Gateway',
        debugShowCheckedModeBanner: false,
        navigatorKey: AppRouter.navigatorKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRouter.splash,
      ),
    );
  }
}

