import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/crashlytics_service.dart';
import '../../../core/di/injection.dart';
import '../../../features/auth/screens/user_profile_form.dart';
import '../pages/main_navigation_page.dart';

/// Helper to check if current buyer is authenticated
class AuthHelper {
  static bool isAuthenticated() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return true;

    try {
      final localStorage = getIt<LocalStorageService>();
      final isLoggedIn = localStorage.isLoggedIn();
      final uid = localStorage.getUserId();
      return isLoggedIn && uid != null && uid.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Shows the login dialog if user is unauthenticated.
  /// Returns `true` if user is logged in, `false` otherwise.
  static Future<bool> requireAuth(
    BuildContext context, {
    String? title,
    String? message,
    VoidCallback? onAuthenticated,
  }) async {
    if (isAuthenticated()) {
      return true;
    }

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => LoginDialog(
        title: title,
        message: message,
      ),
    );

    if (success == true) {
      onAuthenticated?.call();
      return true;
    }
    return false;
  }
}

/// A modern, responsive modal dialog for Web & Mobile Google Sign-In
class LoginDialog extends StatefulWidget {
  final String? title;
  final String? message;

  const LoginDialog({
    super.key,
    this.title,
    this.message,
  });

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      User? firebaseUser;
      String? accountEmail;
      String? accountName;
      String? accountPhoto;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        
        try {
          final UserCredential userCredential =
              await FirebaseAuth.instance.signInWithPopup(googleProvider);
          firebaseUser = userCredential.user;
        } catch (popupErr) {
          debugPrint('[LOGIN DIALOG] Popup failed: $popupErr. Trying redirect...');
          await FirebaseAuth.instance.signInWithRedirect(googleProvider);
          return;
        }
      } else {
        final googleSignIn = GoogleSignIn(
          scopes: const ['email'],
          serverClientId:
              '311090572825-jve8b44v1m0p7smmudr6hnhe5ib5qcuc.apps.googleusercontent.com',
        );

        final account = await googleSignIn.signIn();
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

        final String phone = userData['phone'] ?? '';

        if (mounted) {
          Navigator.of(context).pop(true); // Close dialog with success

          if (phone.isEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserProfileFormScreen(
                  uid: firebaseUser!.uid,
                  initialName: userData['name'] ?? name,
                  email: email,
                  nextScreen: const MainNavigationPage(),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[LOGIN DIALOG ERROR] $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Login failed: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // Slate 900
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Top glowing light bar
              Positioned(
                top: 0,
                left: 40,
                right: 40,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFF38BDF8).withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Close button
              Positioned(
                top: 14,
                right: 14,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 22),
                  onPressed: () => Navigator.of(context).pop(false),
                  tooltip: 'Close',
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Icon badge with glowing gradient
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF2563EB), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.campaign_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dialog Title
                    Text(
                      widget.title ?? 'Sign In Required',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Subtitle / Description
                    Text(
                      widget.message ??
                          'Please sign in to access your dashboard, launch campaigns, manage your wallet, and track micro-worker tasks in real time.',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 13,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Benefits Pills
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureRow(
                            Icons.verified_user_rounded,
                            '10,000+ Verified Micro-Workers',
                            const Color(0xFF10B981),
                          ),
                          const SizedBox(height: 8),
                          _buildFeatureRow(
                            Icons.shield_rounded,
                            '100% Escrow Protection & Screenshot Audits',
                            const Color(0xFF38BDF8),
                          ),
                          const SizedBox(height: 8),
                          _buildFeatureRow(
                            Icons.bolt_rounded,
                            'Instant Campaign Dispatch in 60s',
                            const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFCA5A5),
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),

                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                          elevation: 3,
                          shadowColor: const Color(0xFF38BDF8).withValues(alpha: 0.3),
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
                                  color: Color(0xFF2563EB),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://res.cloudinary.com/dytdjjw4r/image/upload/v1776694476/google-icon-logo-svgrepo-com_pg842v.svg',
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.g_mobiledata_rounded,
                                      color: Color(0xFF4285F4),
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Continue with Google',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF0F172A),
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Terms disclaimer
                    Text(
                      'By continuing, you agree to ReviewsGateway Terms of Service & Privacy Policy',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              color: const Color(0xFFE2E8F0),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
