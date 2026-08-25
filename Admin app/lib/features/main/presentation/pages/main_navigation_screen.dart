import 'package:flutter/material.dart';
import '../../../dashboard/presentation/pages/dashboard_screen.dart';
import '../../../orders/presentation/pages/campaigns_list_screen.dart';
import '../../../service_builder/presentation/pages/services_list_screen.dart';
import '../../../workers/presentation/pages/worker_directory_screen.dart';
import '../../../buyers/presentation/pages/buyer_directory_screen.dart';
import '../../../wallet/presentation/pages/admin_topup_screen.dart';
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
    AdminTopupScreen(),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0)),
              Expanded(child: _buildNavItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Topup', 1)),
              Expanded(child: _buildNavItem(Icons.campaign_outlined, Icons.campaign, 'Campaigns', 2)),
              Expanded(child: _buildNavItem(Icons.dashboard_customize_outlined, Icons.dashboard_customize, 'Services', 3)),
              Expanded(child: _buildNavItem(Icons.people_outline, Icons.people, 'Workers', 4)),
              Expanded(child: _buildNavItem(Icons.business_outlined, Icons.business, 'Buyers', 5)),
              Expanded(child: _buildNavItem(Icons.more_horiz_outlined, Icons.more_horiz, 'More', 6)),
            ],
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppColors.primary : AppColors.gray500,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.gray500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
