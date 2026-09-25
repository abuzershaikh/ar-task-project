import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import '../../../core/providers/task_provider.dart';
import '../../../shared/widgets/platform_logo.dart';
import '../../task_detail/screens/task_detail_premium_screen.dart';
import '../../profile/screens/day_streak_screen.dart';
import '../../profile/screens/quality_score_screen.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../../notifications/screens/notification_history_screen.dart';
import '../../support_chat/screens/worker_support_chat_screen.dart';
import '../../support_chat/services/worker_chat_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/profile_provider.dart';
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

class _TaskFeedScreenState extends State<TaskFeedScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  String _selectedPlatform = 'All Tasks';
  Timer? _autoRefreshTimer;
  int _unreadNotifCount = 0;

  // Support chat real-time alert state
  int _supportUnreadCount = 0;
  StreamSubscription? _supportMsgSub;
  StreamSubscription? _supportUnreadSub;
  StreamSubscription? _supportDeletedSub;
  AudioPlayer? _supportAudioPlayer;

  // Rotating glowing neon light ring around support icon
  late final AnimationController _lightRotateController;

  // Shake / vibrate wobble animation on incoming message
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // Banner Carousel controller and auto-scroll timer
  late final PageController _bannerController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  static const int _totalBannerSlides = 3;

  // Floating golden coin animation in hero banner
  late final AnimationController _floatingCoinController;
  late final Animation<double> _floatingCoinAnimation;

  // Refresh icon rotation controller
  late final AnimationController _refreshSpinController;

  // Real animated falling rain controller and particles
  late final AnimationController _rainController;
  late final List<_RainDropData> _rainDrops;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    WidgetsBinding.instance.addObserver(this);

    // Continuous smooth falling rain animation (60 FPS)
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat();

    final rand = math.Random(1337);
    _rainDrops = List.generate(85, (index) {
      final isForeground = index % 3 == 0;
      return _RainDropData(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        speed: isForeground ? (1.35 + rand.nextDouble() * 0.75) : (0.75 + rand.nextDouble() * 0.45),
        length: isForeground ? (20.0 + rand.nextDouble() * 12.0) : (11.0 + rand.nextDouble() * 7.0),
        thickness: isForeground ? 1.3 : 0.85,
        alpha: isForeground ? 0.32 : 0.16,
        hasSplash: rand.nextDouble() > 0.45,
      );
    });

    // Rotating light around support icon (continuous smooth rotation)
    _lightRotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Floating golden coins animation in hero banner
    _floatingCoinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatingCoinAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _floatingCoinController, curve: Curves.easeInOut),
    );

    // Refresh icon spin controller
    _refreshSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Shake / vibrate wobble animation when message arrives
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -0.16), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -0.16, end: 0.16), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 0.16, end: -0.12), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -0.12, end: 0.12), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 0.12, end: -0.06), weight: 1.5),
      TweenSequenceItem(tween: Tween<double>(begin: -0.06, end: 0.0), weight: 1.5),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    _startBannerAutoPlay();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFeed();
      _loadUnreadNotifCount();
      _startAutoRefreshTimer();
      _initSupportChatListener();
    });
  }

  Future<void> _refreshFeed() async {
    if (!mounted) return;
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await Future.wait([
      taskProvider.fetchAvailableTasks(),
      taskProvider.fetchWalletData(),
      _loadUnreadNotifCount(),
    ]);
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _refreshFeed();
      }
    });
  }

  void _initSupportChatListener() {
    try {
      _supportAudioPlayer = AudioPlayer();
    } catch (_) {}

    WorkerChatService.instance.initSocket();
    _loadSupportUnreadCount();

    _supportMsgSub?.cancel();
    _supportMsgSub = WorkerChatService.instance.onNewMessage.listen((msg) {
      if (msg.senderType == 'ADMIN' && mounted) {
        final isCurrentTab = ModalRoute.of(context)?.isCurrent ?? true;
        if (isCurrentTab) {
          setState(() {
            _supportUnreadCount++;
          });
          _triggerMessageAlert();
        }
      }
    });

    _supportUnreadSub?.cancel();
    _supportUnreadSub = WorkerChatService.instance.onUnreadCountChanged.listen((count) {
      if (mounted && count != _supportUnreadCount) {
        final bool hadLess = count > _supportUnreadCount;
        setState(() => _supportUnreadCount = count);
        if (hadLess) {
          _triggerMessageAlert();
        }
      }
    });

    _supportDeletedSub?.cancel();
    _supportDeletedSub = WorkerChatService.instance.onAllMessagesDeleted.listen((_) {
      if (mounted) {
        setState(() => _supportUnreadCount = 0);
      }
    });
  }

  Future<void> _loadSupportUnreadCount() async {
    try {
      final count = await WorkerChatService.instance.fetchUnreadCount();
      if (mounted) {
        setState(() => _supportUnreadCount = count);
      }
    } catch (_) {}
  }

  void _triggerMessageAlert() {
    // 1. Physical vibration
    try {
      HapticFeedback.vibrate();
      Future.delayed(const Duration(milliseconds: 140), () => HapticFeedback.heavyImpact());
      Future.delayed(const Duration(milliseconds: 280), () => HapticFeedback.mediumImpact());
    } catch (_) {}

    // 2. Play notification sound (native alert + audio chime)
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
    try {
      _supportAudioPlayer?.stop();
      _supportAudioPlayer?.play(AssetSource('audio/support_ping.wav'), volume: 1.0);
    } catch (_) {}

    // 3. Visual icon shake / vibrate
    if (mounted) {
      _shakeController.forward(from: 0.0);
    }
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
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  String _detectCategory(dynamic task) {
    if (task == null || task is! Map) return 'other';

    final req = (task['requirements'] is Map)
        ? (task['requirements'] as Map)
        : (task['requirement'] is Map ? (task['requirement'] as Map) : {});
    final meta = (task['metadata'] is Map) ? (task['metadata'] as Map) : {};

    final type = (task['taskType'] ?? task['type'] ?? req['taskType'] ?? '').toString().toUpperCase().trim();
    final serviceCode = (task['serviceCode'] ?? req['serviceCode'] ?? '').toString().toUpperCase().trim();
    final title = (task['title'] ?? req['title'] ?? req['videoTitle'] ?? req['appName'] ?? meta['appName'] ?? req['serviceName'] ?? '').toString().toLowerCase().trim();
    final targetUrl = (task['targetUrl'] ?? req['targetUrl'] ?? '').toString().toLowerCase().trim();

    final reqPlatform = (req['platform'] ?? task['platform'] ?? '').toString().toLowerCase().trim();
    final reqCategory = (req['category'] ?? task['category'] ?? '').toString().toLowerCase().trim();
    final reqServiceName = (req['serviceName'] ?? '').toString().toLowerCase().trim();

    // 1. App Installs have highest priority!
    if (type == 'APP_INSTALL' ||
        serviceCode.contains('APP_INSTALL') ||
        title.contains('install & open') ||
        title.contains('app install') ||
        title.contains('install app') ||
        reqServiceName.contains('install & open') ||
        reqServiceName.contains('app install') ||
        reqCategory.contains('app install') ||
        reqCategory.contains('install')) {
      return 'app_install';
    }

    // 2. Google Maps / Local Reviews / Business
    if (type.contains('GOOGLE_BUSINESS') ||
        serviceCode.contains('GOOGLE_BUSINESS') ||
        type.contains('GOOGLE_MAPS') ||
        serviceCode.contains('GOOGLE_MAPS') ||
        type.contains('MAP') ||
        serviceCode.contains('MAP') ||
        title.contains('google maps') ||
        title.contains('google review') ||
        title.contains('google business') ||
        reqServiceName.contains('google maps') ||
        reqServiceName.contains('google review') ||
        reqServiceName.contains('google business') ||
        reqCategory.contains('google business') ||
        reqCategory.contains('google maps') ||
        reqCategory.contains('google') ||
        reqPlatform == 'google' ||
        reqPlatform == 'google_business' ||
        reqPlatform == 'google_maps' ||
        targetUrl.contains('maps.google.com') ||
        targetUrl.contains('share.google') ||
        targetUrl.contains('maps.app.goo.gl') ||
        targetUrl.contains('goo.gl/maps')) {
      return 'google_maps';
    }

    // 3. Play Store Review & Rating
    if (type.contains('PLAYSTORE') ||
        serviceCode.contains('PLAYSTORE') ||
        title.contains('play store') ||
        reqServiceName.contains('play store') ||
        reqCategory.contains('play store') ||
        reqPlatform == 'playstore' ||
        targetUrl.contains('play.google.com')) {
      return 'playstore';
    }

    // 4. YouTube
    if (type.startsWith('YOUTUBE') ||
        serviceCode.startsWith('YOUTUBE') ||
        serviceCode.startsWith('YT_') ||
        title.contains('youtube') ||
        reqServiceName.contains('youtube') ||
        reqCategory.contains('youtube') ||
        reqPlatform == 'youtube' ||
        targetUrl.contains('youtube.com') ||
        targetUrl.contains('youtu.be')) {
      return 'youtube';
    }

    // 5. Instagram
    if (type.startsWith('INSTAGRAM') ||
        serviceCode.startsWith('INSTAGRAM') ||
        serviceCode.startsWith('IG_') ||
        title.contains('instagram') ||
        reqServiceName.contains('instagram') ||
        reqCategory.contains('instagram') ||
        reqPlatform == 'instagram' ||
        targetUrl.contains('instagram.com')) {
      return 'instagram';
    }

    // Fallback: check raw platform tag safely
    final rawPlatform = reqPlatform.isNotEmpty ? reqPlatform : (task['platform'] ?? '').toString().toLowerCase().trim();
    if (rawPlatform == 'playstore') return 'playstore';
    if (rawPlatform == 'youtube') return 'youtube';
    if (rawPlatform == 'instagram') return 'instagram';
    if (rawPlatform == 'google' || rawPlatform == 'google_business' || rawPlatform == 'google_maps' || rawPlatform.contains('map')) return 'google_maps';

    return 'other';
  }

  bool _matchesFilter(dynamic task, String filterKey) {
    if (filterKey == 'All Tasks') return true;

    final cat = _detectCategory(task);

    if (filterKey == 'playstore') {
      return cat == 'playstore' || cat == 'app_install';
    }
    if (filterKey == 'app_install') {
      return cat == 'app_install';
    }
    if (filterKey == 'youtube') {
      return cat == 'youtube';
    }
    if (filterKey == 'instagram') {
      return cat == 'instagram';
    }
    if (filterKey == 'google' || filterKey == 'google_maps') {
      return cat == 'google_maps' || cat == 'google';
    }

    return cat == filterKey;
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

    final filteredTasks = tasksToDisplay.where((t) => _matchesFilter(t, _selectedPlatform)).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF01140C),
        body: Stack(
          children: [
            // ── 1. Pristine Deep Rainforest Background (Clean, No Pre-baked Rain) ──
            Positioned.fill(
              child: Image.asset(
                'assets/images/rainforest_pure_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF01140C),
                ),
              ),
            ),

            // ── 2. Deep Forest Emerald Mist Gradient Overlay ──
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF01140C).withValues(alpha: 0.62),
                      const Color(0xFF022416).withValues(alpha: 0.42),
                      const Color(0xFF01100A).withValues(alpha: 0.70),
                    ],
                  ),
                ),
              ),
            ),

            // ── 3. Real Dynamic Animated Rain Simulation (60 FPS Physics Particles) ──
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _RealAnimatedRainPainter(
                    animation: _rainController,
                    drops: _rainDrops,
                  ),
                ),
              ),
            ),

            // ── 4. Scrollable Feed Content ──
            RefreshIndicator(
              color: const Color(0xFF34D399),
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
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/svg/icon_bullseye_target.svg',
                                width: 26,
                                height: 26,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Available Tasks',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black87,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              _refreshSpinController.forward(from: 0.0);
                              taskProvider.fetchAvailableTasks();
                              taskProvider.fetchWalletData();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFF04331C), Color(0xFF01140A)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF34D399),
                                  width: 1.4,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                    offset: Offset(0, 1.5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Refresh',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF34D399),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  RotationTransition(
                                    turns: _refreshSpinController,
                                    child: const Icon(
                                      Icons.refresh_rounded,
                                      size: 15,
                                      color: Color(0xFF34D399),
                                    ),
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
                          child: CircularProgressIndicator(color: Color(0xFF34D399)),
                        ),
                      )
                    else if (filteredTasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 24),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF022013).withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF104A30).withValues(alpha: 0.8)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
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
                                    color: const Color(0xFF043820),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.5)),
                                  ),
                                  child: const Icon(
                                    Icons.task_alt_rounded,
                                    size: 34,
                                    color: Color(0xFF34D399),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _selectedPlatform == 'All Tasks'
                                      ? 'No Tasks Available Right Now'
                                      : 'No Tasks Found for ${_getSelectedCategoryLabel()}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.5,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'New campaigns are added continuously by buyers. Pull down or tap Refresh below to check for new tasks.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF94A3B8),
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
                              index: index,
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
          ],
        ),
      ),
    );
  }

  // ── Top Forest Emerald Multi-Slide Hero Banner ─────────────────────────────
  Widget _buildHeroBanner(BuildContext context, double walletBalance) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF011A0E),
            Color(0xFF032F1A),
            Color(0xFF043F24),
            Color(0xFF021B0F),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFF22C55E),
            width: 2.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          const BoxShadow(
            color: Colors.black87,
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
            padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Bar: Task Feed Title + Notification & Wallet ─────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Title: 3D Carved Wooden Signboard "Task Feed"
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/header_task_feed_title.svg',
                          height: 44,
                          width: 145,
                          fit: BoxFit.fill,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 2),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Task ',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                    shadows: const [
                                      Shadow(color: Color(0xFF260D02), offset: Offset(1.5, 1.5), blurRadius: 0),
                                      Shadow(color: Color(0xFF260D02), offset: Offset(-1, -1), blurRadius: 0),
                                      Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 3),
                                    ],
                                  ),
                                ),
                                TextSpan(
                                  text: 'Feed',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF4ADE80),
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                    shadows: const [
                                      Shadow(color: Color(0xFF073310), offset: Offset(1.5, 1.5), blurRadius: 0),
                                      Shadow(color: Color(0xFF073310), offset: Offset(-1, -1), blurRadius: 0),
                                      Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 3),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Right Icons: Support Chat + 3D Avatar + Notification Bell + 3D Wallet Pill
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Chat Support Icon (1-on-1 Admin Support) with rotating light beam & unread badge
                        InkWell(
                          onTap: () async {
                            setState(() => _supportUnreadCount = 0);
                            WorkerChatService.instance.clearUnreadCount();
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const WorkerSupportChatScreen(),
                              ),
                            );
                            _loadSupportUnreadCount();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_lightRotateController, _shakeAnimation]),
                            builder: (context, _) {
                              final bool hasUnread = _supportUnreadCount > 0;

                              return SizedBox(
                                width: 34,
                                height: 34,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    if (hasUnread)
                                      Transform.rotate(
                                        angle: _lightRotateController.value * 2 * 3.141592653589793,
                                        child: Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const SweepGradient(
                                              colors: [
                                                Colors.transparent,
                                                Color(0x2200E5FF),
                                                Color(0xFF00E5FF),
                                                Color(0xFF38BDF8),
                                                Color(0xFFA855F7),
                                                Colors.transparent,
                                              ],
                                              stops: [0.0, 0.4, 0.68, 0.85, 0.95, 1.0],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF00E5FF).withValues(alpha: 0.55),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    Transform.rotate(
                                      angle: _shakeAnimation.value,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [Color(0xFF0D9488), Color(0xFF044E3B)],
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF2DD4BF),
                                            width: 1.6,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: hasUnread
                                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
                                                  : const Color(0xFF0D9488).withValues(alpha: 0.35),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.headset_mic_rounded,
                                            color: Colors.white,
                                            size: 19,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (hasUnread)
                                      Positioned(
                                        top: -3,
                                        right: -3,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 1.5),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            _supportUnreadCount > 99 ? '99+' : '$_supportUnreadCount',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

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
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              SvgPicture.asset(
                                'assets/svg/icon_notif_bell.svg',
                                width: 36,
                                height: 36,
                              ),
                              if (_unreadNotifCount > 0)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _unreadNotifCount > 9 ? '9+' : '$_unreadNotifCount',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 3D Glossy Emerald Wallet Pill Container
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const WalletScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF045A30), Color(0xFF023219)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF22C55E),
                                width: 1.6,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 19,
                                  height: 19,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    borderRadius: BorderRadius.circular(5.5),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '₹${walletBalance.toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF86EFAC),
                                  size: 15,
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

                // Hero Banner Carousel (Swipeable & Auto-play)
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
                      // Slide 1: Jungle Treasure Hero Board (Explorer Boy & Chest)
                      _buildSlideOne(context),

                      // Slide 2: Daily Streak Bonus Multiplier (Red Panda Explorer)
                      _buildSlideTwo(context),

                      // Slide 3: High Quality Score & VIP Campaigns
                      _buildSlideFour(context),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Carousel Active Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _totalBannerSlides,
                    (index) {
                      final isActive = _currentBannerIndex == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 22 : 6,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF22C55E)
                              : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF22C55E).withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Slide 1: Complete Tasks & Earn Rewards (Jungle Treasure Chest) ─────────
  Widget _buildSlideOne(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final signW = (screenW * 0.44).clamp(150.0, 180.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. High Resolution 3D Jungle Treasure Hero Background
          // Explorer boy and open glowing chest are positioned prominently on the RIGHT half
          Image.asset(
            'assets/images/jungle_treasure_hero_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF03351C),
            ),
          ),

          // 2. Soft darkening vignette ONLY behind the wooden sign on the left
          // This keeps the explorer boy and open treasure chest completely bright and visible!
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.78),
                  Colors.black.withValues(alpha: 0.40),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.40, 0.55],
              ),
            ),
          ),

          // 3. Left Side: Compact Wooden Signboard Overlay
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 6, top: 6, bottom: 6),
              child: SizedBox(
                width: signW,
                child: Stack(
                  children: [
                    // Wooden signboard background frame
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.96,
                        child: SvgPicture.asset(
                          'assets/svg/banner_wood_signboard.svg',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),

                    // Signboard Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // ⚡ Instant Payouts Badge
                          SvgPicture.asset(
                            'assets/svg/badge_instant_payouts.svg',
                            height: 18,
                          ),

                          // Direct to Bank / UPI
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Direct to',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  shadows: const [
                                    Shadow(color: Colors.black87, offset: Offset(0, 1.5), blurRadius: 3),
                                  ],
                                ),
                              ),
                              Text(
                                'Bank / UPI',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFFDE047),
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  shadows: const [
                                    Shadow(color: Colors.black87, offset: Offset(0, 1.5), blurRadius: 3),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Subtitle
                          Text(
                            'Instant withdraw to UPI, Bank & PayPal',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.90),
                              fontSize: 8.0,
                              fontWeight: FontWeight.w500,
                              height: 1.15,
                            ),
                            maxLines: 2,
                          ),

                          // 3D Emerald "Open Wallet ->" Button
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const WalletScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: SvgPicture.asset(
                              'assets/svg/btn_open_wallet_emerald.svg',
                              height: 27,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Subtle Floating Rupee Coin animations near the open treasure chest (bottom right)
          Positioned(
            right: 28,
            bottom: 12,
            child: AnimatedBuilder(
              animation: _floatingCoinAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -_floatingCoinAnimation.value * 3),
                child: child,
              ),
              child: _buildGoldenCoin(13),
            ),
          ),

          Positioned(
            right: 90,
            bottom: 18,
            child: AnimatedBuilder(
              animation: _floatingCoinAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _floatingCoinAnimation.value * 4),
                child: child,
              ),
              child: _buildGoldenCoin(11),
            ),
          ),

          // Top right subtle verified shield
          Positioned(
            right: 8,
            top: 8,
            child: SvgPicture.asset(
              'assets/svg/badge_shield_verified.svg',
              width: 26,
              height: 28,
            ),
          ),
        ],
      ),
    );
  }

  // ── Slide 2: Daily Streak Bonus Multiplier ─────────────────────────────────
  Widget _buildSlideTwo(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A1002), Color(0xFF180800), Color(0xFF0D0300)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
            width: 1.5,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.48,
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
            ),
            Positioned(
              right: 6,
              top: 6,
              bottom: 6,
              width: MediaQuery.of(context).size.width * 0.44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 3D Cartoon Companion: Red Panda Explorer raising flaming streak torches
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/streak_cartoon_companion.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
                  ),
                  // Floating Fire Multiplier badge
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF97316), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEA580C).withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 13),
                          const SizedBox(width: 2),
                          Text(
                            '2X BONUS',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Floating 7-day streak pill at bottom
                  Positioned(
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 12),
                          const SizedBox(width: 3),
                          Text(
                            '7-DAY STREAK',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFDE68A),
                              fontWeight: FontWeight.bold,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
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


  // ── Slide 4: High Quality Score & VIP Campaigns ────────────────────────────
  Widget _buildSlideFour(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF22083D), Color(0xFF130324), Color(0xFF090014)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFC084FC).withValues(alpha: 0.55),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.48,
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
            ),
            Positioned(
              right: 6,
              top: 6,
              bottom: 6,
              width: MediaQuery.of(context).size.width * 0.44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 3D Lottie Treasure Box Animation
                  Lottie.asset(
                    'assets/animations/treasure_box.json',
                    width: 95,
                    height: 95,
                    fit: BoxFit.contain,
                  ),
                  // Floating Quality Score / VIP Access badge
                  Positioned(
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC084FC), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD8B4FE), size: 13),
                          const SizedBox(width: 4),
                          Consumer<ProfileProvider>(
                            builder: (context, prof, _) {
                              final score = prof.liveQualityScore;
                              final text = score > 0
                                  ? '${score.toStringAsFixed(0)}% VIP SCORE'
                                  : 'VIP ACCESS';
                              return Text(
                                text,
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFE9D5FF),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9.0,
                                ),
                              );
                            },
                          ),
                        ],
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

  String _getSelectedCategoryLabel() {
    switch (_selectedPlatform) {
      case 'google':
      case 'google_maps':
        return 'Google Maps';
      case 'playstore':
        return 'Play Store';
      case 'app_install':
        return 'App Install';
      case 'youtube':
        return 'YouTube';
      case 'instagram':
        return 'Instagram';
      default:
        return _selectedPlatform;
    }
  }

  // ── Platform Filter Horizontal Chips ───────────────────────────────────────
  Widget _buildPlatformChips() {
    final chips = [
      {'label': 'All Tasks', 'icon': Icons.grid_view_rounded, 'key': 'All Tasks'},
      {'label': 'Google Maps', 'asset': 'assets/icons/google-maps.png', 'key': 'google_maps'},
      {'label': 'Play Store', 'asset': 'assets/icons/google-play.png', 'key': 'playstore'},
      {'label': 'App Install', 'asset': 'assets/icons/app_install.png', 'key': 'app_install'},
      {'label': 'YouTube', 'asset': 'assets/icons/youtube.png', 'key': 'youtube'},
      {'label': 'Instagram', 'asset': 'assets/icons/instagram.png', 'key': 'instagram'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: chips.map((c) {
          final isSelected = _selectedPlatform == c['key'];

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPlatform = c['key'] as String;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF22C55E),
                            Color(0xFF16A34A),
                            Color(0xFF14532D),
                          ],
                        )
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFF8FAFC),
                            Color(0xFFE2E8F0),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                    width: isSelected ? 1.8 : 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.2),
                      blurRadius: isSelected ? 10 : 5,
                      offset: const Offset(0, 2.5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (c['asset'] != null)
                      Image.asset(
                        c['asset'] as String,
                        width: 19,
                        height: 19,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.apps_rounded, size: 18, color: isSelected ? Colors.white : const Color(0xFF1E293B)),
                      )
                    else if (c['icon'] != null)
                      Icon(
                        c['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      )
                    else if (c['logo'] != null)
                      PlatformLogo(platform: c['logo'] as String, size: 19),
                    const SizedBox(width: 8),
                    Text(
                      c['label'] as String,
                      style: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                        fontSize: 13,
                        shadows: isSelected
                            ? const [
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ]
                            : null,
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

/// Data model for individual raindrops in the tropical forest particle system
class _RainDropData {
  final double x;
  final double y;
  final double speed;
  final double length;
  final double thickness;
  final double alpha;
  final bool hasSplash;

  const _RainDropData({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
    required this.thickness,
    required this.alpha,
    required this.hasSplash,
  });
}

/// Custom painter for real dynamic continuous falling tropical forest rain
class _RealAnimatedRainPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_RainDropData> drops;

  _RealAnimatedRainPainter({required this.animation, required this.drops})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final progress = animation.value;
    const windSlantX = -3.5;

    // Atmospheric forest mist glow
    final mistGlow = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.35), 90, mistGlow);
    canvas.drawCircle(Offset(size.width * 0.80, size.height * 0.65), 110, mistGlow);

    for (int i = 0; i < drops.length; i++) {
      final drop = drops[i];

      // Seamless continuous cyclic vertical position
      final currentYFraction = (drop.y + (progress * drop.speed)) % 1.0;
      final startY = currentYFraction * size.height;
      // Cyclic horizontal position with wind slant
      final startX = (drop.x * size.width + (currentYFraction * windSlantX * 3)) % size.width;
      final endX = startX + windSlantX;
      final endY = startY + drop.length;

      final paint = Paint()
        ..color = Color.fromRGBO(220, 245, 255, drop.alpha)
        ..strokeWidth = drop.thickness
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);

      // Splash ripples at bottom when raindrops hit the floor/canopy
      if (drop.hasSplash && currentYFraction > 0.90) {
        final splashProgress = (currentYFraction - 0.90) / 0.10;
        final splashOpacity = (1.0 - splashProgress) * 0.25;
        final splashPaint = Paint()
          ..color = Color.fromRGBO(180, 235, 255, splashOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9;

        final splashW = splashProgress * 10.0;
        final splashH = splashProgress * 3.5;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(startX, size.height - 12 + (i % 8)),
            width: splashW,
            height: splashH,
          ),
          splashPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RealAnimatedRainPainter oldDelegate) => true;
}
