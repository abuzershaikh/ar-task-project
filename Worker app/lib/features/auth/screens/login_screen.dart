import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../navigation/screens/main_nav_screen.dart';
import 'user_profile_form.dart';

/// Clean Google-only Login Screen for Worker App.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      debugPrint('[GOOGLE SIGN IN] Starting Worker Google Sign-In process...');
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

        // Ensure Firebase is initialized
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp();
          }
        } catch (e) {
          debugPrint('Firebase core init in login error: $e');
        }

        // Authenticate with Firebase Auth
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final User? firebaseUser = userCredential.user;

        if (firebaseUser != null) {
          // Sync worker profile to Firestore only (No VPS token transmission)
          final userData = await FirestoreService.syncUserProfile(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? account.email,
            displayName: firebaseUser.displayName ?? account.displayName,
            role: 'WORKER',
          );

          await authProvider.setFirebaseUser(firebaseUser, userData);

          final String phone = userData['phone'] ?? '';
          if (mounted) {
            if (phone.isEmpty) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => UserProfileFormScreen(
                    uid: firebaseUser.uid,
                    initialName: userData['name'] ?? account.displayName ?? '',
                    email: firebaseUser.email ?? account.email,
                  ),
                ),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainNavScreen()),
              );
            }
          }
        }
      }
    } catch (e, stack) {
      debugPrint('[GOOGLE SIGN IN ERROR] Exception: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDirectLogin() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final userData = {
        'uid': 'worker_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'Worker User',
        'email': 'worker_user@taskpost.com',
        'role': 'WORKER',
        'phone': '9876543210',
        'isOnline': true,
      };
      await authProvider.setDirectUser(userData);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavScreen()),
        );
      }
    } catch (e) {
      debugPrint('[DIRECT LOGIN ERROR] $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              children: [
                const Spacer(),

                // App Icon / Logo Badge
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.stars_rounded, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),

                Text(
                  'Task Reward',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Perform simple micro-tasks, submit proof,\nand earn instant rewards.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // Feature Highlights
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureRow(
                        Icons.check_circle_outline_rounded,
                        'Verified real-time payouts',
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureRow(
                        Icons.security_rounded,
                        'Secure Google authentication',
                        const Color(0xFF3B82F6),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureRow(
                        Icons.bolt_rounded,
                        'Fast automated task review',
                        const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Google Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 2,
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
                              color: Color(0xFF4285F4),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.g_mobiledata_rounded,
                                color: Color(0xFF4285F4),
                                size: 32,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Sign in with Google',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Direct Worker Access Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleDirectLogin,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.25)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white70),
                    label: const Text(
                      'Direct Worker Access (Quick Login)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'By continuing, you agree to our Terms of Service & Privacy Policy',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),
              ],
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
