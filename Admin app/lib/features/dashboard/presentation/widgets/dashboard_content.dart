import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'kpi_card.dart';
import 'alert_card.dart';
import 'quick_stats_grid.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '5',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh logic
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(76),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, Admin 👋',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'EarnPost Task Platform Control Center',
                      style: TextStyle(
                        color: Color(0xFFE0E7FF),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Key Platform Metrics
              const QuickStatsGrid(),
              const SizedBox(height: 24),

              // Financial Overview
              _SectionHeader(
                title: 'Financial Overview',
                icon: Icons.account_balance_wallet_outlined,
                onViewAll: () {},
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: KpiCard(
                      title: "Today's Revenue",
                      value: '₹4,82,500',
                      icon: Icons.trending_up,
                      color: AppColors.success,
                      trend: '+12.5%',
                      trendUp: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiCard(
                      title: 'Platform Margin',
                      value: '₹1,91,500',
                      icon: Icons.payments_outlined,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: KpiCard(
                      title: 'Worker Earnings',
                      value: '₹2,91,000',
                      icon: Icons.money_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiCard(
                      title: 'Pending Payout',
                      value: '₹84,200',
                      icon: Icons.pending_actions_outlined,
                      color: AppColors.error,
                      trend: '18 pending',
                      trendUp: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Platform Alerts
              _SectionHeader(
                title: 'Platform Alerts',
                icon: Icons.warning_amber_outlined,
                onViewAll: () {},
              ),
              const SizedBox(height: 12),
              AlertCard(
                icon: Icons.verified_user_outlined,
                title: '42 KYC Pending',
                subtitle: 'Review worker verification documents',
                color: AppColors.warning,
                onTap: () {},
              ),
              AlertCard(
                icon: Icons.assignment_late_outlined,
                title: '320 Tasks Waiting for Worker',
                subtitle: 'Allocation pending, check matching engine',
                color: AppColors.error,
                onTap: () {},
              ),
              AlertCard(
                icon: Icons.people_alt_outlined,
                title: '12 Campaigns Low Worker Availability',
                subtitle: 'May need deadline extension',
                color: AppColors.info,
                onTap: () {},
              ),
              AlertCard(
                icon: Icons.payment_outlined,
                title: '7 Payment Failures',
                subtitle: 'Webhook delivery failed, retry needed',
                color: AppColors.error,
                onTap: () {},
              ),
              const SizedBox(height: 24),

              // Recent Activity
              _SectionHeader(
                title: 'Recent Activity',
                icon: Icons.history_outlined,
                onViewAll: () {},
              ),
              const SizedBox(height: 12),
              _ActivityItem(
                icon: Icons.task_alt,
                title: 'Task T-10025 Approved',
                subtitle: 'Worker W-10025 • 2 mins ago',
                color: AppColors.success,
              ),
              _ActivityItem(
                icon: Icons.shopping_bag,
                title: 'New Order Created',
                subtitle: 'ABC Company • ₹2,500 • 5 mins ago',
                color: AppColors.info,
              ),
              _ActivityItem(
                icon: Icons.person_add,
                title: 'New Worker Registered',
                subtitle: 'W-52841 • 12 mins ago',
                color: AppColors.success,
              ),
              _ActivityItem(
                icon: Icons.money,
                title: 'Payout Processed',
                subtitle: 'W-10123 • ₹2,500 • 15 mins ago',
                color: AppColors.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onViewAll;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.gray700, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text('View All'),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gray400),
        ],
      ),
    );
  }
}
