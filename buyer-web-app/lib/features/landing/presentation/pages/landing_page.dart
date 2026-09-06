import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/presentation/pages/main_navigation_page.dart';
import '../../../auth/screens/user_profile_form.dart';

class ReviewsGatewayLandingPage extends StatefulWidget {
  const ReviewsGatewayLandingPage({super.key});

  @override
  State<ReviewsGatewayLandingPage> createState() => _ReviewsGatewayLandingPageState();
}

class _ReviewsGatewayLandingPageState extends State<ReviewsGatewayLandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _testimonialsKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  bool _isSigningIn = false;
  User? _currentUser;

  // Colors based on ReviewsGateway Brand
  static const Color brandPrimary = Color(0xFF6366F1); // Indigo
  static const Color brandSecondary = Color(0xFF8B5CF6); // Purple
  static const Color brandDark = Color(0xFF0F172A); // Slate 900
  static const Color brandBody = Color(0xFF475569); // Slate 600
  static const Color brandBg = Color(0xFFFFFFFF);
  static const Color brandCardBg = Color(0xFFF8FAFC);
  static const Color brandBorder = Color(0xFFE2E8F0);
  static const Color brandAmber = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) setState(() => _currentUser = user);
    });

    if (kIsWeb) {
      _checkRedirectResult();
    }
  }

  Future<void> _checkRedirectResult() async {
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.getRedirectResult();
      if (userCredential.user != null) {
        await _processSuccessfulAuth(userCredential.user!);
      }
    } catch (e) {
      debugPrint('[REDIRECT RESULT] $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _processSuccessfulAuth(User firebaseUser) async {
    final token = await firebaseUser.getIdToken();
    final storage = getIt<SecureStorageService>();
    final localStorage = getIt<LocalStorageService>();

    if (token != null) {
      await storage.saveAccessToken(token);
      await localStorage.saveAccessToken(token);
    }

    final email = firebaseUser.email ?? '';
    final name = firebaseUser.displayName ?? '';
    final photo = firebaseUser.photoURL ?? '';

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

    // Sync with Firestore profile
    final userData = await FirestoreService.syncUserProfile(
      uid: firebaseUser.uid,
      email: email,
      displayName: name,
      role: 'BUYER',
    );

    final String phone = userData['phone'] ?? '';
    if (mounted) {
      if (phone.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => UserProfileFormScreen(
              uid: firebaseUser.uid,
              initialName: userData['name'] ?? name,
              email: email,
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

  Future<void> _handleGoogleSignIn() async {
    if (_currentUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationPage()),
      );
      return;
    }

    setState(() => _isSigningIn = true);

    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      User? firebaseUser;

      if (kIsWeb) {
        try {
          final UserCredential userCredential =
              await FirebaseAuth.instance.signInWithPopup(googleProvider);
          firebaseUser = userCredential.user;
        } catch (popupError) {
          debugPrint('[POPUP BLOCKED OR FAILED] Falling back to redirect: $popupError');
          // If popup is blocked by browser or closed, fallback to full redirect flow
          await FirebaseAuth.instance.signInWithRedirect(googleProvider);
          return;
        }
      } else {
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithProvider(googleProvider);
        firebaseUser = userCredential.user;
      }

      if (firebaseUser != null) {
        await _processSuccessfulAuth(firebaseUser);
      }
    } catch (e) {
      debugPrint('[GOOGLE SIGN IN ERROR] $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    return Scaffold(
      backgroundColor: brandBg,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // 1. Top Announcement Bar
            _buildAnnouncementBar(),

            // 2. Main Navigation Bar
            _buildNavbar(isDesktop),

            // 3. Hero Section
            _buildHero(isDesktop, isTablet),

            // 4. Trust Marquee / Logos
            _buildTrustStrip(),

            // 5. Services Section
            _buildServicesSection(key: _servicesKey, isDesktop: isDesktop),

            // 6. Statistics Bar
            _buildStatsSection(isDesktop),

            // 7. How It Works Section
            _buildHowItWorksSection(key: _howItWorksKey, isDesktop: isDesktop),

            // 8. About Section
            _buildAboutSection(key: _aboutKey, isDesktop: isDesktop),

            // 9. Real Testimonials
            _buildTestimonialsSection(key: _testimonialsKey, isDesktop: isDesktop),

            // 10. Frequently Asked Questions
            _buildFaqSection(key: _faqKey, isDesktop: isDesktop),

            // 11. Pre-Footer Call to Action
            _buildPreFooterCta(isDesktop),

            // 12. Footer
            _buildFooter(isDesktop),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1. ANNOUNCEMENT BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAnnouncementBar() {
    return InkWell(
      onTap: () => _scrollTo(_servicesKey),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🚀 ', style: TextStyle(fontSize: 14)),
            Text(
              'Claim 50% OFF Your First Campaign Today! ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              'Learn More →',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 2. NAVBAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildNavbar(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: brandBorder, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand Logo
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [brandPrimary, brandSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: brandPrimary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(
                      text: 'Reviews',
                      style: TextStyle(color: brandPrimary),
                    ),
                    TextSpan(
                      text: 'Gateway',
                      style: TextStyle(color: brandDark),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Desktop Nav Items
          if (isDesktop)
            Row(
              children: [
                _navLink('Home', () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut)),
                _navLink('Services', () => _scrollTo(_servicesKey)),
                _navLink('How It Works', () => _scrollTo(_howItWorksKey)),
                _navLink('Testimonials', () => _scrollTo(_testimonialsKey)),
                _navLink('FAQ', () => _scrollTo(_faqKey)),
                _navLink('About', () => _scrollTo(_aboutKey)),
              ],
            ),

          // Auth / CTA Button
          Row(
            children: [
              if (_currentUser != null) ...[
                // Logged In Status & Avatar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: brandPrimary,
                        backgroundImage: _currentUser?.photoURL != null
                            ? CachedNetworkImageProvider(_currentUser!.photoURL!)
                            : null,
                        child: _currentUser?.photoURL == null
                            ? Text(
                                (_currentUser?.displayName ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _currentUser?.displayName?.split(' ').first ?? 'Account',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainNavigationPage()),
                    );
                  },
                  icon: const Icon(Icons.dashboard_rounded, size: 16),
                  label: const Text('Main Home →'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ] else ...[
                // Direct Dashboard Button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRouter.mainNavigation);
                  },
                  icon: const Icon(Icons.dashboard_outlined, size: 16),
                  label: const Text('Buyer Dashboard →'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brandDark,
                    side: const BorderSide(color: brandBorder, width: 1.5),
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 18 : 12,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),

                // Google Sign In CTA
                ElevatedButton.icon(
                  onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                  icon: _isSigningIn
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Image.network(
                          'https://res.cloudinary.com/dytdjjw4r/image/upload/v1776694476/google-icon-logo-svgrepo-com_pg842v.svg',
                          width: 18,
                          height: 18,
                          errorBuilder: (_, __, ___) => const Icon(Icons.login_rounded, size: 18),
                        ),
                  label: Text(
                    _isSigningIn ? 'Connecting...' : 'Launch Your Campaign',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandPrimary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 22 : 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                    shadowColor: brandPrimary.withOpacity(0.4),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _navLink(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            title,
            style: const TextStyle(
              color: brandDark,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 3. HERO SECTION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHero(bool isDesktop, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: isDesktop ? 60 : 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 6, child: _buildHeroTextContent()),
                    const SizedBox(width: 48),
                    Expanded(flex: 5, child: _buildHeroImage()),
                  ],
                )
              : Column(
                  children: [
                    _buildHeroTextContent(),
                    const SizedBox(height: 36),
                    _buildHeroImage(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeroTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trust Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: brandBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.star_rounded, color: brandAmber, size: 18),
              SizedBox(width: 6),
              Text(
                'Trusted by 1,000+ Businesses Worldwide',
                style: TextStyle(
                  color: brandDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Hero Title
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 46,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: brandDark,
              letterSpacing: -1.2,
            ),
            children: [
              TextSpan(text: 'We Build Online '),
              TextSpan(
                text: 'Reputation',
                style: TextStyle(
                  color: brandPrimary,
                  decoration: TextDecoration.underline,
                  decorationColor: brandSecondary,
                ),
              ),
              TextSpan(text: ' & Authority for Brands'),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Subtitle
        const Text(
          'We help brands, coaches, businesses, and professionals earn authentic reviews, organic installs, and high visibility that drives multi-fold growth.',
          style: TextStyle(
            fontSize: 17,
            height: 1.55,
            color: brandBody,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 32),

        // Hero CTA Buttons
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: _isSigningIn ? null : _handleGoogleSignIn,
              icon: _isSigningIn
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Image.network(
                      'https://res.cloudinary.com/dytdjjw4r/image/upload/v1776694476/google-icon-logo-svgrepo-com_pg842v.svg',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) => const Icon(Icons.rocket_launch_rounded, size: 20),
                    ),
              label: const Text(
                'Launch Your Campaign →',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 3,
                shadowColor: brandPrimary.withOpacity(0.5),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.mainNavigation);
              },
              icon: const Icon(Icons.dashboard_rounded, size: 18),
              label: const Text(
                'Open Buyer Dashboard',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            OutlinedButton(
              onPressed: () => _scrollTo(_servicesKey),
              style: OutlinedButton.styleFrom(
                foregroundColor: brandDark,
                side: const BorderSide(color: brandBorder, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Explore Services',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
            SizedBox(width: 6),
            Text('No password needed', style: TextStyle(color: brandBody, fontSize: 13)),
            SizedBox(width: 16),
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
            SizedBox(width: 6),
            Text('100% Organic Drip', style: TextStyle(color: brandBody, fontSize: 13)),
            SizedBox(width: 16),
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
            SizedBox(width: 6),
            Text('Instant Dashboard Access', style: TextStyle(color: brandBody, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroImage() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 460),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: brandPrimary.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          'https://res.cloudinary.com/dytdjjw4r/image/upload/v1773757511/ChatGPT_Image_Mar_17_2026_07_51_37_PM_ddqhl9.png',
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 340,
              color: const Color(0xFFF1F5F9),
              child: const Center(child: CircularProgressIndicator(color: brandPrimary)),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            height: 340,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [brandPrimary.withOpacity(0.1), brandSecondary.withOpacity(0.1)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.rocket_launch_rounded, size: 80, color: brandPrimary),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 4. TRUST MARQUEE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTrustStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border.symmetric(
          horizontal: BorderSide(color: brandBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'TRUSTED BY FAST-MOVING BRANDS & AGENCIES WORLDWIDE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 32,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              _trustBrand('WealthMize'),
              _trustBrand('iammafah'),
              _trustBrand('AutosaveContact'),
              _trustBrand('Chatpromo'),
              _trustBrand('Hostnet'),
              _trustBrand('NexusCommerce'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trustBrand(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: brandBorder),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: brandDark,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 5. SERVICES SECTION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildServicesSection({required GlobalKey key, required bool isDesktop}) {
    return Container(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: 70,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _sectionHeader(
                tag: 'OUR SERVICES',
                title: 'Powerful Growth Solutions That Drive Real Results',
                subtitle: 'Choose your desired service and launch your campaign in minutes with real organic users.',
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _serviceCard(
                    icon: Icons.card_giftcard_rounded,
                    iconBg: const Color(0xFFEEF2FF),
                    iconColor: brandPrimary,
                    title: 'Free Growth Tools',
                    desc: 'Start instantly with powerful tools to audit your app, analyze Google reviews, and uncover growth opportunities with zero signup fee.',
                    actionLabel: 'Launch Free Audit →',
                    onTap: _handleGoogleSignIn,
                    isDesktop: isDesktop,
                  ),
                  _serviceCard(
                    icon: Icons.star_rounded,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: brandAmber,
                    title: 'Google Reviews Growth',
                    desc: 'Boost online trust and top local 3-pack rankings with authentic verified Google reviews. Turn searchers into paying clients.',
                    actionLabel: 'Launch Google Campaign →',
                    onTap: _handleGoogleSignIn,
                    isDesktop: isDesktop,
                  ),
                  _serviceCard(
                    icon: Icons.phone_android_rounded,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF10B981),
                    title: 'App Install & Reviews',
                    desc: 'Scale your Play Store app with verified real-device downloads, high retention rates, and 5-star organic keyword reviews.',
                    actionLabel: 'Scale App Now →',
                    onTap: _handleGoogleSignIn,
                    isDesktop: isDesktop,
                  ),
                  _serviceCard(
                    icon: Icons.rocket_launch_rounded,
                    iconBg: const Color(0xFFFAF5FF),
                    iconColor: brandSecondary,
                    title: 'Complete App Growth System',
                    desc: 'All-in-one organic acceleration combining keyword installs, drip reviews, and retention strategies for guaranteed top rank.',
                    actionLabel: 'Get Full Engine →',
                    onTap: _handleGoogleSignIn,
                    isDesktop: isDesktop,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String desc,
    required String actionLabel,
    required VoidCallback onTap,
    required bool isDesktop,
  }) {
    final width = isDesktop ? 550.0 : double.infinity;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: brandBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded, color: brandPrimary, size: 20),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: brandDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 14.5,
                color: brandBody,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              actionLabel,
              style: const TextStyle(
                color: brandPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 6. STATS SECTION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsSection(bool isDesktop) {
    return Container(
      width: double.infinity,
      color: brandDark,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Wrap(
            spacing: 40,
            runSpacing: 30,
            alignment: WrapAlignment.spaceAround,
            children: [
              _statItem('1K+', 'Businesses Served'),
              _statItem('50K+', 'Reviews Generated'),
              _statItem('4.8★', 'Average Rating Boost'),
              _statItem('10X', 'Customer Trust Growth'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 7. HOW IT WORKS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHowItWorksSection({required GlobalKey key, required bool isDesktop}) {
    return Container(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: 70,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _sectionHeader(
                tag: 'HOW IT WORKS',
                title: 'Launch Your Campaign in 4 Simple Steps',
                subtitle: 'Seamless, automated, and secure campaign management built for modern brands.',
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _stepCard('1', Icons.assignment_outlined, 'Choose Service', 'Select Google Reviews, App Installs, or Combo bundles.'),
                  _stepCard('2', Icons.tune_rounded, 'Customize Target', 'Provide your Store/Google URL and specify organic daily pace.'),
                  _stepCard('3', Icons.shield_outlined, 'Instant Checkout', 'Fund securely via Wallet or payment gateway with automated invoicing.'),
                  _stepCard('4', Icons.auto_graph_rounded, 'Watch It Scale', 'Monitor live worker proof submissions and approve tasks directly.'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepCard(String number, IconData icon, String title, String desc) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: brandCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: brandPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: brandPrimary, size: 24),
              ),
              Text(
                '0$number',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: brandBorder,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: brandDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 13.5,
              color: brandBody,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 8. ABOUT SECTION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAboutSection({required GlobalKey key, required bool isDesktop}) {
    return Container(
      key: key,
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: 70,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(flex: 6, child: _buildAboutText()),
                    const SizedBox(width: 48),
                    Expanded(flex: 5, child: _buildAboutGraphic()),
                  ],
                )
              : Column(
                  children: [
                    _buildAboutText(),
                    const SizedBox(height: 36),
                    _buildAboutGraphic(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAboutText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tagPill('ABOUT US'),
        const SizedBox(height: 12),
        const Text(
          'Building Trust, Not Just Reviews',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: brandDark,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'ReviewsGateway was founded on the belief that digital trust is your most valuable revenue driver. We empower businesses to collect real feedback, protect brand sentiment, and maximize conversions with safe, organic community workflows.',
          style: TextStyle(fontSize: 15.5, color: brandBody, height: 1.6),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _aboutBadge('5+ Years', 'Field Experience'),
            _aboutBadge('98%', 'Client Retention'),
            _aboutBadge('24/7', 'Live Support'),
            _aboutBadge('Organic Drip', 'No Bot Guarantee'),
          ],
        ),
      ],
    );
  }

  Widget _aboutBadge(String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: brandBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: brandPrimary)),
          Text(label, style: const TextStyle(fontSize: 12, color: brandBody)),
        ],
      ),
    );
  }

  Widget _buildAboutGraphic() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        'https://res.cloudinary.com/dytdjjw4r/image/upload/v1774201838/review-gateway-main_udpawu.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 300,
          color: brandPrimary.withOpacity(0.08),
          child: const Center(child: Icon(Icons.shield_rounded, size: 60, color: brandPrimary)),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 9. TESTIMONIALS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTestimonialsSection({required GlobalKey key, required bool isDesktop}) {
    return Container(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: 70,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _sectionHeader(
                tag: 'TESTIMONIALS',
                title: 'What Business Owners Say About Us',
                subtitle: 'Verified feedback from companies that scaled their trust and conversions using our portal.',
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _testimonialCard(
                    name: 'Raju Sharma',
                    role: 'Agency Founder',
                    quote: 'Our Google reviews increased naturally within a few weeks. The drip pacing kept everything organic and our local inquiries skyrocketed.',
                    avatarUrl: 'https://res.cloudinary.com/dytdjjw4r/image/upload/v1778793422/young-bearded-man-with-striped-shirt_273609-5677_hhor86.avif',
                    isDesktop: isDesktop,
                  ),
                  _testimonialCard(
                    name: 'Priya Mehta',
                    role: 'Marketing Director',
                    quote: 'Outstanding service for Play Store app launches. Keyword ranking jumped 14 positions within 10 days of starting our campaign.',
                    avatarUrl: 'https://res.cloudinary.com/dytdjjw4r/image/upload/q_auto/f_auto/v1776434064/istockphoto-1144909099-612x612_jmg6ve.jpg',
                    isDesktop: isDesktop,
                  ),
                  _testimonialCard(
                    name: 'Simran Kaur',
                    role: 'E-commerce Brand Owner',
                    quote: 'The proof verification system gives complete peace of mind. We can review each worker screenshot before approving payment.',
                    avatarUrl: 'https://res.cloudinary.com/dytdjjw4r/image/upload/q_auto/f_auto/v1776434064/istockphoto-1304581885-612x612_ruwiff.jpg',
                    isDesktop: isDesktop,
                  ),
                  _testimonialCard(
                    name: 'Rahul Sharma',
                    role: 'SaaS Entrepreneur',
                    quote: 'Safe, professional, and reliable. No passwords asked, everything managed through clean dashboards with real-time analytics.',
                    avatarUrl: 'https://res.cloudinary.com/dytdjjw4r/image/upload/q_auto/f_auto/v1776434064/istockphoto-1384357176-612x612_ewyxsn.jpg',
                    isDesktop: isDesktop,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _testimonialCard({
    required String name,
    required String role,
    required String quote,
    required String avatarUrl,
    required bool isDesktop,
  }) {
    return Container(
      width: isDesktop ? 550 : double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: brandBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (index) => const Icon(Icons.star_rounded, color: brandAmber, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '"$quote"',
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: brandDark,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatarUrl),
                backgroundColor: brandCardBg,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                  Text(role, style: const TextStyle(fontSize: 12, color: brandBody)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 10. FAQ SECTION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFaqSection({required GlobalKey key, required bool isDesktop}) {
    return Container(
      key: key,
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: 70,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              _sectionHeader(
                tag: 'FAQ',
                title: 'Frequently Asked Questions',
                subtitle: 'Everything you need to know about our organic delivery, privacy, and campaign system.',
              ),
              const SizedBox(height: 40),
              _faqTile(
                'Are the reviews and installs from real users?',
                'Yes — 100%. All reviews come from active Google accounts and real physical mobile devices. We use gradual drip delivery to ensure 100% natural, safe patterns.',
              ),
              _faqTile(
                'How long does campaign delivery take?',
                'Most packages are fulfilled within 7 to 14 days depending on volume. Our system drips tasks steadily rather than delivering all at once, which ensures lasting retention.',
              ),
              _faqTile(
                'Is it safe for my Google Business Profile or Play Store app?',
                'Absolutely safe. We follow strict organic guidelines — real accounts, genuine devices, natural pacing, and geo-targeted profiles. Your account security is paramount.',
              ),
              _faqTile(
                'Do I need to share my passwords or login access?',
                'Never. We only need your public Google Business Profile link or Play Store app link. No password, no access delegation, no private keys required ever.',
              ),
              _faqTile(
                'How can I track my order progress?',
                'Once you sign in, your Buyer Dashboard provides real-time progress bars, screenshot proofs submitted by workers, approval buttons, and downloadable tax invoices.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _faqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: brandBorder),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: brandDark,
          ),
        ),
        iconColor: brandPrimary,
        collapsedIconColor: brandDark,
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 14, color: brandBody, height: 1.55),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 11. PRE-FOOTER CTA
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPreFooterCta(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: 70,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Text(
                'Ready to Build Your Online Authority?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Join over 1,000+ top brands scaling their credibility and organic revenue today.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                icon: _isSigningIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: brandDark, strokeWidth: 2),
                      )
                    : Image.network(
                        'https://res.cloudinary.com/dytdjjw4r/image/upload/v1776694476/google-icon-logo-svgrepo-com_pg842v.svg',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, __, ___) => const Icon(Icons.rocket_launch, color: brandDark),
                      ),
                label: const Text(
                  'Launch Your Campaign with Google',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: brandDark,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 12. FOOTER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFooter(bool isDesktop) {
    return Container(
      color: const Color(0xFF0B1120),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: 50,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(text: 'Reviews', style: TextStyle(color: brandPrimary)),
                        TextSpan(text: 'Gateway', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const Text(
                    'support@reviewsgateway.com',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFF1E293B)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '© 2026 ReviewsGateway Technologies. All rights reserved.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  Text(
                    'Mumbai, India • 100% Verified Workflows',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _sectionHeader({required String tag, required String title, required String subtitle}) {
    return Column(
      children: [
        _tagPill(tag),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: brandDark,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: brandBody, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _tagPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: brandPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: brandPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
