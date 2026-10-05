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
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              // Ambient gradient orbs
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                top: 140,
                left: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                  ),
                ),
              ),

              // Scrollable Content
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top App Header Branding with Buyer App Icon
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                'assets/logos/buyer_app_icon.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.campaign_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Marketing Pro',
                                  style: GoogleFonts.outfit(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                Text(
                                  'Campaign Management & Analytics Platform',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 2. Catchy Typography Tagline
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grow Your',
                              style: GoogleFonts.caveat(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF4338CA),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Business',
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                height: 1.05,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reach more people with smart marketing campaigns.',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 3. Realistic Marketing Hero Image (Matching Buyer App)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/marketing_team_hero.jpg',
                                fit: BoxFit.cover,
                                alignment: const Alignment(0, -0.3),
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF4F46E5),
                                  child: const Center(
                                    child: Icon(Icons.people_alt_rounded, color: Colors.white, size: 54),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.15),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 4. White Card Container ("Welcome Back!")
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back!',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Login to continue and manage your campaigns, track performance and grow your business.',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // 5. Google Sign-In Button with 4-Color Google 'G' Logo
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF0F172A),
                                      elevation: 0,
                                      side: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                    ),
                                    child: _isLoading
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Color(0xFF4F46E5),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Connecting to Google...',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const GoogleLogoWidget(size: 24),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Continue with Google',
                                                style: GoogleFonts.outfit(
                                                  color: const Color(0xFF0F172A),
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Download Android App APK Button
                              InkWell(
                                onTap: () => ApkDownloader.downloadBuyerApk(),
                                borderRadius: BorderRadius.circular(28),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.android_rounded, color: Color(0xFF059669), size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Download Android App (APK) ⬇',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF059669),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // 6. Value Proposition Chips / Trust Badges
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTrustBadge(
                                      icon: Icons.verified_user_rounded,
                                      label: '100% Real\nWorkers',
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildTrustBadge(
                                      icon: Icons.bolt_rounded,
                                      label: 'Instant\nExecution',
                                      color: const Color(0xFFF59E0B),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildTrustBadge(
                                      icon: Icons.security_rounded,
                                      label: 'Escrow\nProtected',
                                      color: const Color(0xFF4F46E5),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // 7. Terms & Privacy Notice
                              Center(
                                child: Text(
                                  'By continuing, you agree to our Terms & Privacy Policy',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Official 4-Color Google 'G' Logo Widget rendered crisp via CustomPainter
class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double center = s / 2;
    final double radius = s * 0.44;
    final double stroke = s * 0.18;

    final Rect outerRect = Rect.fromCircle(
      center: Offset(center, center),
      radius: radius,
    );

    // Blue horizontal bar
    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          center - (s * 0.04),
          center - (stroke / 2),
          radius + (s * 0.04),
          stroke,
        ),
        Radius.zero,
      ),
      bluePaint,
    );

    // Arc painter
    final Paint arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Blue arc (bottom right)
    arcPaint.color = const Color(0xFF4285F4);
    canvas.drawArc(outerRect, 0.0, 0.85, false, arcPaint);

    // Green arc (bottom)
    arcPaint.color = const Color(0xFF34A853);
    canvas.drawArc(outerRect, 0.85, 1.85, false, arcPaint);

    // Yellow arc (left)
    arcPaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(outerRect, 2.70, 1.30, false, arcPaint);

    // Red arc (top)
    arcPaint.color = const Color(0xFFEA4335);
    canvas.drawArc(outerRect, 4.00, 1.45, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
