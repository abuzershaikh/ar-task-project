import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../navigation/screens/main_nav_screen.dart';

/// Clean Google-only Login Screen for Worker App.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon / Logo Badge
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.stars_rounded, size: 52, color: Colors.white),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'Task Reward',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete Tasks • Earn Real Money',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.accentColor, fontSize: 16),
                  ),
                  const SizedBox(height: 48),

                  // Google Login Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome Worker',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sign in with your Google account to get started and earn rewards.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                          const SizedBox(height: 28),

                          SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                              ),
                              icon: const Icon(Icons.g_mobiledata_rounded, size: 32, color: Color(0xFF4285F4)),
                              label: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4285F4)),
                                    )
                                  : const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      setState(() => _isLoading = true);
                                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                      try {
                                        debugPrint('[GOOGLE SIGN IN] Starting Google Sign-In process...');
                                        final googleSignIn = GoogleSignIn(
                                          scopes: const ['email'],
                                          serverClientId: '311090572825-jve8b44v1m0p7smmudr6hnhe5ib5qcuc.apps.googleusercontent.com',
                                        );
                                        final account = await googleSignIn.signIn();
                                        debugPrint('[GOOGLE SIGN IN] Account result: $account');
                                        if (account != null) {
                                          final auth = await account.authentication;
                                          final String? googleIdToken = auth.idToken ?? auth.accessToken;
                                          debugPrint(
                                            '[GOOGLE SIGN IN] Google token obtained: ${googleIdToken != null ? "YES (${googleIdToken.substring(0, 10)}...)" : "NULL"}',
                                          );
                                          if (googleIdToken != null) {
                                            final response = await ApiService.googleLogin(googleIdToken);
                                            final token = response['data']?['accessToken'] ?? response['accessToken'] ?? response['token'];
                                            if (token != null) {
                                              await ApiService.saveToken(token);
                                              await authProvider.fetchProfile();
                                              if (mounted) {
                                                Navigator.of(context).pushReplacement(
                                                  MaterialPageRoute(builder: (_) => const MainNavScreen()),
                                                );
                                              }
                                            }
                                          } else if (googleIdToken == null && mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Google Sign-In failed: Google token is null')),
                                            );
                                          }
                                        } else {
                                          debugPrint('[GOOGLE SIGN IN] User canceled sign-in dialog.');
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
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
