import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/kpi_card.dart';
import '../widgets/action_banner.dart';
import '../widgets/quick_action_button.dart';
import '../../../service_builder/presentation/pages/services_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Command Center'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              backgroundColor: AppColors.white.withOpacity(0.2),
              child: const Icon(Icons.person, color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Implement refresh
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Environment Switcher
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Production',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Urgent Action Banners
              const ActionBanner(
                icon: Icons.verified_user,
                text: '3 Pending KYC Requests',
                color: AppColors.warning,
              ),
              const SizedBox(height: 8),
              const ActionBanner(
                icon: Icons.rate_review,
                text: '14 Task Reviews Needed',
                color: AppColors.error,
              ),
              const SizedBox(height: 8),
              const ActionBanner(
                icon: Icons.account_balance_wallet,
                text: '5 Pending Payouts',
                color: AppColors.info,
              ),
              
              const SizedBox(height: 24),
              
              // KPI Cards Grid
              const Text(
                'Master KPIs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 16),
              
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: const [
                  KpiCard(
                    title: 'Total Workers',
                    value: '1,245',
                    subtitle: '1,120 Active',
                    icon: Icons.people,
                    color: AppColors.primary,
                  ),
                  KpiCard(
                    title: 'Total Buyers',
                    value: '156',
                    subtitle: '142 Active',
                    icon: Icons.business,
                    color: AppColors.secondary,
                  ),
                  KpiCard(
                    title: 'Active Campaigns',
                    value: '89',
                    subtitle: 'Running Now',
                    icon: Icons.campaign,
                    color: AppColors.success,
                  ),
                  KpiCard(
                    title: 'Completed Campaigns',
                    value: '542',
                    subtitle: 'All Time',
                    icon: Icons.check_circle,
                    color: AppColors.info,
                  ),
                  KpiCard(
                    title: 'Pending Reviews',
                    value: '234',
                    subtitle: 'Awaiting Action',
                    icon: Icons.rate_review,
                    color: AppColors.warning,
                  ),
                  KpiCard(
                    title: 'Pending KYC',
                    value: '12',
                    subtitle: 'Verification Queue',
                    icon: Icons.verified_user,
                    color: AppColors.error,
                  ),
                  KpiCard(
                    title: 'Gross Volume',
                    value: '₹24.5L',
                    subtitle: 'Total Processed',
                    icon: Icons.currency_rupee,
                    color: AppColors.primary,
                  ),
                  KpiCard(
                    title: 'Platform Margin',
                    value: '₹3.2L',
                    subtitle: 'Net Profit',
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.verified_user,
                      label: 'Verify KYC',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.account_balance_wallet,
                      label: 'Approve Payouts',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.rate_review,
                      label: 'Review Tasks',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                child: QuickActionButton(
                      icon: Icons.add_business,
                      label: 'Add Service',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ServicesListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
