import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routes/app_router.dart';
import '../bloc/dashboard_bloc.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/campaign_summary.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late PageController _carouselController;
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;
  String _selectedCategory = 'All Solutions';

  final List<Map<String, dynamic>> _carouselSlides = [
    {
      'badge': '⭐ TOP RATED • GOOGLE PLAY',
      'title': 'Dominate Google Play Store',
      'highlight': '5-Star Ratings & AI Reviews',
      'description': 'Rank #1 on search keywords with genuine user downloads & authentic reviews from verified Android devices.',
      'gradientColors': [const Color(0xFF0F172A), const Color(0xFF0284C7), const Color(0xFF0D9488)],
      'accentColor': const Color(0xFF38BDF8),
      'buttonText': 'Boost Play Store →',
      'platform': 'playstore',
      'route': AppRouter.services,
    },
    {
      'badge': '🚀 VIRAL ENGINE • YOUTUBE',
      'title': 'Ignite YouTube Algorithm',
      'highlight': 'High Retention & Discussions',
      'description': 'Real video watch time, organic likes & intelligent niche-relevant comments that push videos to recommendations.',
      'gradientColors': [const Color(0xFF1E1B4B), const Color(0xFF991B1B), const Color(0xFFBE123C)],
      'accentColor': const Color(0xFFFB7185),
      'buttonText': 'Supercharge Video →',
      'platform': 'youtube',
      'route': AppRouter.services,
    },
    {
      'badge': '🛡️ ZERO BOTS • 100% REAL',
      'title': '10,000+ Verified Workers',
      'highlight': 'Real Hardware & Screenshots',
      'description': 'Every task is completed by real Indian users on active smartphones with rigorous screenshot proof auditing.',
      'gradientColors': [const Color(0xFF064E3B), const Color(0xFF047857), const Color(0xFF0F766E)],
      'accentColor': const Color(0xFF34D399),
      'buttonText': 'Launch Campaign →',
      'platform': 'verify',
      'route': AppRouter.createCampaign,
    },
    {
      'badge': '⚡ MASSIVE SCALE • RAPID DISPATCH',
      'title': 'Scale to 10,000 Tasks',
      'highlight': 'Instant Automated Allocation',
      'description': 'Deploy high-volume campaigns in 60 seconds with live real-time progress analytics and escrow safety.',
      'gradientColors': [const Color(0xFF312E81), const Color(0xFF4338CA), const Color(0xFF6D28D9)],
      'accentColor': const Color(0xFFA78BFA),
      'buttonText': 'Create Custom Order →',
      'platform': 'scale',
      'route': AppRouter.createCampaign,
    },
  ];

  final List<Map<String, dynamic>> _serviceCatalog = [
    {
      'id': 'play_review',
      'category': 'Play Store',
      'title': 'Play Store 5-Star Rating & Review',
      'tag': 'MOST POPULAR',
      'tagColor': const Color(0xFFF59E0B),
      'description': 'Boost keyword ranking & app conversion. Workers download, test for 30s, give 5★ rating & post authentic keyword-rich reviews.',
      'price': 'From ₹25 / review',
      'gradient': [const Color(0xFF047857), const Color(0xFF059669)],
      'iconType': 'playstore',
      'features': ['100% Real Android Devices', 'Keyword Placement', 'Verified Badges'],
      'route': AppRouter.services,
    },
    {
      'id': 'yt_comments',
      'category': 'YouTube',
      'title': 'YouTube Targeted AI Comments',
      'tag': 'VIRAL ALGORITHM',
      'tagColor': const Color(0xFFEF4444),
      'description': 'Trigger the YouTube recommendation algorithm with context-aware, topic-specific comments and natural active discussions.',
      'price': 'From ₹5 / comment',
      'gradient': [const Color(0xFFBE123C), const Color(0xFFE11D48)],
      'iconType': 'youtube_comment',
      'features': ['Custom or AI Prompts', 'High Retention', 'Spam-Free Accounts'],
      'route': AppRouter.services,
    },
    {
      'id': 'yt_likes_subs',
      'category': 'YouTube',
      'title': 'YouTube Likes & Channel Subscribers',
      'tag': 'AUTHORITY BUILDER',
      'tagColor': const Color(0xFF8B5CF6),
      'description': 'Permanent channel subscribers and genuine video likes from unique IP addresses to establish instant social proof.',
      'price': 'From ₹3 / like',
      'gradient': [const Color(0xFF6D28D9), const Color(0xFF7C3AED)],
      'iconType': 'youtube_sub',
      'features': ['Permanent Subscribers', 'Fast Delivery', 'Safe for Monetization'],
      'route': AppRouter.services,
    },
    {
      'id': 'app_install',
      'category': 'Mobile Apps',
      'title': 'Android App Install & Open',
      'tag': 'DOWNLOADS SURGE',
      'tagColor': const Color(0xFF0284C7),
      'description': 'Drive massive direct installs to your app from active Android users. Guaranteed installation and open verification.',
      'price': 'From ₹15 / install',
      'gradient': [const Color(0xFF0369A1), const Color(0xFF0284C7)],
      'iconType': 'app_install',
      'features': ['Unique Device IDs', 'Open App Verification', 'Organic Search Surge'],
      'route': AppRouter.services,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _carouselController = PageController(viewportFraction: 0.94);
    _startCarouselTimer();
    context.read<DashboardBloc>().add(LoadDashboardDataEvent());
    _fadeController.forward();
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_carouselController.hasClients) {
        final nextPage = (_currentCarouselIndex + 1) % _carouselSlides.length;
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C16),
      body: Stack(
        children: [
          // ─── 1. 3D AMBIENT ATMOSPHERE BACKGROUND ───
          _buildAmbientBackground(),

          // ─── 2. MAIN SCROLLABLE CONTENT ───
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF38BDF8),
                    strokeWidth: 2.5,
                  ),
                );
              }

              if (state is DashboardError) {
                return _buildErrorView(state.message);
              }

              final d = state is DashboardLoaded
                  ? state.dashboardData
                  : const DashboardData(
                      totalSpend: 0,
                      totalCampaigns: 0,
                      activeCampaigns: 0,
                      completedCampaigns: 0,
                      pendingTasks: 0,
                      inProgressTasks: 0,
                      completedTasks: 0,
                      overallCompletion: 0,
                      recentCampaigns: [],
                    );

              return FadeTransition(
                opacity: _fadeController,
                child: RefreshIndicator(
                  color: const Color(0xFF38BDF8),
                  backgroundColor: const Color(0xFF0F172A),
                  onRefresh: () async {
                    context.read<DashboardBloc>().add(LoadDashboardDataEvent());
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: EdgeInsets.zero,
                    children: [
                      // Header
                      _buildTopHeader(context, d),
                      const SizedBox(height: 16),

                      // 3D Multi-Slide Carousel ("caroon")
                      _build3DCarouselSection(),
                      const SizedBox(height: 14),

                      // 3D Investment & Performance Overview Card
                      _build3DInvestmentCard(context, d),
                      const SizedBox(height: 24),

                      // 3D Services Catalog Section (with clear explanations & beautiful transparent 3D icons)
                      _buildServicesExplorerSection(context),
                      const SizedBox(height: 24),

                      // Live Active Campaigns Monitor
                      if (d.recentCampaigns.isNotEmpty) ...[
                        _buildRecentCampaignsSection(context, d.recentCampaigns),
                        const SizedBox(height: 24),
                      ],

                      // 3D Trust & Assurance Pillars
                      _buildTrustAssuranceGrid(),
                      const SizedBox(height: 36),

                      // Bottom safe area padding
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. 3D AMBIENT BACKGROUND WITH MESH GLOWS
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildAmbientBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Deep Obsidian Base
          Container(color: const Color(0xFF080D1A)),

          // Glowing Indigo Ambient Light Sphere (Top Right)
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4F46E5).withValues(alpha: 0.35),
                    const Color(0xFF4F46E5).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Glowing Cyan Light Sphere (Middle Left)
          Positioned(
            top: 240,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withValues(alpha: 0.20),
                    const Color(0xFF06B6D4).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Glowing Emerald Light Sphere (Lower Right)
          Positioned(
            top: 600,
            right: -120,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.18),
                    const Color(0xFF10B981).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Futuristic Geometric Grid Overlay
          Opacity(
            opacity: 0.03,
            child: CustomPaint(
              size: Size.infinite,
              painter: _TechGridPainter(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. TOP VIP HEADER
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTopHeader(BuildContext context, DashboardData d) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
        child: Row(
          children: [
            // 3D Metallic Avatar Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF4F46E5), Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      color: Color(0xFF38BDF8),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Greeting & Business Tagline
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_greeting()} 👋',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Text(
                          'BUYER VIP',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF34D399),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Grow your Apps, Channels & Brand',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Notification Center with Glow
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRouter.notifications),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. 3D HERO CAROUSEL ("caroon") WITH AUTO-SLIDER & GLOW
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _build3DCarouselSection() {
    return Column(
      children: [
        SizedBox(
          height: 195,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: _carouselSlides.length,
            onPageChanged: (index) {
              setState(() => _currentCarouselIndex = index);
            },
            itemBuilder: (context, index) {
              final slide = _carouselSlides[index];
              return _buildCarouselCard(slide);
            },
          ),
        ),
        const SizedBox(height: 10),

        // Animated Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_carouselSlides.length, (index) {
            final isSelected = _currentCarouselIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 22 : 6,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF38BDF8)
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                          blurRadius: 6,
                        )
                      ]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCarouselCard(Map<String, dynamic> slide) {
    final List<Color> gradientColors = slide['gradientColors'];
    final Color accentColor = slide['accentColor'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background 3D Abstract Glow Ring
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),

            // 3D Floating Platform Icon Illustration (Transparent Depth)
            Positioned(
              right: 14,
              bottom: 14,
              child: _build3DPlatformIllustration(slide['platform'], accentColor),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 110, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      slide['badge'],
                      style: GoogleFonts.outfit(
                        color: accentColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),

                  // Title & Highlight
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slide['title'],
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        slide['highlight'],
                        style: GoogleFonts.outfit(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        slide['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),

                  // Action Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, slide['route'] as String);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        slide['buttonText'],
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DPlatformIllustration(String platform, Color accent) {
    if (platform == 'playstore') {
      return Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 48),
            Positioned(
              top: 8,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Text('5★', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      );
    }

    if (platform == 'youtube') {
      return Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_fill_rounded, color: Color(0xFFEF4444), size: 50),
        ),
      );
    }

    if (platform == 'verify') {
      return Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: const Center(
          child: Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 48),
        ),
      );
    }

    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: const Center(
        child: Icon(Icons.speed_rounded, color: Color(0xFFA78BFA), size: 48),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. 3D INVESTMENT & METRICS CARD (REPLACES COMPLEX ANALYTICS WITH CLEAN 3D)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _build3DInvestmentCard(BuildContext context, DashboardData d) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.7), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Ambient Top Glow
            Positioned(
              top: 0,
              left: 20,
              right: 20,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF38BDF8).withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Title & Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF38BDF8), size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Marketing Investment',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'LIVE ESCROW',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF34D399),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Big Spend Display + Create Campaign Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${d.totalSpend.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total Campaign Budget Allocated',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Glowing 3D Launch Button
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRouter.services),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.45),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                'New Campaign',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Divider Line
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
                  const SizedBox(height: 14),

                  // 3 Key Stats Pills (No complicated graphs)
                  Row(
                    children: [
                      _buildMetricBox('Active Campaigns', '${d.activeCampaigns}', const Color(0xFF10B981), Icons.bolt_rounded),
                      const SizedBox(width: 8),
                      _buildMetricBox('Completed', '${d.completedCampaigns}', const Color(0xFF6366F1), Icons.done_all_rounded),
                      const SizedBox(width: 8),
                      _buildMetricBox('Units Done', '${d.completedTasks}', const Color(0xFFF59E0B), Icons.task_alt_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String val, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1120),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(height: 4),
            Text(
              val,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. 3D INTERACTIVE SERVICES EXPLORER (BEAUTIFUL VISUALS & EXPLANATIONS)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildServicesExplorerSection(BuildContext context) {
    final filteredServices = _selectedCategory == 'All Solutions'
        ? _serviceCatalog
        : _serviceCatalog.where((s) => s['category'] == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Growth Services Catalog',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'Choose marketing solution to deploy instantly',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRouter.services),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    'View All →',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Category Filter Chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            children: [
              _buildCategoryChip('All Solutions'),
              _buildCategoryChip('Play Store'),
              _buildCategoryChip('YouTube'),
              _buildCategoryChip('Mobile Apps'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Service Cards List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: filteredServices.map((service) {
              return _build3DServiceCard(context, service);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String title) {
    final isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = title);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF38BDF8)
              : const Color(0xFF1E293B).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF38BDF8)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: isSelected ? const Color(0xFF0F172A) : Colors.white70,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DServiceCard(BuildContext context, Map<String, dynamic> s) {
    final List<Color> gradient = s['gradient'];
    final Color tagColor = s['tagColor'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle Ambient Colored Accent Border on Top
          Positioned(
            top: 0,
            left: 24,
            right: 24,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, gradient.first, Colors.transparent],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: 3D Platform Icon + Tag & Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3D Layered Platform Icon
                    _buildService3DIcon(s['iconType'], gradient),
                    const SizedBox(width: 14),

                    // Title & Category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: tagColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: tagColor.withValues(alpha: 0.4), width: 0.8),
                            ),
                            child: Text(
                              s['tag'],
                              style: GoogleFonts.outfit(
                                color: tagColor,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            s['title'],
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price Tag Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s['price'],
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF34D399),
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Description (Explaining clearly to the buyer)
                Text(
                  s['description'],
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),

                // Key Features Row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (s['features'] as List<String>).map((feat) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF38BDF8), size: 10),
                          const SizedBox(width: 4),
                          Text(
                            feat,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFCBD5E1),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Full Width Button: "Deploy Campaign"
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, s['route'] as String);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Launch Campaign For This Service',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildService3DIcon(String iconType, List<Color> gradient) {
    IconData icon;
    Color iconColor = Colors.white;

    switch (iconType) {
      case 'playstore':
        icon = Icons.star_rounded;
        iconColor = const Color(0xFFFBBF24);
        break;
      case 'youtube_comment':
        icon = Icons.chat_bubble_rounded;
        iconColor = Colors.white;
        break;
      case 'youtube_sub':
        icon = Icons.thumb_up_alt_rounded;
        iconColor = Colors.white;
        break;
      case 'app_install':
        icon = Icons.install_mobile_rounded;
        iconColor = Colors.white;
        break;
      default:
        icon = Icons.campaign_rounded;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. RECENT CAMPAIGNS LIVE MONITOR
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildRecentCampaignsSection(BuildContext context, List<CampaignSummary> campaigns) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Active Campaigns Live Tracker',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRouter.campaigns),
                child: Text(
                  'Manage (${campaigns.length}) →',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF38BDF8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Campaigns List
          ...campaigns.take(3).map((c) {
            final progress = c.totalTasks > 0 ? c.completedTasks / c.totalTasks : 0.0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.status.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF34D399),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Progress Bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: const Color(0xFF1E293B),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${c.completedTasks}/${c.totalTasks} Done',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF94A3B8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. 3D TRUST & ASSURANCE PILLARS (BUYER PEACE OF MIND)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTrustAssuranceGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The EarnPost Buyer Guarantee',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Built from the ground up for high-security, authentic growth',
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),

          // 2x2 Trust Grid
          Row(
            children: [
              _buildTrustCard(
                icon: Icons.camera_alt_rounded,
                title: 'Screenshot Audits',
                desc: 'Every single task submitted with high-res photo proof',
                color: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 10),
              _buildTrustCard(
                icon: Icons.security_rounded,
                title: 'Escrow Protected',
                desc: '100% money back if tasks are not approved by you',
                color: const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTrustCard(
                icon: Icons.bolt_rounded,
                title: '60s Instant Dispatch',
                desc: 'Automated queue sends orders to active micro-workers',
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 10),
              _buildTrustCard(
                icon: Icons.support_agent_rounded,
                title: '24/7 VIP Support',
                desc: 'Direct dedicated support for large enterprise campaigns',
                color: const Color(0xFFA855F7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              desc,
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 9.5,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 36, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<DashboardBloc>().add(LoadDashboardDataEvent()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry Connection', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER FOR BACKGROUND TECH GRID
// ─────────────────────────────────────────────────────────────────────────────
class _TechGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.6;

    const spacing = 36.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
