import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/crashlytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/presentation/pages/main_navigation_page.dart';
import '../../screens/user_profile_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('[GOOGLE SIGN IN] Starting Google Sign-In process...');
      final googleSignIn = GoogleSignIn(
        scopes: const ['email'],
        serverClientId: '311090572825-jve8b44v1m0p7smmudr6hnhe5ib5qcuc.apps.googleusercontent.com',
      );
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final account = await googleSignIn.signIn();
      debugPrint('[GOOGLE SIGN IN] Account result: $account');

      if (account != null) {
        final auth = await account.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );

        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final User? firebaseUser = userCredential.user;

        if (firebaseUser != null) {
          final token = await firebaseUser.getIdToken();
          final storage = getIt<SecureStorageService>();
          if (token != null) await storage.saveAccessToken(token);
          await storage.saveUserEmail(firebaseUser.email ?? account.email);
          await storage.saveUserName(firebaseUser.displayName ?? account.displayName ?? '');
          await storage.saveUserId(firebaseUser.uid);

          // Link user to Crashlytics reports
          await CrashlyticsService.setUser(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? account.email,
            name: firebaseUser.displayName ?? account.displayName,
            role: 'BUYER',
          );

          final userData = await FirestoreService.syncUserProfile(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? account.email,
            displayName: firebaseUser.displayName ?? account.displayName,
            role: 'BUYER',
          );

          final String phone = userData['phone'] ?? '';
          if (context.mounted) {
            if (phone.isEmpty) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => UserProfileFormScreen(
                    uid: firebaseUser.uid,
                    initialName: userData['name'] ?? account.displayName ?? '',
                    email: firebaseUser.email ?? account.email,
                    nextScreen: const MainNavigationPage(),
                  ),
                ),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainNavigationPage()),
              );
            }
          }
        }
      }
    } catch (e, stack) {
      debugPrint('[GOOGLE SIGN IN ERROR] Exception: $e\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            children: [
              const Spacer(),

              // Logo & App Name
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Marketing Pro',
                style: AppTextStyles.heading1.copyWith(
                  color: const Color(0xFF0F172A),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Campaign Management & Analytics Platform',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Feature Badges
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(Icons.verified_user_rounded, 'Verified Worker Analytics', const Color(0xFF10B981)),
                    const SizedBox(height: 12),
                    _buildFeatureRow(Icons.bolt_rounded, 'Real-time Campaign Execution', const Color(0xFFF59E0B)),
                    const SizedBox(height: 12),
                    _buildFeatureRow(Icons.security_rounded, 'Secure Escrow Payments', const Color(0xFF4F46E5)),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Single Google Sign In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 1,
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF4F46E5),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.g_mobiledata_rounded,
                              color: Color(0xFF4F46E5),
                              size: 32,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Sign in with Google',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'By signing in, you agree to our Terms & Privacy Policy',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
