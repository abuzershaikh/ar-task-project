import 'package:flutter/material.dart';
import '../../task_feed/screens/task_feed_screen.dart';
import '../../my_tasks/my_tasks_screen.dart';
import '../../rewards/screens/rewards_screen.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../../profile/screens/profile_screen.dart';

import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/task_provider.dart';

import 'package:flutter/services.dart';

/// Main Navigation Shell with 5 bottom tabs:
/// Task Feed | My Tasks | Rewards (3D Gaming Strike Center) | Wallet | Profile
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _pingPresence();
  }

  Future<void> _pingPresence() async {
    try {
      await ApiService.pingPresence();
    } catch (_) {}
  }

  final List<Widget> _screens = const [
    TaskFeedScreen(),
    MyTasksScreen(),
    RewardsScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          // If on another tab (Tasks, Rewards, Wallet, Profile), go back to Feed (Home) first
          setState(() => _currentIndex = 0);
          return;
        }

        // If on Task Feed (Home), require double back press to exit
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          color: const Color(0xFF0D192B), // Dark slate matching design
          child: SafeArea(
            top: false,
            bottom: true,
            child: SizedBox(
              height: 64,
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
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFF00875A); // Green matching screenshot
    const inactiveColor = Color(0xFF94A3B8);

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _currentIndex = index);
          if (index == 0) {
            Provider.of<TaskProvider>(context, listen: false).fetchAvailableTasks();
            Provider.of<TaskProvider>(context, listen: false).fetchWalletData();
          }
        },
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
    const activeColor = Color(0xFFF59E0B);
    const inactiveColor = Color(0xFF94A3B8);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🔥', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Strike',
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

