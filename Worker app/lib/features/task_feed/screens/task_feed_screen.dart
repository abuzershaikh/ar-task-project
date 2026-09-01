import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../shared/widgets/platform_logo.dart';
import '../../task_detail/screens/task_detail_premium_screen.dart';
import '../../profile/screens/day_streak_screen.dart';
import '../../profile/screens/quality_score_screen.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../../notifications/screens/notification_history_screen.dart';
import '../../../core/services/api_service.dart';
import '../widgets/task_feed_card.dart';

/// Task Feed Screen with Multi-Slide Top Hero Banner:
/// - Top Dark Forest Emerald Gradient Hero Banner with edge-to-edge status bar
/// - Multi-Slide Animated Banner Carousel (Complete Tasks, Daily Streak, Instant Payouts, VIP Quality Score)
/// - 3D Lottie Animations (3D Treasure Box & Coin Bar) with floating badges
/// - Real backend tasks only (no demo tasks)
/// - Platform filter chips (All Tasks, Google, YouTube, Facebook, Instagram, More)
class TaskFeedScreen extends StatefulWidget {
  const TaskFeedScreen({super.key});

  @override
  State<TaskFeedScreen> createState() => _TaskFeedScreenState();
}

class _TaskFeedScreenState extends State<TaskFeedScreen> with WidgetsBindingObserver {
  String _selectedPlatform = 'All Tasks';
  Timer? _autoRefreshTimer;
  int _unreadNotifCount = 0;

  // Banner Carousel controller and auto-scroll timer
  late final PageController _bannerController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  static const int _totalBannerSlides = 4;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    WidgetsBinding.instance.addObserver(this);

