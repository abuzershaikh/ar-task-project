import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/di/injection.dart';
import '../bloc/campaigns_list_bloc.dart';
import '../../domain/entities/campaign_detail.dart';

class CampaignsPage extends StatelessWidget {
  const CampaignsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CampaignsListBloc>()..add(const LoadCampaignsListEvent()),
      child: const _CampaignsView(),
    );
  }
}

class _CampaignsView extends StatefulWidget {
  const _CampaignsView();

  @override
  State<_CampaignsView> createState() => _CampaignsViewState();
}

class _CampaignsViewState extends State<_CampaignsView> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // 1. Curved Wave Gradient Header
            _buildCurvedHeader(context),

            // 2. Main Content (Chips + Campaign Cards)
            Expanded(
              child: BlocBuilder<CampaignsListBloc, CampaignsListState>(
                builder: (context, state) {
                  if (state is CampaignsListLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00BFA5),
                      ),
                    );
                  }

                  if (state is CampaignsListError) {
                    return _buildErrorState(context, state.message);
                  }

                  if (state is CampaignsListLoaded) {
                    final allCampaigns = state.campaigns;

                    // Filter in memory for instant feedback
                    final filteredCampaigns = _filterCampaigns(allCampaigns, _selectedFilter);

                    return Column(
                      children: [
                        // Pinned Filter Chips right under the curved wave header
                        Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 8),
                          child: _buildFilterChips(allCampaigns),
                        ),

                        // Scrollable Cards List
                        Expanded(
                          child: RefreshIndicator(
                            color: const Color(0xFF00BFA5),
                            onRefresh: () async {
                              context.read<CampaignsListBloc>().add(
                                    const RefreshCampaignsListEvent(),
                                  );
                            },
                            child: filteredCampaigns.isEmpty
                                ? SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    child: SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.5,
                                      child: _buildEmptyState(_selectedFilter),
                                    ),
                                  )
                                : ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                                    itemCount: filteredCampaigns.length,
                                    itemBuilder: (context, index) {
                                      final campaign = filteredCampaigns[index];
                                      return _buildCampaignCard(context, campaign);
                                    },
                                  ),
                          ),
                        ),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _buildCreateCampaignFAB(context),
      ),
    );
  }

  // ── 1. Top Curved Wave Gradient Header ─────────────────────────────────────
  Widget _buildCurvedHeader(BuildContext context) {
    return ClipPath(
      clipper: const HeaderWaveClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0284C7), // Bright cyan blue
              Color(0xFF0EA5E9),
              Color(0xFF00BFA5), // Vibrant emerald / teal
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Soft Wave Overlay Lines
            Positioned.fill(
              child: CustomPaint(
                painter: const WaveBackgroundPainter(),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                child: Row(
                  children: [
                    // 3D Megaphone Avatar
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.40),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/icons/marketing.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.campaign_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Header Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Campaigns',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manage your content campaigns',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Notification Bell with Red Dot
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No new campaign notifications'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.88),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_rounded,
                              color: Color(0xFF1E293B),
                              size: 20,
                            ),
                            Positioned(
                              top: 8,
                              right: 9,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Refresh Button
                    GestureDetector(
                      onTap: () {
                        context.read<CampaignsListBloc>().add(
                              const RefreshCampaignsListEvent(),
                            );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.88),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF1E293B),
                          size: 20,
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

  // ── 2. Filter Chips Row ────────────────────────────────────────────────────
  Widget _buildFilterChips(List<CampaignDetail> allCampaigns) {
    final int allCount = allCampaigns.length;
    final int activeCount = allCampaigns
        .where((c) => c.status.toLowerCase() == 'active')
        .length;
    final int inProgressCount = allCampaigns
        .where((c) =>
            c.status.toLowerCase() == 'in_progress' ||
            c.status.toLowerCase() == 'inprogress')
        .length;
    final int completedCount = allCampaigns
        .where((c) => c.status.toLowerCase() == 'completed')
        .length;

    final chips = [
      _FilterOption(key: 'all', label: 'All', count: allCount),
      _FilterOption(
        key: 'active',
        label: 'Active',
        count: activeCount,
        dotColor: const Color(0xFF10B981),
      ),
      _FilterOption(
        key: 'in_progress',
        label: 'In Progress',
        count: inProgressCount,
        dotColor: const Color(0xFF3B82F6),
      ),
      _FilterOption(
        key: 'completed',
        label: 'Completed',
        count: completedCount,
        dotColor: const Color(0xFF64748B),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: chips.map((option) {
          final isSelected = _selectedFilter == option.key;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = option.key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF2563EB).withOpacity(0.25)
                          : Colors.black.withOpacity(0.02),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isSelected && option.dotColor != null) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: option.dotColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      option.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${option.count}',
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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

  // ── 3. Campaign Card ───────────────────────────────────────────────────────
  Widget _buildCampaignCard(BuildContext context, CampaignDetail campaign) {
    final double progress = campaign.totalTasks > 0
        ? (campaign.completedTasks / campaign.totalTasks).clamp(0.0, 1.0)
        : 0.0;
    final int percent = (progress * 100).toInt();

    final int unitPrice = campaign.totalTasks > 0
        ? (campaign.totalAmount / campaign.totalTasks).round()
        : campaign.totalAmount.round();

    final String formattedDate = DateFormat('yyyy-MM-dd').format(campaign.createdAt);
    final String formattedTime = DateFormat('hh:mm a').format(campaign.createdAt);
    final String tagline = _getCampaignTagline(campaign);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRouter.campaignDetail,
              arguments: campaign.id,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon + Details + Status Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Platform Icon
                    _buildServiceIcon(campaign),
                    const SizedBox(width: 12),

                    // Title, Subtitle, Date/Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            campaign.name,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tagline,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 7),
                          // Date & Time Row
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 12.5,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 7),
                                child: Text(
                                  '|',
                                  style: TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formattedTime,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Status Pill Badge
                    _buildStatusPill(campaign.status),
                  ],
                ),

                const SizedBox(height: 12),

                // Bottom Stats Bar Container (Light Mint / Soft Tint)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4).withOpacity(0.55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 1. Completed Tasks / Progress (Left)
                      Row(
                        children: [
                          const Icon(
                            Icons.group_rounded,
                            color: Color(0xFF059669),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${campaign.completedTasks}/${campaign.totalTasks}',
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '($percent%)',
                                style: TextStyle(
                                  color: const Color(0xFF059669).withOpacity(0.85),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 2. Price Per Task (Middle)
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFF059669),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '₹',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹$unitPrice',
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Per Task',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 3. View Details Button (Right)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 15,
                              color: Color(0xFF2563EB),
                            ),
                          ],
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
    );
  }

  // ── Platform Icon Factory ──────────────────────────────────────────────────
  Widget _buildServiceIcon(CampaignDetail campaign) {
    final nameLower = '${campaign.name} ${campaign.serviceName}'.toLowerCase();

    List<Color> gradientColors;
    String mainAsset;
    double mainSize = 34;
    String? badgeAsset;
    Widget? customBadge;
    bool badgeTopLeft = false;

    final bool isExplicitPremium = nameLower.contains('premium') ||
        nameLower.contains('vip') ||
        nameLower.contains('crown') ||
        nameLower.contains('special') ||
        nameLower.contains('pro');

    if (nameLower.contains('comment')) {
      // Lavender / Purple gradient
      gradientColors = const [Color(0xFFF3E8FF), Color(0xFFE9D5FF)];
      mainAsset = 'assets/icons/comment.png';
      mainSize = 34;

      // Badge: If YouTube, show YouTube icon badge
      if (nameLower.contains('youtube') || nameLower.contains('yt') || nameLower.contains('video')) {
        badgeAsset = 'assets/icons/youtube.png';
      }
    } else if (nameLower.contains('review') ||
        nameLower.contains('rating') ||
        nameLower.contains('star') ||
        nameLower.contains('play')) {
      // Golden Amber gradient for rating/review
      gradientColors = const [Color(0xFFFEF3C7), Color(0xFFFDE68A)];
      mainAsset = 'assets/icons/star.png';
      mainSize = 34;

      // Blue chat bubble or Google Play badge at bottom right
      if (nameLower.contains('play') || nameLower.contains('google')) {
        badgeAsset = 'assets/icons/google-play.png';
      } else {
        customBadge = Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 10,
            ),
          ),
        );
      }
    } else if (nameLower.contains('sub') || nameLower.contains('subscribe')) {
      // YouTube Channel Subscribe
      final bool isCrownStyle = isExplicitPremium || (campaign.id.hashCode % 2 == 0);
      if (isCrownStyle) {
        gradientColors = const [Color(0xFFFFF1F2), Color(0xFFFFE4E6)]; // soft rose
        mainAsset = 'assets/icons/youtube.png';
        mainSize = 34;
        badgeTopLeft = true;
        customBadge = Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Image.asset(
            'assets/icons/crown.png',
            width: 22,
            height: 22,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFF59E0B),
              size: 14,
            ),
          ),
        );
      } else {
        gradientColors = const [Color(0xFFE0F2FE), Color(0xFFBAE6FD)]; // soft blue
        mainAsset = 'assets/icons/youtube.png';
        mainSize = 34;
        badgeAsset = 'assets/icons/subscribe.png';
      }
    } else if (nameLower.contains('install') ||
        nameLower.contains('download') ||
        nameLower.contains('app')) {
      gradientColors = const [Color(0xFFE0F2FE), Color(0xFFBAE6FD)];
      mainAsset = 'assets/icons/smartphone.png';
      mainSize = 34;
      badgeAsset = 'assets/icons/google-play.png';
    } else if (nameLower.contains('like')) {
      gradientColors = const [Color(0xFFFFF1F2), Color(0xFFFFE4E6)];
      mainAsset = 'assets/icons/like.png';
      mainSize = 34;
      badgeAsset = 'assets/icons/youtube.png';
    } else if (nameLower.contains('insta') || nameLower.contains('follow')) {
      gradientColors = const [Color(0xFFFDF2F8), Color(0xFFFCE7F3)];
      mainAsset = 'assets/icons/instagram.png';
      mainSize = 34;
      badgeAsset = 'assets/icons/like.png';
    } else if (nameLower.contains('youtube') || nameLower.contains('video')) {
      gradientColors = const [Color(0xFFFFF1F2), Color(0xFFFFE4E6)];
      mainAsset = 'assets/icons/youtube.png';
      mainSize = 34;
      badgeAsset = 'assets/icons/play.png';
    } else {
      gradientColors = const [Color(0xFFE6FFFA), Color(0xFFB2F5EA)];
      mainAsset = 'assets/icons/marketing.png';
      mainSize = 32;
    }

    if (isExplicitPremium && customBadge == null) {
      badgeTopLeft = true;
      customBadge = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Image.asset(
          'assets/icons/crown.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.workspace_premium_rounded,
            color: Color(0xFFF59E0B),
            size: 14,
          ),
        ),
      );
    }

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Image.asset(
              mainAsset,
              width: mainSize,
              height: mainSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.campaign_rounded,
                color: Color(0xFF00BFA5),
                size: 28,
              ),
            ),
          ),
          if (badgeAsset != null || customBadge != null)
            Positioned(
              right: badgeTopLeft ? null : -2,
              left: badgeTopLeft ? -3 : null,
              bottom: badgeTopLeft ? null : -2,
              top: badgeTopLeft ? -3 : null,
              child: customBadge ??
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        badgeAsset!,
                        width: 12,
                        height: 12,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
            ),
        ],
      ),
    );
  }

  // ── Status Pill Badge ──────────────────────────────────────────────────────
  Widget _buildStatusPill(String status) {
    Color textColor;
    Color bgColor;
    Color borderColor;
    Widget leadingWidget;
    final statusLower = status.toLowerCase();

    if (statusLower == 'active') {
      textColor = const Color(0xFF059669);
      bgColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFFA7F3D0);
      leadingWidget = Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
      );
    } else if (statusLower == 'in_progress' || statusLower == 'inprogress') {
      textColor = const Color(0xFF2563EB);
      bgColor = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFFBFDBFE);
      leadingWidget = Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
      );
    } else if (statusLower == 'completed') {
      textColor = const Color(0xFF64748B);
      bgColor = const Color(0xFFF1F5F9);
      borderColor = const Color(0xFFE2E8F0);
      leadingWidget = Icon(Icons.check_circle_rounded, color: textColor, size: 12);
    } else if (statusLower == 'paused') {
      textColor = const Color(0xFFD97706);
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      leadingWidget = Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
      );
    } else {
      textColor = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      leadingWidget = Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leadingWidget,
          const SizedBox(width: 5),
          Text(
            status.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 9.5,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating Action Button ─────────────────────────────────────────────────
  Widget _buildCreateCampaignFAB(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRouter.services);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BFA5).withOpacity(0.40),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'Create Campaign',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Utilities ───────────────────────────────────────────────────────
  String _getCampaignTagline(CampaignDetail campaign) {
    final nameLower = '${campaign.name} ${campaign.serviceName}'.toLowerCase();
    if (nameLower.contains('subscribe')) {
      return 'Grow your channel with real subscribers';
    } else if (nameLower.contains('play') ||
        nameLower.contains('rating') ||
        nameLower.contains('review')) {
      return 'Boost your app rating with genuine reviews';
    } else if (nameLower.contains('comment')) {
      return 'Get genuine comments on your videos';
    } else if (nameLower.contains('like')) {
      return 'Increase likes and organic engagement';
    } else if (nameLower.contains('install')) {
      return 'Drive real Android app installs & opens';
    } else if (campaign.serviceName.isNotEmpty) {
      return campaign.serviceName;
    }
    return 'High quality organic growth';
  }

  List<CampaignDetail> _filterCampaigns(
    List<CampaignDetail> allCampaigns,
    String filter,
  ) {
    if (filter == 'active') {
      return allCampaigns
          .where((c) => c.status.toLowerCase() == 'active')
          .toList();
    } else if (filter == 'in_progress') {
      return allCampaigns
          .where((c) =>
              c.status.toLowerCase() == 'in_progress' ||
              c.status.toLowerCase() == 'inprogress')
          .toList();
    } else if (filter == 'completed') {
      return allCampaigns
          .where((c) => c.status.toLowerCase() == 'completed')
          .toList();
    }
    return allCampaigns;
  }

  Widget _buildEmptyState(String filter) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00BFA5).withOpacity(0.12),
              ),
              child: const Center(
                child: Icon(
                  Icons.campaign_outlined,
                  size: 38,
                  color: Color(0xFF00BFA5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${filter.replaceAll('_', ' ')} campaigns found',
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Launch a new campaign to grow your digital presence',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.services);
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Create Campaign',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                context.read<CampaignsListBloc>().add(
                      const LoadCampaignsListEvent(),
                    );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Option Model ──────────────────────────────────────────────────────
class _FilterOption {
  final String key;
  final String label;
  final int count;
  final Color? dotColor;

  const _FilterOption({
    required this.key,
    required this.label,
    required this.count,
    this.dotColor,
  });
}

// ── Custom Wave Header Clipper ───────────────────────────────────────────────
class HeaderWaveClipper extends CustomClipper<Path> {
  const HeaderWaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 24);

    // Smooth double wave curve
    final firstControlPoint = Offset(size.width * 0.28, size.height);
    final firstEndPoint = Offset(size.width * 0.58, size.height - 14);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 0.84, size.height - 30);
    final secondEndPoint = Offset(size.width, size.height - 10);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ── Custom Wave Background Painter ───────────────────────────────────────────
class WaveBackgroundPainter extends CustomPainter {
  const WaveBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.35);
    path1.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.75,
      size.width,
      size.height * 0.50,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.quadraticBezierTo(
      size.width * 0.55,
      size.height * 0.32,
      size.width,
      size.height * 0.70,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
