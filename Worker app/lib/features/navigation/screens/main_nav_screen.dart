import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../task_feed/screens/task_feed_screen.dart';
import '../../my_tasks/my_tasks_screen.dart';
import '../../rewards/screens/rewards_screen.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/task_provider.dart';
import 'package:flutter/services.dart';

/// Main Navigation Shell with 5 bottom tabs:
/// Feed (Leaf) | Tasks | Strike (Center Glowing Flame) | Wallet | Profile
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Press back again to exit',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              duration: const Duration(seconds: 2),
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
          children: [
            const TaskFeedScreen(),
            const MyTasksScreen(),
            const RewardsScreen(),
            WalletScreen(isCurrentTab: _currentIndex == 3),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF021B11), // Deep dark forest green matching screenshot
            border: Border(
              top: BorderSide(color: Color(0xFF083320), width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.spa_rounded, 'Feed'),
                  _buildNavItem(1, Icons.assignment_outlined, 'Tasks'),
                  _buildCenterStrikeNavItem(2),
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
    const activeColor = Color(0xFF22C55E); // Bright vibrant emerald green
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
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterStrikeNavItem(int index) {
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFCD34D), // Yellow
                    Color(0xFFF59E0B), // Amber
                    Color(0xFFD97706), // Orange
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Strike',
              style: GoogleFonts.poppins(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
