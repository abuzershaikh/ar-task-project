import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/crashlytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/apk_downloader.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/presentation/pages/main_navigation_page.dart';
import '../bloc/auth_bloc.dart';
import '../../screens/user_profile_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final localStorage = getIt<LocalStorageService>();
    final secureStorage = getIt<SecureStorageService>();
    final isLoggedIn = localStorage.isLoggedIn();
    final uid = localStorage.getUserId() ?? await secureStorage.getUserId();
    if (isLoggedIn && uid != null && uid.isNotEmpty) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.mainNavigation);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('[GOOGLE SIGN IN] Starting Google Sign-In process...');
      User? firebaseUser;
      String? accountEmail;
      String? accountName;
      String? accountPhoto;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
        firebaseUser = userCredential.user;
      } else {
        final googleSignIn = GoogleSignIn(
          scopes: const ['email'],
          serverClientId: '311090572825-jve8b44v1m0p7smmudr6hnhe5ib5qcuc.apps.googleusercontent.com',
        );

        final account = await googleSignIn.signIn();
        debugPrint('[GOOGLE SIGN IN] Account result: $account');

        if (account != null) {
          accountEmail = account.email;
          accountName = account.displayName;
          accountPhoto = account.photoUrl;

          final auth = await account.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: auth.accessToken,
            idToken: auth.idToken,
          );

          final UserCredential userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          firebaseUser = userCredential.user;
        }
      }

      if (firebaseUser != null) {
        final token = await firebaseUser.getIdToken();
        final storage = getIt<SecureStorageService>();
        final localStorage = getIt<LocalStorageService>();

        if (token != null) {
          await storage.saveAccessToken(token);
          await localStorage.saveAccessToken(token);
        }
        final email = firebaseUser.email ?? accountEmail ?? '';
        final name = firebaseUser.displayName ?? accountName ?? '';
        final photo = firebaseUser.photoURL ?? accountPhoto ?? '';

        await storage.saveUserEmail(email);
        await localStorage.saveUserEmail(email);
        await storage.saveUserName(name);
        await localStorage.saveUserName(name);
        await storage.saveUserId(firebaseUser.uid);
        await localStorage.saveUserId(firebaseUser.uid);
        if (photo.isNotEmpty) {
          await storage.saveUserPhoto(photo);
          await localStorage.saveUserPhoto(photo);
        }
        await localStorage.saveIsLoggedIn(true);

        if (!kIsWeb) {
          await CrashlyticsService.setUser(
            id: firebaseUser.uid,
            email: email,
            name: name,
            role: 'BUYER',
          );
        }

        final userData = await FirestoreService.syncUserProfile(
          uid: firebaseUser.uid,
          email: email,
          displayName: name,
          role: 'BUYER',
        );

        if (context.mounted) {
          try {
            context.read<AuthBloc>().add(CheckAuthStatusEvent());
          } catch (_) {}

          final String phone = userData['phone'] ?? '';
          if (phone.isEmpty) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => UserProfileFormScreen(
                  uid: firebaseUser!.uid,
                  initialName: userData['name'] ?? name,
                  email: email,
                  nextScreen: const MainNavigationPage(),
                ),
              ),
            );
          } else {
            Navigator.of(context).pushReplacementNamed(AppRouter.mainNavigation);
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[GOOGLE SIGN IN ERROR] $e');
      if (!kIsWeb) {
        await CrashlyticsService.recordNonFatal(e, stackTrace, 'Google Sign-In failed');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C16),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.05),
                      blurRadius: 40,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF2563EB), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App Title
                    Text(
                      'ReviewsGateway',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),

                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'BUYER PORTAL',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF38BDF8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Sign in to launch campaigns, access your wallet, and track verified micro-tasks in real time.',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 13,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Feature List
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131D33),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureRow(
                            Icons.verified_user_rounded,
                            '10,000+ Real Micro-Workers on Android',
                            const Color(0xFF10B981),
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureRow(
                            Icons.bolt_rounded,
                            'Instant Campaign Setup & Geo-Targeting',
                            const Color(0xFFF59E0B),
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureRow(
                            Icons.shield_rounded,
                            '100% Escrow Shield & Screenshot Verification',
                            const Color(0xFF38BDF8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF2563EB),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                    width: 22,
                                    height: 22,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.g_mobiledata_rounded,
                                      color: Color(0xFFEA4335),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Sign in with Google',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF0F172A),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Download Android App APK Button
                    InkWell(
                      onTap: () => ApkDownloader.downloadBuyerApk(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.android_rounded,
                              color: Color(0xFF34D399),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Download Android App (APK) ⬇',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF34D399),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Terms Note
                    Text(
                      'By continuing, you agree to ReviewsGateway Terms of Service & Escrow Policy.',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 11,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              color: const Color(0xFFCBD5E1),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
