import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/dashboard_stats_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/campaign_overview_card.dart';
import '../widgets/recent_campaign_item.dart';
import '../widgets/info_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboardDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning, Buyer! 👋',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 2),
            Text(
              'Here\'s what\'s happening with your campaigns.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 26),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '3',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.notifications);
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRouter.profile);
            },
            child: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                'B',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<DashboardBloc>().add(LoadDashboardDataEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is DashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardBloc>().add(LoadDashboardDataEvent());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Stats Card
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: DashboardStatsCard(
                              icon: Icons.shopping_bag_outlined,
                              label: 'Total Spend',
                              value: '₹${state.dashboardData.totalSpend.toStringAsFixed(0)}',
                              trend: '+12.5% vs last month',
                              isWhite: true,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: Colors.white.withOpacity(0.3),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          Expanded(
                            child: DashboardStatsCard(
                              icon: Icons.campaign_outlined,
                              label: 'Total Campaigns',
                              value: state.dashboardData.totalCampaigns.toString(),
                              trend: '${state.dashboardData.activeCampaigns} Active',
                              isWhite: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionButton(
                            icon: Icons.add_circle_outline,
                            label: 'Create Campaign',
                            color: AppColors.primary,
                            onTap: () {
                              Navigator.pushNamed(context, AppRouter.services);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionButton(
                            icon: Icons.trending_up_outlined,
                            label: 'Performance',
                            color: AppColors.success,
                            onTap: () {
                              Navigator.pushNamed(context, AppRouter.analytics);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionButton(
                            icon: Icons.people_outline,
                            label: 'Workers',
                            color: AppColors.warning,
                            onTap: () {
                              // Show worker stats
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionButton(
                            icon: Icons.payment_outlined,
                            label: 'Payments',
                            color: AppColors.info,
                            onTap: () {
                              Navigator.pushNamed(context, AppRouter.payments);
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Campaign Overview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Campaign Overview', style: AppTextStyles.heading4),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRouter.campaigns);
                          },
                          child: Row(
                            children: [
                              Text('View all', style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                              )),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: CampaignOverviewCard(
                            icon: Icons.rocket_launch_outlined,
                            iconColor: AppColors.info,
                            label: 'Active\ncampaigns',
                            value: state.dashboardData.activeCampaigns.toString(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampaignOverviewCard(
                            icon: Icons.check_circle_outline,
                            iconColor: AppColors.success,
                            label: 'Completed\ntasks',
                            value: state.dashboardData.completedTasks.toString(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampaignOverviewCard(
                            icon: Icons.schedule_outlined,
                            iconColor: AppColors.warning,
                            label: 'In Progress\ntasks',
                            value: state.dashboardData.inProgressTasks.toString(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampaignOverviewCard(
                            icon: Icons.pending_outlined,
                            iconColor: AppColors.error,
                            label: 'Pending\ntasks',
                            value: state.dashboardData.pendingTasks.toString(),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Recent Campaigns
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Campaigns', style: AppTextStyles.heading4),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRouter.campaigns);
                          },
                          child: Row(
                            children: [
                              Text('View all', style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                              )),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    ...state.dashboardData.recentCampaigns.map((campaign) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RecentCampaignItem(campaign: campaign),
                      );
                    }).toList(),
                    
                    const SizedBox(height: 16),
                    
                    // Info Banners
                    const InfoBanner(
                      icon: Icons.verified_outlined,
                      title: 'Quality Work. Verified Workers.',
                      description: 'We ensure reliable data and high quality through our verification process.',
                      actionText: 'Learn more',
                    ),
                    
                    const SizedBox(height: 12),
                    
                    const InfoBanner(
                      icon: Icons.headset_mic_outlined,
                      title: 'Need Help?',
                      description: 'Contact our support team anytime.',
                      actionText: 'Contact',
                      backgroundColor: AppColors.info,
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
          
          return const SizedBox();
        },
      ),
    );
  }
}
