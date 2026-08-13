import 'package:flutter/material.dart';
import '../../../dashboard/presentation/pages/dashboard_screen.dart';
import '../../../orders/presentation/pages/campaigns_list_screen.dart';
import '../../../service_builder/presentation/pages/services_list_screen.dart';
import '../../../workers/presentation/pages/worker_directory_screen.dart';
import '../../../buyers/presentation/pages/buyer_directory_screen.dart';
import '../../../more/presentation/pages/control_center_screen.dart';
import '../../../../core/theme/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CampaignsListScreen(),
    ServicesListScreen(),
    WorkerDirectoryScreen(),
    BuyerDirectoryScreen(),
    ControlCenterScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
                _buildNavItem(Icons.campaign_outlined, Icons.campaign, 'Campaigns', 1),
                _buildNavItem(Icons.dashboard_customize_outlined, Icons.dashboard_customize, 'Services', 2),
                _buildNavItem(Icons.people_outline, Icons.people, 'Workers', 3),
                _buildNavItem(Icons.business_outlined, Icons.business, 'Buyers', 4),
                _buildNavItem(Icons.more_horiz_outlined, Icons.more_horiz, 'More', 5),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData selectedIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(minWidth: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppColors.primary : AppColors.gray500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
