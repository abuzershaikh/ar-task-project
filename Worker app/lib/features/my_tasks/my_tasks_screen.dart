import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/task_provider.dart';
import 'screens/task_stage_list_view.dart';

/// My Tasks Screen:
/// - Sticky Header & Filter Row at top (fixed)
/// - Scrollable Task List in middle (only tasks scroll)
/// - 100% Edge-to-Edge Full-Width Dark Sub-Bottom Navigation Bar (Accepted, Submitted, Review, Approved, Rejected)
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
      'label': 'Submitted',
      'icon': Icons.send_rounded,
      'title': 'Submitted Tasks',
    },
    {
      'label': 'Review',
      'icon': Icons.hourglass_empty_rounded,
      'title': 'Review Tasks',
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
    });
  }

  void _loadStage(int index) {
    setState(() => _currentStageIndex = index);
    Provider.of<TaskProvider>(context, listen: false)
        .fetchMyTasks(AppConstants.myTaskStages[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        top: true,
        bottom: false,
        left: false,
        right: false,
        child: Column(
          children: [
            // ── 1. Top Fixed Section (Header & Filter Row) ────────────────
            Container(
              color: const Color(0xFFF6F8FA),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Bar
                  _buildHeaderBar(),
                  const SizedBox(height: 14),

                  // Section Title & Filter Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _stageMeta[_currentStageIndex]['title'] as String,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Filter Pill Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
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
                ],
              ),
            ),

            // ── 2. Scrollable Task List (Only tasks scroll) ───────────────
            Expanded(
              child: TaskStageListView(
                stage: AppConstants.myTaskStages[_currentStageIndex],
              ),
            ),

            // ── 3. 100% Full-Width Dark Sub Bottom Navigation Bar ─────────
            _buildStageSubBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Header Bar ─────────────────────────────────────────────────────────────
  Widget _buildHeaderBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title & Subtitle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'My ',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: 'Tasks',
                    style: TextStyle(
                      color: Color(0xFF00875A),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Track and manage your tasks',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Circular Refresh Button
        InkWell(
          onTap: () => _loadStage(_currentStageIndex),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF00875A),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ── 100% Full-Width Sub Bottom Navigation Bar (Stage Tabs) ─────────────────
  Widget _buildStageSubBottomBar() {
    return Container(
      width: double.infinity,
      height: 52,
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
                    size: 17,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta['label'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? activeColor : inactiveColor,
                      fontSize: 9.5,
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
