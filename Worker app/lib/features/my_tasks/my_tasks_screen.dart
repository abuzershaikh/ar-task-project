import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/task_provider.dart';
import 'screens/task_stage_list_view.dart';

/// My Tasks Screen:
/// - Curved Emerald Jungle Top Header Banner with 3D Avatar, Title, Today Earnings Pill, Notification & Refresh
/// - Sticky Subtitle & Filter Row
/// - Scrollable Task List in middle (only tasks scroll)
/// - 100% Edge-to-Edge Full-Width Dark Sub-Bottom Navigation Bar (Accepted, In Review, Approved, Rejected)
class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  int _currentStageIndex = 0;

  final List<Map<String, dynamic>> _stageMeta = [
    {
      'label': 'Accepted',
      'icon': Icons.task_alt_rounded,
      'title': 'Accepted Tasks',
    },
    {
      'label': 'In Review',
      'icon': Icons.hourglass_top_rounded,
      'title': 'In Review Tasks',
    },
    {
      'label': 'Approved',
      'icon': Icons.check_circle_outline_rounded,
      'title': 'Approved Tasks',
    },
    {
      'label': 'Rejected',
      'icon': Icons.cancel_outlined,
      'title': 'Rejected Tasks',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStage(0);
      Provider.of<TaskProvider>(context, listen: false).fetchWalletData();
    });
  }

  void _loadStage(int index, {bool forceRefresh = false}) {
    setState(() => _currentStageIndex = index);
    Provider.of<TaskProvider>(context, listen: false).fetchMyTasks(
      AppConstants.myTaskStages[index],
      forceRefresh: forceRefresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FA),
        body: Column(
          children: [
            // ── 1. Top Emerald Jungle Header Banner ───────────────────────
            _buildTopBanner(topPadding),

            // ── 2. Fixed Section Title & Filter Row ────────────────────────
            Container(
              color: const Color(0xFFF6F8FA),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _stageMeta[_currentStageIndex]['title'] as String,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  // Filter Pill Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list_rounded,
                            size: 13, color: Color(0xFF475569)),
                        SizedBox(width: 4),
                        Text(
                          'Filter',
                          style: TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 15, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 3. Scrollable Task List (Only tasks scroll) ───────────────
            Expanded(
              child: TaskStageListView(
                stage: AppConstants.myTaskStages[_currentStageIndex],
              ),
            ),

            // ── 4. 100% Full-Width Dark Sub Bottom Navigation Bar ─────────
            _buildStageSubBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Top Emerald Jungle Banner (Matching User Reference Image) ───────────────
  Widget _buildTopBanner(double topPadding) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF022B19),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF044E33).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Stack(
          children: [
            // Background Image with gradient fallback
            Positioned.fill(
              child: Image.asset(
                'assets/images/tasks_banner_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF011E11),
                        Color(0xFF03442A),
                        Color(0xFF046640),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),

            // Subtle dark overlay to guarantee text legibility
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.transparent,
                      Colors.black.withOpacity(0.35),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Foreground Content
            Padding(
              padding: EdgeInsets.fromLTRB(14, topPadding + 10, 14, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Left: 3D Boy Avatar with Neon Border & Golden Crown ──
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF22C55E), // Vivid Neon Green Ring
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withOpacity(0.45),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/worker_avatar_3d.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                              backgroundColor: Color(0xFF064E3B),
                              child: Icon(Icons.person_rounded, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      // Golden Crown Badge at top-right
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: 19,
                          height: 19,
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFDF00), Color(0xFFF59E0B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/icons/crown.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.workspace_premium_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),

                  // ── Title & Subtitle with Leaf Motif ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'My ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              TextSpan(
                                text: 'Tasks',
                                style: TextStyle(
                                  color: Color(0xFF4ADE80), // Mint green
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Track and manage your tasks',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFFD1FAE5).withOpacity(0.88),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.eco_rounded,
                              size: 13,
                              color: Color(0xFF4ADE80),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ── Right: Circular Refresh Button ──
                  InkWell(
                    onTap: () {
                      _loadStage(_currentStageIndex, forceRefresh: true);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.38),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4ADE80).withOpacity(0.38),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 19,
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

  // ── 100% Full-Width Sub Bottom Navigation Bar (4 Clean Stage Tabs) ─────────
  Widget _buildStageSubBottomBar() {
    return Container(
      width: double.infinity,
      height: 54,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      decoration: const BoxDecoration(
        color: Color(0xFF0D192B), // Dark slate matching screenshot
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_stageMeta.length, (index) {
          final isSelected = index == _currentStageIndex;
          final meta = _stageMeta[index];
          const activeColor = Color(0xFF00875A);
          const inactiveColor = Color(0xFF94A3B8);

          return Expanded(
            child: InkWell(
              onTap: () => _loadStage(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    meta['icon'] as IconData,
                    size: 18,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta['label'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? activeColor : inactiveColor,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
