import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/storage/local_storage_service.dart';
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
    // 1. Brief splash delay for branding animation
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    try {
      final secureStorage = getIt<SecureStorageService>();
      final localStorage = getIt<LocalStorageService>();

      // 2. Direct check on current Firebase Auth session
      User? currentUser = FirebaseAuth.instance.currentUser;

      // If null, give FirebaseAuth up to 1.5 seconds to restore session from disk
      if (currentUser == null) {
        try {
          currentUser = await FirebaseAuth.instance
              .authStateChanges()
              .firstWhere((u) => u != null)
              .timeout(const Duration(milliseconds: 1500));
        } catch (_) {
          // Timeout reached, proceed to silent sign-in & local storage checks
        }
      }

      // If user is already active in Firebase
      if (currentUser != null) {
        try {
          final token = await currentUser.getIdToken();
          if (token != null) {
            await secureStorage.saveAccessToken(token);
            await localStorage.saveAccessToken(token);
          }
          await secureStorage.saveUserId(currentUser.uid);
          await localStorage.saveUserId(currentUser.uid);
          if (currentUser.email != null) {
            await secureStorage.saveUserEmail(currentUser.email!);
            await localStorage.saveUserEmail(currentUser.email!);
          }
          await localStorage.saveIsLoggedIn(true);
        } catch (_) {}

        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRouter.mainNavigation);
          return;
        }
      }

      // 3. Silent Google Sign-In attempt (re-authenticates without user interaction)
      try {
        final googleSignIn = GoogleSignIn(
          scopes: const ['email'],
          serverClientId: '311090572825-jve8b44v1m0p7smmudr6hnhe5ib5qcuc.apps.googleusercontent.com',
        );
        final account = await googleSignIn.signInSilently();
        if (account != null) {
          final auth = await account.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: auth.accessToken,
            idToken: auth.idToken,
          );
          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          final loggedInUser = userCredential.user;
          if (loggedInUser != null) {
            final token = await loggedInUser.getIdToken();
            if (token != null) {
              await secureStorage.saveAccessToken(token);
              await localStorage.saveAccessToken(token);
            }
            await secureStorage.saveUserId(loggedInUser.uid);
            await localStorage.saveUserId(loggedInUser.uid);
            await secureStorage.saveUserEmail(loggedInUser.email ?? account.email);
            await localStorage.saveUserEmail(loggedInUser.email ?? account.email);
            await localStorage.saveIsLoggedIn(true);

            if (mounted) {
              Navigator.pushReplacementNamed(context, AppRouter.mainNavigation);
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('[SPLASH] Silent sign-in error: $e');
      }

      // 4. Check persistent storage (LocalStorage / SecureStorage)
      final bool isLocallyLoggedIn = localStorage.isLoggedIn();
      final String? localUid = localStorage.getUserId();
      final String? secureUid = await secureStorage.getUserId();

      if ((isLocallyLoggedIn && localUid != null && localUid.isNotEmpty) ||
          (secureUid != null && secureUid.isNotEmpty)) {
        debugPrint('[SPLASH] Persistent user session validated ($localUid / $secureUid)');
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRouter.mainNavigation);
          return;
        }
      }
    } catch (e) {
      debugPrint('[SPLASH] Auth verification exception: $e');
    }

    // 5. Take user directly to main dashboard navigation
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.mainNavigation);
    }
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
