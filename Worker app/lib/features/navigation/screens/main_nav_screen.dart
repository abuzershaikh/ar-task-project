import 'package:flutter/material.dart';
import '../../task_feed/screens/task_feed_screen.dart';
import '../../my_tasks/my_tasks_screen.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../../profile/screens/profile_screen.dart';

/// Main Navigation Shell with 5 bottom tabs:
/// Task Feed | My Tasks | Rewards (Center Gift) | Wallet | Profile
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TaskFeedScreen(),
    MyTasksScreen(),
    _RewardsPlaceholderScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF0D192B), // Dark slate matching screenshot
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.explore_rounded, 'Feed'),
                _buildNavItem(1, Icons.assignment_outlined, 'Tasks'),
                _buildCenterRewardNavItem(2),
                _buildNavItem(3, Icons.account_balance_wallet_outlined, 'Wallet'),
                _buildNavItem(4, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFF00875A); // Green matching screenshot
    const inactiveColor = Color(0xFF94A3B8);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 21,
            ),
            const SizedBox(height: 2),
            Text(
              label,
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
  }

  Widget _buildCenterRewardNavItem(int index) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFF00875A);
    const inactiveColor = Color(0xFF94A3B8);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF00875A),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00875A).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Rewards',
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
  }
}

class _RewardsPlaceholderScreen extends StatelessWidget {
  const _RewardsPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text('Rewards & Bonuses', style: TextStyle(color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard_rounded,
                  size: 64, color: Color(0xFF00875A)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Claim Daily Rewards & Bonuses!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete 5 tasks daily to unlock bonus scratch cards.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
