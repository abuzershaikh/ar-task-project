import 'dart:async';
import '../../../services/data/repositories/service_repository_impl.dart';
import '../../../services/domain/models/service_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/routes/app_router.dart';
import '../bloc/dashboard_bloc.dart';
import '../../../wallet/presentation/bloc/wallet_bloc.dart';
import '../../../wallet/presentation/bloc/wallet_event.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/campaign_summary.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../shared/presentation/widgets/currency_toggle_switch.dart';
import '../../../tutorials/presentation/buyer_tutorials_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late PageController _carouselController;
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;
  String _selectedCategory = 'Play Store';

  final List<Map<String, dynamic>> _carouselSlides = [
    {
      'badge': '⭐ TOP RATED • GOOGLE PLAY',
      'title': 'Dominate Google Play Store',
      'highlight': '5-Star Ratings & Reviews',
      'description':
          'Rank #1 on search keywords with genuine user downloads & authentic reviews from verified Android devices.',
      'gradientColors': [
        const Color(0xFF0F172A),
        const Color(0xFF0284C7),
        const Color(0xFF0D9488)
      ],
      'accentColor': const Color(0xFF38BDF8),
      'buttonText': 'Boost Play Store →',
      'platform': 'playstore',
      'route': AppRouter.services,
    },
    {
      'badge': '📍 LOCAL SEO • GOOGLE MAPS',
      'title': 'Dominate Google Maps & GMB',
      'highlight': '5-Star Ratings & Reviews',
      'description':
          'Boost your local business ranking on Google Maps & Search with authentic 5-star ratings & verified customer reviews.',
      'gradientColors': [
        const Color(0xFF0F172A),
        const Color(0xFF1D4ED8),
        const Color(0xFF2563EB)
      ],
      'accentColor': const Color(0xFF60A5FA),
      'buttonText': 'Boost Google Maps →',
      'platform': 'google_maps',
      'route': AppRouter.services,
    },
    {
      'badge': '🚀 VIRAL ENGINE • YOUTUBE',
      'title': 'Ignite YouTube Algorithm',
      'highlight': 'High Retention & Discussions',
      'description':
          'Real video watch time, organic likes & intelligent niche-relevant comments that push videos to recommendations.',
      'gradientColors': [
        const Color(0xFF1E1B4B),
        const Color(0xFF991B1B),
        const Color(0xFFBE123C)
      ],
      'accentColor': const Color(0xFFFB7185),
      'buttonText': 'Supercharge Video →',
      'platform': 'youtube',
      'route': AppRouter.services,
    },
    {
      'badge': '🔥 VIRAL REACH • INSTAGRAM',
      'title': 'Explode Instagram Reach',
      'highlight': 'Followers, Likes & Comments',
      'description':
          'Boost your Instagram reels, posts & profile with verified followers, instant likes & custom comments.',
      'gradientColors': [
        const Color(0xFF831843),
        const Color(0xFFBE185D),
        const Color(0xFFDB2777)
      ],
      'accentColor': const Color(0xFFF472B6),
      'buttonText': 'Boost Instagram →',
      'platform': 'instagram',
      'route': AppRouter.services,
    },
    {
      'badge': '🛡️ ZERO BOTS • 100% REAL',
      'title': '10,000+ Verified Workers',
      'highlight': 'Real Hardware & Screenshots',
      'description':
          'Every task is completed by real Indian users on active smartphones with rigorous screenshot proof auditing.',
      'gradientColors': [
        const Color(0xFF064E3B),
        const Color(0xFF047857),
        const Color(0xFF0F766E)
      ],
      'accentColor': const Color(0xFF34D399),
      'buttonText': 'Launch Campaign →',
      'platform': 'verify',
      'route': AppRouter.createCampaign,
    },
    {
      'badge': '⚡ MASSIVE SCALE • RAPID DISPATCH',
      'title': 'Scale to 10,000 Tasks',
      'highlight': 'Instant Automated Allocation',
      'description':
          'Deploy high-volume campaigns in 60 seconds with live real-time progress analytics and escrow safety.',
      'gradientColors': [
        const Color(0xFF312E81),
        const Color(0xFF4338CA),
        const Color(0xFF6D28D9)
      ],
      'accentColor': const Color(0xFFA78BFA),
      'buttonText': 'Create Custom Order →',
      'platform': 'scale',
      'route': AppRouter.createCampaign,
    },
  ];

  final ServiceRepositoryImpl _serviceRepository = ServiceRepositoryImpl();
  List<ServiceModel> _liveServices = [];
  Timer? _serviceRefreshTimer;
  bool _refreshingServices = false;

  List<Map<String, dynamic>> get _serviceCatalog => _liveServices.map((service) {
    final identity = '${service.code} ${service.category}'.toUpperCase();
    var category = service.category;
    var icon = 'app_install';
    var color = const Color(0xFF0284C7);
    if (identity.contains('GOOGLE_BUSINESS') || identity.contains('GMB') || identity.contains('MAP')) {
      category = 'Google Maps';
      icon = 'google_maps';
      color = const Color(0xFF2563EB);
    } else if (identity.contains('INSTA') && !identity.contains('INSTALL')) {
      category = 'Instagram';
      icon = 'insta_combo';
      color = const Color(0xFFEC4899);
    } else if (identity.contains('YOUTUBE') || identity.contains('YT_')) {
      category = 'YouTube';
      icon = 'youtube_combo';
      color = const Color(0xFFEF4444);
    } else if (identity.contains('INSTALL') || identity.contains('MOBILE APP')) {
      category = 'Mobile Apps';
    } else if (identity.contains('PLAY') || identity.contains('RATING') || identity.contains('REVIEW')) {
      category = 'Play Store';
      icon = 'playstore';
      color = const Color(0xFF10B981);
    }
    return <String, dynamic>{
      'id': service.id,
      'category': category,
      'title': service.name,
      'tag': 'AVAILABLE',
      'tagColor': color,
      'description': service.description,
      'price': CurrencyService.instance.formatPrice(service.pricing.buyerPrice),
      'gradient': <Color>[color, color],
      'iconType': icon,
      'features': <String>[],
      'route': AppRouter.services,
    };
  }).toList();

  Future<void> _refreshServiceCatalog() async {
    if (_refreshingServices) return;
    _refreshingServices = true;
    try {
      final services = await _serviceRepository.getPublishedServices();
      if (!mounted) return;
      setState(() {
        _liveServices = services;
        final categories = _serviceCatalog.map((s) => s['category'] as String).toSet();
        if (categories.isNotEmpty && !categories.contains(_selectedCategory)) {
          _selectedCategory = categories.first;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _liveServices = []);
    } finally {
      _refreshingServices = false;
    }
  }

  void _startServiceRefresh() {
    _serviceRefreshTimer?.cancel();
    _serviceRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshServiceCatalog());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshServiceCatalog();
      _startServiceRefresh();
    } else {
      _serviceRefreshTimer?.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _carouselController = PageController(viewportFraction: 0.94);
    _startCarouselTimer();
    WidgetsBinding.instance.addObserver(this);
    _refreshServiceCatalog();
    _startServiceRefresh();
    context.read<WalletBloc>().add(const GetBalanceEvent());
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
    WidgetsBinding.instance.removeObserver(this);
    _serviceRefreshTimer?.cancel();
    _carouselTimer?.cancel();
    _carouselController.dispose();
    _fadeController.dispose();
    super.dispose();
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
                    context.read<WalletBloc>().add(const RefreshWalletEvent());
                    context.read<DashboardBloc>().add(LoadDashboardDataEvent());
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
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

                      // Bottom safe area padding
                      SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 80),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          children: [
            // 1st: Currency Switch Pill (₹ INR / $ USD)
            const CurrencyToggleSwitch(compact: true),
            const SizedBox(width: 8),

            // 2nd: Animated YouTube Tutorial Icon linked to Tutorials Page
            _AnimatedYouTubeTutorialButton(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BuyerTutorialsPage(),
                ),
              ),
            ),
            const Spacer(),

            // Live Support Chat Action with Animated Lottie Customer Care (No outline, increased size, with 'Chat Support' text)
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRouter.chat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 38,
                      child: OverflowBox(
                        maxWidth: 64,
                        maxHeight: 64,
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: const Offset(-2, -4),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: Lottie.asset(
                              'assets/animations/customercare.json',
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Live',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF10B981),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        _BlinkingChatText(
                          text: 'Chat Support',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Notification Center with Glow
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.notifications),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.notifications_none_rounded,
                        color: Colors.white, size: 20),
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
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.8),
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
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.18), width: 1.2),
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
              child:
                  _build3DPlatformIllustration(slide['platform'], accentColor),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: accentColor.withValues(alpha: 0.5)),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
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
    if (platform == 'google_business' || platform == 'google_maps') {
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
            Image.asset(
              'assets/icons/google-maps.png',
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('MAPS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      );
    }

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
            Image.asset(
              'assets/icons/google-play.png',
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('5★',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900)),
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
        child: Center(
          child: Image.asset(
            'assets/icons/youtube.png',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    if (platform == 'instagram') {
      return Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Image.asset(
            'assets/icons/instagram.png',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    if (platform == 'app_install' || platform == 'apps' || platform == 'mobile_apps') {
      return Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Image.asset(
            'assets/icons/app_install.png',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/images/social_growth_3d.jpg',
            width: 86,
            height: 86,
            fit: BoxFit.cover,
          ),
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
      child: Center(
        child: Image.asset(
          'assets/icons/marketing.png',
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        ),
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
          border: Border.all(
              color: const Color(0xFF334155).withValues(alpha: 0.7),
              width: 1.2),
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
                              color: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'assets/icons/wallet.png',
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                            ),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded,
                                color: Color(0xFF34D399), size: 12),
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
                            ValueListenableBuilder<String>(
                              valueListenable: CurrencyService.instance.currencyNotifier,
                              builder: (context, _, __) {
                                return Text(
                                  CurrencyService.instance.formatPrice(d.totalSpend.toDouble(), showDecimals: CurrencyService.instance.isUSD),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total Campaign Budget Allocated',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  'Available Escrow: ',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₹${d.walletBalance.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF34D399),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Glowing 3D Launch Button
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, AppRouter.services),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.45),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 18),
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
                  Container(
                      height: 1, color: Colors.white.withValues(alpha: 0.07)),
                  const SizedBox(height: 14),

                  // 3 Key Stats Pills (No complicated graphs)
                  Row(
                    children: [
                      _buildMetricBox(
                          'Active',
                          '${d.activeCampaigns}',
                          const Color(0xFF10B981),
                          'assets/icons/marketing.png'),
                      const SizedBox(width: 8),
                      _buildMetricBox('Completed', '${d.completedCampaigns}',
                          const Color(0xFF6366F1), 'assets/icons/rating.png'),
                      const SizedBox(width: 8),
                      _buildMetricBox('Units Done', '${d.completedTasks}',
                          const Color(0xFFF59E0B), 'assets/icons/star.png'),
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

  Widget _buildMetricBox(
      String label, String val, Color color, String assetPath) {
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
            Image.asset(assetPath, width: 16, height: 16, fit: BoxFit.contain),
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
    final filteredServices = _serviceCatalog
        .where((s) => s['category'] == _selectedCategory)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
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
                  'Choose marketing category to deploy instantly',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
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
              ..._serviceCatalog.map((s) => s['category'] as String).toSet().map(_buildCategoryChip),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Service Cards List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              if (filteredServices.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No services are available right now.', style: TextStyle(color: Colors.white70)),
                ),
              ...filteredServices.map((service) => _build3DServiceCard(context, service)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String title) {
    final isSelected = _selectedCategory == title;
    final Widget chipIcon;
    if (title == 'Play Store') {
      chipIcon = Image.asset('assets/icons/google-play.png',
          width: 14, height: 14, fit: BoxFit.contain);
    } else if (title == 'Google Maps' || title.contains('Map')) {
      chipIcon = Image.asset('assets/icons/google-maps.png',
          width: 14, height: 14, fit: BoxFit.contain);
    } else if (title == 'YouTube') {
      chipIcon = Image.asset('assets/icons/youtube.png',
          width: 14, height: 14, fit: BoxFit.contain);
    } else if (title == 'Instagram') {
      chipIcon = Image.asset('assets/icons/instagram.png',
          width: 14, height: 14, fit: BoxFit.contain);
    } else if (title == 'Mobile Apps' ||
        title == 'App Install & Review' ||
        title.contains('Install') ||
        title.contains('App')) {
      chipIcon = Image.asset('assets/icons/app_install.png',
          width: 14, height: 14, fit: BoxFit.contain);
    } else {
      chipIcon = Icon(Icons.auto_awesome_rounded,
          size: 13,
          color:
              isSelected ? const Color(0xFF0F172A) : const Color(0xFF38BDF8));
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = title);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            chipIcon,
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: isSelected ? const Color(0xFF0F172A) : Colors.white70,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DServiceCard(BuildContext context, Map<String, dynamic> s) {
    final List<Color> gradient = s['gradient'];
    final Color tagColor = s['tagColor'];
    final String iconType = s['iconType'] as String;

    // ── Unique visual identity per service category ──
    final cardThemes = <String, Map<String, dynamic>>{
      'google_business': {
        'bg': const [Color(0xFF081A3A), Color(0xFF0C2754), Color(0xFF103672)],
        'glow': const Color(0xFF3B82F6),
        'emoji': '📍',
      },
      'google_maps': {
        'bg': const [Color(0xFF081A3A), Color(0xFF0C2754), Color(0xFF103672)],
        'glow': const Color(0xFF3B82F6),
        'emoji': '📍',
      },
      'playstore': {
        'bg': const [Color(0xFF061F16), Color(0xFF0A3024), Color(0xFF0E3F30)],
        'glow': const Color(0xFF10B981),
        'emoji': '⭐',
      },
      'insta_combo': {
        'bg': const [Color(0xFF280816), Color(0xFF3D0C22), Color(0xFF50102D)],
        'glow': const Color(0xFFEC4899),
        'emoji': '📸',
      },
      'youtube_combo': {
        'bg': const [Color(0xFF250808), Color(0xFF3B0D0D), Color(0xFF4E1212)],
        'glow': const Color(0xFFEF4444),
        'emoji': '🚀',
      },
      'youtube_comment': {
        'bg': const [Color(0xFF200A0A), Color(0xFF331414), Color(0xFF401A1A)],
        'glow': const Color(0xFFEF4444),
        'emoji': '💬',
      },
      'insta_follow': {
        'bg': const [Color(0xFF200612), Color(0xFF32091D), Color(0xFF420C26)],
        'glow': const Color(0xFFF43F5E),
        'emoji': '✨',
      },
      'youtube_sub': {
        'bg': const [Color(0xFF150B30), Color(0xFF1F1248), Color(0xFF281858)],
        'glow': const Color(0xFF8B5CF6),
        'emoji': '👍',
      },
      'app_install': {
        'bg': const [Color(0xFF081A28), Color(0xFF0C2840), Color(0xFF103552)],
        'glow': const Color(0xFF0EA5E9),
        'emoji': '📲',
      },
    };
    final theme = cardThemes[iconType] ??
        {
          'bg': const [Color(0xFF0F172A), Color(0xFF1E293B)],
          'glow': const Color(0xFF38BDF8),
          'emoji': '🚀',
        };
    final cardBg = theme['bg'] as List<Color>;
    final glowColor = theme['glow'] as Color;
    final cartoonEmoji = theme['emoji'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cardBg,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: glowColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Glowing accent top edge with category color ──
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    glowColor.withValues(alpha: 0.7),
                    gradient.first.withValues(alpha: 0.8),
                    glowColor.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Large floating cartoon emoji (background watermark) ──
          Positioned(
            right: -8,
            top: -12,
            child: Text(
              cartoonEmoji,
              style: TextStyle(
                fontSize: 100,
                color: Colors.white.withValues(alpha: 0.045),
              ),
            ),
          ),

          // ── Floating ambient glow sphere ──
          Positioned(
            right: 30,
            bottom: 50,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glowColor.withValues(alpha: 0.12),
                    glowColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Small decorative ring ──
          Positioned(
            left: -20,
            bottom: 10,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: glowColor.withValues(alpha: 0.08), width: 1.5),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: 3D Platform Icon + Tag & Price & Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3D Layered Platform Icon
                    _buildService3DIcon(s['iconType'], gradient),
                    const SizedBox(width: 14),

                    // Title & Category & Price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tagColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: tagColor.withValues(alpha: 0.4),
                                        width: 0.8),
                                  ),
                                  child: Text(
                                    s['tag'],
                                    style: GoogleFonts.outfit(
                                      color: tagColor,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ValueListenableBuilder<String>(
                                  valueListenable: CurrencyService.instance.currencyNotifier,
                                  builder: (context, _, __) {
                                    String formattedPrice = s['price'];
                                    final match = RegExp(r'₹([0-9.]+)\s*/\s*([a-zA-Z_]+)').firstMatch(s['price']);
                                    if (match != null) {
                                      final amount = double.tryParse(match.group(1)!) ?? 0.0;
                                      final u = match.group(2)!;
                                      formattedPrice = 'From ${CurrencyService.instance.formatRateWithUnit(amount, u)}';
                                    }
                                    return Text(
                                      formattedPrice,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF34D399),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10.5,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s['title'],
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ],
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
                  runSpacing: 6,
                  children: (s['features'] as List<String>).map((feat) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: glowColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: glowColor.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: glowColor, size: 11),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              feat,
                              style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
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
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 15),
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
    Widget iconWidget;
    String miniLabel = '';

    switch (iconType) {
      case 'google_business':
      case 'google_maps':
        iconWidget = Image.asset(
          'assets/icons/google-maps.png',
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        );
        miniLabel = 'MAPS';
        break;
      case 'playstore':
        iconWidget = Image.asset(
          'assets/icons/google-play.png',
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        );
        miniLabel = '5★';
        break;
      case 'insta_combo':
        iconWidget = Image.asset(
          'assets/icons/instagram.png',
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        );
        miniLabel = 'COMBO';
        break;
      case 'youtube_combo':
        iconWidget = Image.asset(
          'assets/icons/marketing.png',
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        );
        miniLabel = 'COMBO';
        break;
      case 'insta_follow':
        iconWidget = Image.asset(
          'assets/icons/instagram.png',
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        );
        miniLabel = '+1k';
        break;
      case 'youtube_comment':
        iconWidget = Image.asset(
          'assets/icons/comment.png',
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        );
        miniLabel = 'CMT';
        break;
      case 'youtube_sub':
        iconWidget = Image.asset(
          'assets/icons/youtube.png',
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        );
        miniLabel = 'SUB';
        break;
      case 'app_install':
        iconWidget = Image.asset(
          'assets/icons/app_install.png',
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        );
        miniLabel = 'APP';
        break;
      default:
        iconWidget = Image.asset(
          'assets/icons/marketing.png',
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        );
        miniLabel = 'PRO';
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.55),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          iconWidget,
          if (miniLabel.isNotEmpty)
            Positioned(
              top: 3,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 0.5),
                ),
                child: Text(
                  miniLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. RECENT CAMPAIGNS LIVE MONITOR
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildRecentCampaignsSection(
      BuildContext context, List<CampaignSummary> campaigns) {
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

          // Campaigns List (Latest campaigns on top)
          ...(() {
            final sorted = List<CampaignSummary>.from(campaigns)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return sorted.take(3);
          })().map((c) {
            final progress =
                c.totalTasks > 0 ? c.completedTasks / c.totalTasks : 0.0;
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.15),
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
                            valueColor:
                                const AlwaysStoppedAnimation(Color(0xFF38BDF8)),
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
                iconAsset: 'assets/icons/review.png',
                title: 'Screenshot Audits',
                desc: 'Every single task submitted with high-res photo proof',
                color: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 10),
              _buildTrustCard(
                iconAsset: 'assets/icons/star.png',
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
                iconAsset: 'assets/icons/marketing.png',
                title: '60s Instant Dispatch',
                desc: 'Automated queue sends orders to active micro-workers',
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 10),
              _buildTrustCard(
                iconAsset: 'assets/icons/mobile-chatting.png',
                title: '24/7 Live Support',
                desc: 'Instant 1-on-1 chat support desk for all campaigns',
                color: const Color(0xFFA855F7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustCard({
    required String iconAsset,
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
              child: Image.asset(
                iconAsset,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
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
              child: const Icon(Icons.wifi_off_rounded,
                  size: 36, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<DashboardBloc>().add(LoadDashboardDataEvent()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry Connection',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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

// ─────────────────────────────────────────────────────────────────────────────
// BLINKING CHAT SUPPORT TEXT WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _BlinkingChatText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _BlinkingChatText({
    required this.text,
    required this.style,
  });

  @override
  State<_BlinkingChatText> createState() => _BlinkingChatTextState();
}

class _BlinkingChatTextState extends State<_BlinkingChatText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }
}

class _AnimatedYouTubeTutorialButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedYouTubeTutorialButton({
    required this.onTap,
  });

  @override
  State<_AnimatedYouTubeTutorialButton> createState() =>
      _AnimatedYouTubeTutorialButtonState();
}

class _AnimatedYouTubeTutorialButtonState
    extends State<_AnimatedYouTubeTutorialButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.10).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Tooltip(
          message: 'Tutorials & Guides',
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF0000)
                      .withValues(alpha: _glowAnimation.value),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF0000)
                        .withValues(alpha: _glowAnimation.value * 0.45),
                    blurRadius: 8 + 4 * _controller.value,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Image.asset(
                      'assets/icons/youtube.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Color(0xFFFF0000),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

