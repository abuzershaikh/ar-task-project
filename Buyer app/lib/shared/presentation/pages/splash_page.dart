import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/di/injection.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRouter.mainNavigation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.campaign,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Marketing Pro',
                style: AppTextStyles.heading1.copyWith(
                  color: Colors.white,
                  fontSize: 36,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Campaign Management Platform',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              
              const SizedBox(height: 48),
              
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
