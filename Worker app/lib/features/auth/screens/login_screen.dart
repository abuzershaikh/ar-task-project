import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../navigation/screens/main_nav_screen.dart';
import 'user_profile_form.dart';

/// 3D Realistic & Animated Google Auth Screen for Worker App
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late Animation<double> _iconFloatAnimation;

  @override
  void initState() {
    super.initState();
    // Continuous subtle floating / bobbing motion animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _iconFloatAnimation = Tween<double>(begin: 3.5, end: -3.5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      debugPrint('[GOOGLE SIGN IN] Starting Worker Google Sign-In process...');
      final googleSignIn = GoogleSignIn(
        scopes: const ['email'],
        serverClientId:
            '311090572825-jve8b44v1m0p7smmudr6hnhe5ib5qcuc.apps.googleusercontent.com',
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
          final String? photoUrl = account.photoUrl ?? firebaseUser.photoURL;

          // Sync worker profile to Firestore only
          final userData = await FirestoreService.syncUserProfile(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? account.email,
            displayName: firebaseUser.displayName ?? account.displayName,
            role: 'WORKER',
            photoUrl: photoUrl,
          );

          await authProvider.setFirebaseUser(firebaseUser, {
            ...userData,
            'photoUrl': photoUrl,
          });

          final String phone = userData['phone'] ?? '';
          if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF040A26),
      body: Stack(
        children: [
          // 1. Deep Midnight & Royal Blue Rich Ambient Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF030822),
                    Color(0xFF071442),
                    Color(0xFF0C246E),
                    Color(0xFF060E36),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
          ),

          // 2. Glowing Ambient Orbs in Background
          Positioned(
            top: 20,
            left: size.width * 0.15,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2563EB).withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 260,
            right: -30,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA855F7).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Scrollable Foreground Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  topPadding > 0 ? 4 : 10,
                  16,
                  bottomPadding > 0 ? bottomPadding + 16 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Animated Hero 3D Artwork (Floating with gentle bobbing motion)
                    AnimatedBuilder(
                      animation: _floatAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: child,
                        );
                      },
                      child: Container(
                        height: 290,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1D4ED8).withValues(alpha: 0.45),
                              blurRadius: 36,
                              spreadRadius: 2,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/worker_fast_payout_hero.jpg',
                                fit: BoxFit.cover,
                                alignment: const Alignment(0, -0.15),
                              ),
                              // Soft bottom gradient blend to merge with background
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        const Color(0xFF040A26).withValues(alpha: 0.15),
                                        const Color(0xFF040A26).withValues(alpha: 0.60),
                                      ],
                                      stops: const [0.65, 0.88, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Big 3D "Fast Payout ⚡" Title with Underline Swoosh
                    _buildFastPayoutTitle(),

                    const SizedBox(height: 18),

                    // 3. Glassmorphic 5-Category Services Container (With subtle counter-float)
                    AnimatedBuilder(
                      animation: _iconFloatAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _iconFloatAnimation.value),
                          child: child,
                        );
                      },
                      child: _buildCategoriesRow(),
                    ),

                    const SizedBox(height: 24),

                    // 4. Energetic Glowing "Sign in with Google ➔" Button
                    _buildGoogleSignInButton(),

                    const SizedBox(height: 20),

                    // 5. Trust Badge Footer: "🛡️ Safe • Simple • Fast"
                    _buildFooterTrustBadge(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3D Embossed "Fast Payout ⚡" with Gradient & Yellow Swoosh
  Widget _buildFastPayoutTitle() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // "Fast " in 3D White with Deep Blue Multi-Shadow Extrusion
            Text(
              'Fast ',
              style: GoogleFonts.outfit(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
                shadows: [
                  const Shadow(
                    color: Color(0xFF001B5E),
                    offset: Offset(0, 2),
                  ),
                  const Shadow(
                    color: Color(0xFF001B5E),
                    offset: Offset(0, 4),
                  ),
                  const Shadow(
                    color: Color(0xFF001446),
                    offset: Offset(0, 6),
                  ),
                  Shadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.85),
                    offset: const Offset(0, 10),
                    blurRadius: 18,
                  ),
                ],
              ),
            ),

            // "Payout" in Magenta-Purple 3D Gradient
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFE879F9), Color(0xFFC084FC), Color(0xFFF472B6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                'Payout',
                style: GoogleFonts.outfit(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  shadows: const [
                    Shadow(
                      color: Color(0xFF3B0764),
                      offset: Offset(0, 3),
                    ),
                    Shadow(
                      color: Color(0xFF2E0250),
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Yellow 3D Lightning Bolt ⚡
            Transform.rotate(
              angle: 0.12,
              child: const Text(
                '⚡',
                style: TextStyle(
                  fontSize: 36,
                  shadows: [
                    Shadow(
                      color: Color(0xFFFACC15),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Yellow Curved Swoosh Underline
        const SizedBox(height: 4),
        CustomPaint(
          size: const Size(240, 8),
          painter: _YellowSwooshPainter(),
        ),
      ],
    );
  }

  /// Glassmorphic Card showing 5 Earning Task Categories
  Widget _buildCategoriesRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1B54).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.40),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000826).withValues(alpha: 0.7),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCategoryItem(
            iconAsset: 'assets/icons/google-maps.png',
            title: 'Google Map',
            subtitle: 'Find & Explore',
            bgColor: Colors.white,
          ),
          _buildCategoryItem(
            iconAsset: 'assets/icons/youtube.png',
            title: 'YouTube',
            subtitle: 'Watch & Earn',
            bgColor: const Color(0xFFEF4444),
          ),
          _buildCategoryItem(
            iconAsset: 'assets/icons/instagram.png',
            title: 'Instagram',
            subtitle: 'Like & Engage',
            gradient: const LinearGradient(
              colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          _buildCategoryItem(
            iconAsset: 'assets/icons/google-play.png',
            title: 'Playstore',
            subtitle: 'Download & Earn',
            bgColor: Colors.white,
          ),
          _buildCategoryItem(
            iconAsset: 'assets/icons/review.png',
            title: 'Review',
            subtitle: 'Share Opinion',
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String iconAsset,
    required String title,
    required String subtitle,
    Color? bgColor,
    Gradient? gradient,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            gradient: gradient,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Image.asset(
            iconAsset,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          maxLines: 1,
        ),
        const SizedBox(height: 1),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF93C5FD),
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  /// Big Energetic "Sign in with Google ➔" Button
  Widget _buildGoogleSignInButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Golden sparkle accents on top-left and bottom-right
        Positioned(
          top: -12,
          left: 14,
          child: Transform.rotate(
            angle: -0.2,
            child: const Text(
              '✦',
              style: TextStyle(
                color: Color(0xFFFDE047),
                fontSize: 18,
                shadows: [
                  Shadow(color: Color(0xFFFACC15), blurRadius: 10),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          right: 18,
          child: Transform.rotate(
            angle: 0.2,
            child: const Text(
              '✦',
              style: TextStyle(
                color: Color(0xFFFDE047),
                fontSize: 16,
                shadows: [
                  Shadow(color: Color(0xFFFACC15), blurRadius: 10),
                ],
              ),
            ),
          ),
        ),

        // Button Container
        SizedBox(
          width: double.infinity,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.55),
                  blurRadius: 26,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleGoogleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 22),
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Signing in with Google...',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const GoogleLogoWidget(size: 26),
                        const SizedBox(width: 14),
                        Text(
                          'Sign in with Google',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF0F172A),
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF1D4ED8),
                          size: 22,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// Footer Trust Badge: "🛡️ Safe • Simple • Fast"
  Widget _buildFooterTrustBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            color: Color(0xFF60A5FA),
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Safe  •  Simple  •  Fast',
          style: GoogleFonts.outfit(
            color: const Color(0xFF93C5FD),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

/// Official 4-Color Google 'G' Logo Widget
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

/// Dynamic Yellow Swoosh Underline
class _YellowSwooshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFACC15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.5,
      size.width,
      0,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
