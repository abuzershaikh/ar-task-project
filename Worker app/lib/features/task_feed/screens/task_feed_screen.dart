import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../shared/widgets/platform_logo.dart';
import '../../task_detail/screens/task_detail_screen.dart';
import '../widgets/task_feed_card.dart';

/// Task Feed Screen — exact replica of the user's provided UI screenshot.
class TaskFeedScreen extends StatefulWidget {
  const TaskFeedScreen({super.key});

  @override
  State<TaskFeedScreen> createState() => _TaskFeedScreenState();
}

class _TaskFeedScreenState extends State<TaskFeedScreen> {
  String _selectedPlatform = 'All Tasks';

  final List<Map<String, dynamic>> _mockTasks = [
    {
      'id': 'T-101',
      'title': 'Review on Google',
      'taskType': 'GOOGLE_REVIEW',
      'platform': 'google',
      'badge': 'Featured',
      'rewardPerTask': 10,
      'description':
          'Give a 5★ review for our partner business on Google and share your honest feedback.',
      'estimatedTime': '2-3 min',
      'tagType': '5★ Review',
      'timeToCompleteHours': 24,
    },
    {
      'id': 'T-102',
      'title': 'Comment on YouTube',
      'taskType': 'YOUTUBE_COMMENT',
      'platform': 'youtube',
      'badge': 'Trending',
      'rewardPerTask': 8,
      'description':
          'Watch short video and post a genuine comment. Keep it positive and real.',
      'estimatedTime': '2 min',
      'tagType': 'Comment',
      'timeToCompleteHours': 24,
    },
    {
      'id': 'T-103',
      'title': 'Like & Comment on Instagram',
      'taskType': 'INSTAGRAM_LIKE',
      'platform': 'instagram',
      'badge': 'Hot',
      'rewardPerTask': 6,
      'description':
          'Like the post and drop a nice comment to support the creator.',
      'estimatedTime': '1-2 min',
      'tagType': 'Like + Comment',
      'timeToCompleteHours': 12,
    },
    {
      'id': 'T-104',
      'title': 'Review on Facebook Page',
      'taskType': 'FACEBOOK_REVIEW',
      'platform': 'facebook',
      'badge': 'Featured',
      'rewardPerTask': 8,
      'description':
          'Give 5★ rating and write a short review on our partner page.',
      'estimatedTime': '2-3 min',
      'tagType': '5★ Review',
      'timeToCompleteHours': 48,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchAvailableTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    // Merge live tasks from API or fallback mock tasks
    final tasksToDisplay = taskProvider.availableTasks.isNotEmpty
        ? taskProvider.availableTasks
        : _mockTasks;

    final filteredTasks = _selectedPlatform == 'All Tasks'
        ? tasksToDisplay
        : tasksToDisplay.where((t) {
            final p = (t['platform'] ?? t['taskType'] ?? '').toString().toLowerCase();
            return p.contains(_selectedPlatform.toLowerCase());
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF00875A),
          onRefresh: () => taskProvider.fetchAvailableTasks(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Top Header Bar ────────────────────────────────────────
                _buildHeaderBar(),
                const SizedBox(height: 14),

                // ── 3. Promo Banner / Carousel ──────────────────────────────
                _buildPromoBanner(),
                const SizedBox(height: 16),

                // ── 4. Platform Filter Chips ─────────────────────────────────
                _buildPlatformChips(),
                const SizedBox(height: 16),

                // ── 5. Section Header ("Available Tasks") ────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Tasks',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () {},
                      child: const Row(
                        children: [
                          Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xFF00875A),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 14, color: Color(0xFF00875A)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── 7. Available Task List Cards ────────────────────────────
                if (taskProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF00875A)),
                    ),
                  )
                else
                  ListView.builder(
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
                              builder: (_) => TaskDetailScreen(task: task),
                            ),
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header Bar ─────────────────────────────────────────────────────────────
  Widget _buildHeaderBar() {
    return Row(
      children: [
        // Left Column: Task Feed Title
        Expanded(
          child: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Task ',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: 'Feed',
                  style: TextStyle(
                    color: Color(0xFF00875A),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Actions: Notification Bell + Wallet Balance Card
        Row(
          children: [
            // Bell Button with notification dot
            Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF334155),
                    size: 22,
                  ),
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00875A),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),

            // Wallet Pill Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF00875A),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '₹1,250',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Promo Banner Card ──────────────────────────────────────────────────────
  Widget _buildPromoBanner() {
    return Container(
      height: 165,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Green Wave Graphic (Right Side)
            Positioned(
              right: -30,
              top: -20,
              bottom: -20,
              width: 220,
              child: CustomPaint(
                painter: _GreenWavePainter(),
              ),
            ),

            // Left Content Text & Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Complete Tasks',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Earn Rewards',
                    style: TextStyle(
                      color: Color(0xFF00875A),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(
                    width: 170,
                    child: Text(
                      'Reviews, Comments & More on Your Favorite Platforms',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Start Earning Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00875A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Start Earning',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Floating Platform Logos on Green Wave
            Positioned(
              right: 110,
              top: 24,
              child: const PlatformLogo(platform: 'google', size: 36),
            ),
            Positioned(
              right: 50,
              top: 14,
              child: const PlatformLogo(platform: 'youtube', size: 38),
            ),
            Positioned(
              right: 12,
              top: 28,
              child: const PlatformLogo(platform: 'instagram', size: 36),
            ),
            Positioned(
              right: 80,
              top: 78,
              child: const PlatformLogo(platform: 'facebook', size: 36),
            ),
            Positioned(
              right: 32,
              top: 86,
              child: const PlatformLogo(platform: 'x', size: 34),
            ),

            // Bottom Carousel Indicator Dots
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 16,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00875A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCBD5E1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCBD5E1),
                      shape: BoxShape.circle,
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

  // ── Platform Filter Horizontal Chips ───────────────────────────────────────
  Widget _buildPlatformChips() {
    final chips = [
      {'label': 'All Tasks', 'icon': Icons.grid_view_rounded, 'key': 'All Tasks'},
      {'label': 'Google', 'logo': 'google', 'key': 'Google'},
      {'label': 'YouTube', 'logo': 'youtube', 'key': 'YouTube'},
      {'label': 'Facebook', 'logo': 'facebook', 'key': 'Facebook'},
      {'label': 'Instagram', 'logo': 'instagram', 'key': 'Instagram'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
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
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00875A) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00875A)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
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
                      PlatformLogo(platform: c['logo'] as String, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      c['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
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

/// Custom Painter to draw the smooth curved green wave on the Promo Banner
class _GreenWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00875A), Color(0xFF0E9F6E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width * 0.35, 0)
      ..cubicTo(
        size.width * 0.05,
        size.height * 0.45,
        size.width * 0.4,
        size.height * 0.8,
        0,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