    _startBannerAutoPlay();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFeed();
      _loadUnreadNotifCount();
      _startAutoRefreshTimer();
    });
  }

  Future<void> _loadUnreadNotifCount() async {
    try {
      final count = await ApiService.getUnreadNotificationCount();
      if (mounted) setState(() => _unreadNotifCount = count);
    } catch (_) {}
  }

  void _startBannerAutoPlay() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(milliseconds: 4500), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final nextPage = (_currentBannerIndex + 1) % _totalBannerSlides;
      _bannerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshFeed();
      _startAutoRefreshTimer();
      _startBannerAutoPlay();
    } else if (state == AppLifecycleState.paused) {
      _autoRefreshTimer?.cancel();
      _bannerTimer?.cancel();
    }
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        taskProvider.fetchAvailableTasks(silent: true);
        taskProvider.fetchWalletData();
      }
    });
  }

  void _refreshFeed() {
    if (!mounted) return;
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.fetchAvailableTasks();
    taskProvider.fetchWalletData();
  }

  String _detectPlatform(dynamic task) {
    if (task == null) return 'general';
    if (task['platform'] != null && task['platform'].toString().trim().isNotEmpty) {
      return task['platform'].toString().toLowerCase().trim();
    }
    final type = (task['taskType'] ?? task['type'] ?? task['serviceCode'] ?? '').toString().toLowerCase();
    String reqStr = '';
    if (task['requirements'] is Map) {
      reqStr = task['requirements'].toString().toLowerCase();
    }
    final metaStr = (task['metadata'] != null) ? task['metadata'].toString().toLowerCase() : '';
    final combined = '$type $reqStr $metaStr';
    if (combined.contains('youtube') || combined.contains('yt_')) return 'youtube';
    if (combined.contains('instagram') || combined.contains('insta')) return 'instagram';
    if (combined.contains('facebook') || combined.contains('fb')) return 'facebook';
    if (combined.contains('google') || combined.contains('maps') || combined.contains('playstore')) return 'google';
    if (combined.contains('twitter') || combined.contains(' x ') || combined.contains('x.com')) return 'x';
    if (combined.contains('telegram')) return 'telegram';
    return 'youtube';
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    // Only real tasks from provider (demo tasks removed completely)
    final tasksToDisplay = taskProvider.availableTasks;

    final wallet = taskProvider.walletData;
    double walletBalance = 0.0;
    final rawBal = wallet['balance'] ?? wallet['availableBalance'];
    if (rawBal is num) {
      walletBalance = rawBal.toDouble();
    } else if (rawBal != null) {
      walletBalance = double.tryParse(rawBal.toString()) ?? 0.0;
    }

    final filteredTasks = _selectedPlatform == 'All Tasks'
        ? tasksToDisplay
        : tasksToDisplay.where((t) {
            final p = _detectPlatform(t);
            final sel = _selectedPlatform.toLowerCase();
            return p.contains(sel) || t.toString().toLowerCase().contains(sel);
          }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF00875A),
          onRefresh: () async {
            await taskProvider.fetchAvailableTasks();
            await taskProvider.fetchWalletData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Top Emerald Multi-Slide Hero Banner (Edge-to-edge) ────
                _buildHeroBanner(context, walletBalance),
                const SizedBox(height: 16),

                // ── 2. Platform Filter Chips ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildPlatformChips(),
                ),
                const SizedBox(height: 18),

                // ── 3. Section Header ("Available Tasks" + Refresh) ──────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Tasks',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0F172A),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.1,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          taskProvider.fetchAvailableTasks();
                          taskProvider.fetchWalletData();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                'Refresh',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF00875A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.refresh_rounded,
                                size: 15,
                                color: Color(0xFF00875A),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── 4. Task Feed Cards List (Real Backend Tasks Only) ────────
                if (taskProvider.isLoading && tasksToDisplay.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF00875A)),
                    ),
                  )
                else if (filteredTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 24),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F4EA),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.task_alt_rounded,
                                size: 34,
                                color: Color(0xFF00875A),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _selectedPlatform == 'All Tasks'
                                  ? 'No Tasks Available Right Now'
                                  : 'No Tasks Found for $_selectedPlatform',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.5,
                                color: const Color(0xFF0F172A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'New campaigns are added continuously by buyers. Pull down or tap Refresh below to check for new tasks.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00875A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(
                                'Refresh Tasks',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () {
                                taskProvider.fetchAvailableTasks();
                                taskProvider.fetchWalletData();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return TaskFeedCard(
                          task: task,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TaskDetailPremiumScreen(task: task),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Forest Emerald Multi-Slide Hero Banner ─────────────────────────────
  Widget _buildHeroBanner(BuildContext context, double walletBalance) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF011F11),
            Color(0xFF03351C),
            Color(0xFF044827),
            Color(0xFF022714),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3300875A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Sparkles & Glows
          Positioned.fill(
            child: CustomPaint(
              painter: _SparkleBackgroundPainter(),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(18, topPadding + 10, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Bar: Task Feed Title + Notification & Wallet ─────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Title: Task Feed
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Task ',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          TextSpan(
                            text: 'Feed',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF22C55E),
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Icons: Notification Bell + Wallet Pill
                    Row(
                      children: [
                        // Notification Bell with dynamic unread badge
                        InkWell(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationHistoryScreen(),
                              ),
                            );
                            _loadUnreadNotifCount();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Color(0xFF1E293B),
                                  size: 20,
                                ),
                              ),
                              if (_unreadNotifCount > 0)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      _unreadNotifCount > 9 ? '9+' : '$_unreadNotifCount',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Wallet Pill Container
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const WalletScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F4EA),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Color(0xFF00875A),
                                    size: 13,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '₹${walletBalance.toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF0F172A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Hero Banner Carousel (Swipeable & Auto-play) ─────────────
                SizedBox(
                  height: 155,
                  child: PageView(
                    controller: _bannerController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentBannerIndex = index;
                      });
                    },
                    children: [
                      // Slide 1: Complete Tasks & Earn Rewards (Treasure Box + Platform Badges)
                      _buildSlideOne(context),

                      // Slide 2: Daily Streak Bonus Multiplier (Coin Bar + Fire & Streak)
                      _buildSlideTwo(context),

                      // Slide 3: Instant Withdrawal Payouts (Bank/UPI/PayPal)
                      _buildSlideThree(context),

                      // Slide 4: High Quality Score & VIP Campaigns
                      _buildSlideFour(context),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Carousel Active Indicator Dots ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_totalBannerSlides, (index) {
                    final isActive = _currentBannerIndex == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: isActive ? 18 : 5,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Slide 1: Complete Tasks & Earn Rewards ─────────────────────────────────
  Widget _buildSlideOne(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Complete Tasks',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Earn Daily Rewards',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF4ADE80),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Complete social tasks & earn instant cash',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 9.5,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start Earning',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF03351C),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF03351C),
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: -10,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: Lottie.asset(
                    'assets/animations/treasure_box.json',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 54);
                    },
                  ),
                ),
              ),
              Positioned(
                top: 2,
                left: 30,
                child: _buildFloatingBadge(
                  child: const PlatformLogo(platform: 'youtube', size: 28),
                ),
              ),
              Positioned(
                top: 14,
                right: 12,
                child: _buildFloatingBadge(
                  child: const PlatformLogo(platform: 'instagram', size: 28),
                ),
              ),
              Positioned(
                top: 50,
                left: 4,
                child: _buildFloatingBadge(
                  child: const PlatformLogo(platform: 'google', size: 26),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 20,
                child: _buildFloatingBadge(
                  child: const PlatformLogo(platform: 'facebook', size: 28),
                ),
              ),
              Positioned(
                bottom: 18,
                right: 8,
                child: _buildFloatingBadge(
                  child: const PlatformLogo(platform: 'x', size: 26),
                ),
              ),
              Positioned(top: 18, left: 0, child: _buildGoldenCoin(14)),
              Positioned(top: 4, right: 48, child: _buildGoldenCoin(10)),
              Positioned(bottom: 30, left: 56, child: _buildGoldenCoin(12)),
              Positioned(bottom: 6, right: 40, child: _buildGoldenCoin(14)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Slide 2: Daily Streak Bonus Multiplier ─────────────────────────────────
  Widget _buildSlideTwo(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Daily Streak',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Up to 2X Bonus',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFBBF24),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '7-day active streak unlocks cash multiplier',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 9.5,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DayStreakScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Streak',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: -10,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFBBF24),
                        Color(0xFFEA580C),
                        Color(0xFF9A3412),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFBBF24), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '7-DAY STREAK',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFDE68A),
                          fontWeight: FontWeight.bold,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(top: 14, left: 10, child: _buildGoldenCoin(14)),
              Positioned(bottom: 24, right: 14, child: _buildGoldenCoin(12)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Slide 3: Instant Withdrawal Payouts ────────────────────────────────────
  Widget _buildSlideThree(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Instant Payouts',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Direct to Bank / UPI',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF38BDF8),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Withdraw earnings to UPI, Bank & PayPal',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 9.5,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WalletScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Open Wallet',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: -10,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Lottie.asset(
                    'assets/animations/treasure_box.json',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF38BDF8), size: 54);
                    },
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 18,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF38BDF8)),
                  ),
                  child: Text(
                    'UPI • Bank • PayPal',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 9.5,
                    ),
                  ),
                ),
              ),
              Positioned(top: 20, left: 14, child: _buildGoldenCoin(13)),
              Positioned(bottom: 26, right: 18, child: _buildGoldenCoin(11)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Slide 4: High Quality Score & VIP Campaigns ────────────────────────────
  Widget _buildSlideFour(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Quality Score',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'VIP Tasks Access',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFC084FC),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'High accuracy score unlocks premium tasks',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 9.5,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QualityScoreScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9333EA),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Check Score',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: -10,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFD8B4FE),
                        Color(0xFF9333EA),
                        Color(0xFF581C87),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 22,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                ),
              ),
              Positioned(
                bottom: 14,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC084FC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFFD8B4FE), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '98.5% QUALITY SCORE',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFE9D5FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 9.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(top: 22, left: 16, child: _buildGoldenCoin(12)),
              Positioned(bottom: 28, right: 12, child: _buildGoldenCoin(13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingBadge({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildGoldenCoin(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFFFFF7B2),
            Color(0xFFFFD700),
            Color(0xFFD97706),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '₹',
          style: TextStyle(
            color: const Color(0xFF78350F),
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ── Platform Filter Horizontal Chips ───────────────────────────────────────
  Widget _buildPlatformChips() {
    final chips = [
      {'label': 'All Tasks', 'icon': Icons.grid_view_rounded, 'key': 'All Tasks'},
      {'label': 'Google', 'logo': 'google', 'key': 'Google'},
      {'label': 'YouTube', 'logo': 'youtube', 'key': 'YouTube'},
      {'label': 'Facebook', 'logo': 'facebook', 'key': 'Facebook'},
      {'label': 'Instagram', 'logo': 'instagram', 'key': 'Instagram'},
      {'label': 'More', 'icon': Icons.more_horiz_rounded, 'key': 'More'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: chips.map((c) {
          final isSelected = _selectedPlatform == c['key'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPlatform = c['key'] as String;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00875A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00875A)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    if (c['icon'] != null)
                      Icon(
                        c['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : const Color(0xFF00875A),
                      )
                    else if (c['logo'] != null)
                      PlatformLogo(platform: c['logo'] as String, size: 17),
                    const SizedBox(width: 6),
                    Text(
                      c['label'] as String,
                      style: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Custom painter to draw subtle golden/green sparkle stars across the banner
class _SparkleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sparklePaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // Glowing orbs in background
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.4), 60, glowPaint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.7), 40, glowPaint);

    // Small star sparkles
    _drawStar(canvas, Offset(size.width * 0.12, size.height * 0.25), 4, sparklePaint);
    _drawStar(canvas, Offset(size.width * 0.48, size.height * 0.18), 5, sparklePaint);
    _drawStar(canvas, Offset(size.width * 0.62, size.height * 0.6), 3.5, sparklePaint);
    _drawStar(canvas, Offset(size.width * 0.92, size.height * 0.35), 4, sparklePaint);
    _drawStar(canvas, Offset(size.width * 0.38, size.height * 0.82), 3, sparklePaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
