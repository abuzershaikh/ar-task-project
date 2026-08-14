import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/kpi_card.dart';
import '../widgets/action_banner.dart';
import '../widgets/quick_action_button.dart';
import '../../../service_builder/presentation/pages/services_list_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../../../../core/di/injection.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DashboardBloc>()..add(LoadDashboardEvent()),
      child: Scaffold(
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
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is DashboardError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, style: const TextStyle(color: AppColors.error)),
                    ElevatedButton(
                      onPressed: () => context.read<DashboardBloc>().add(LoadDashboardEvent()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is DashboardLoaded) {
              final data = state.data;
              final financial = state.financial;

              final totalWorkers = data['users']?['totalWorkers'] ?? 0;
              final activeWorkers = data['users']?['activeWorkers'] ?? 0;
              final totalBuyers = data['users']?['totalBuyers'] ?? 0;
              final activeBuyers = data['users']?['activeBuyers'] ?? 0;
              final pendingKycCount = data['queues']?['pendingKycCount'] ?? 0;
              final pendingReviewCount = data['queues']?['pendingReviewCount'] ?? 0;
              final pendingPayoutsCount = data['queues']?['pendingPayoutsCount'] ?? 0;

              final grossVolume = financial['grossPlatformVolume'] ?? 0.0;
              final netMargin = financial['platformNetMargin'] ?? 0.0;

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DashboardBloc>().add(RefreshDashboardEvent());
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
              if (pendingKycCount > 0)
                Column(
                  children: [
                    ActionBanner(
                      icon: Icons.verified_user,
                      text: '$pendingKycCount Pending KYC Requests',
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              if (pendingReviewCount > 0)
                Column(
                  children: [
                    ActionBanner(
                      icon: Icons.rate_review,
                      text: '$pendingReviewCount Task Reviews Needed',
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              if (pendingPayoutsCount > 0)
                ActionBanner(
                  icon: Icons.account_balance_wallet,
                  text: '$pendingPayoutsCount Pending Payouts',
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
                  KpiCard(
                    title: 'Total Workers',
                    value: totalWorkers.toString(),
                    subtitle: '$activeWorkers Active',
                    icon: Icons.people,
                    color: AppColors.primary,
                  ),
                  KpiCard(
                    title: 'Total Buyers',
                    value: totalBuyers.toString(),
                    subtitle: '$activeBuyers Active',
                    icon: Icons.business,
                    color: AppColors.secondary,
                  ),
                  const KpiCard(
                    title: 'Active Campaigns',
                    value: 'API Pending', // Will need order metrics API 
                    subtitle: 'Running Now',
                    icon: Icons.campaign,
                    color: AppColors.success,
                  ),
                  const KpiCard(
                    title: 'Completed Campaigns',
                    value: 'API Pending',
                    subtitle: 'All Time',
                    icon: Icons.check_circle,
                    color: AppColors.info,
                  ),
                  KpiCard(
                    title: 'Pending Reviews',
                    value: pendingReviewCount.toString(),
                    subtitle: 'Awaiting Action',
                    icon: Icons.rate_review,
                    color: AppColors.warning,
                  ),
                  KpiCard(
                    title: 'Pending KYC',
                    value: pendingKycCount.toString(),
                    subtitle: 'Verification Queue',
                    icon: Icons.verified_user,
                    color: AppColors.error,
                  ),
                  KpiCard(
                    title: 'Gross Volume',
                    value: '₹${grossVolume.toStringAsFixed(0)}',
                    subtitle: 'Total Processed',
                    icon: Icons.currency_rupee,
                    color: AppColors.primary,
                  ),
                  KpiCard(
                    title: 'Platform Margin',
                    value: '₹${netMargin.toStringAsFixed(0)}',
                    subtitle: 'Net Profit',
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              

            ],
          ),
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
