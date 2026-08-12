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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primary.withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign, color: AppColors.primary),
            label: 'Campaigns',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_customize_outlined),
            selectedIcon: Icon(Icons.dashboard_customize, color: AppColors.primary),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Workers',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business, color: AppColors.primary),
            label: 'Buyers',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_outlined),
            selectedIcon: Icon(Icons.more_horiz, color: AppColors.primary),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
