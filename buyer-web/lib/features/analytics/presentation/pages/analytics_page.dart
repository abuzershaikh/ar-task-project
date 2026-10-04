import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/presentation/bloc/dashboard_bloc.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Performance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardBloc>().add(LoadDashboardDataEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          int totalCampaigns = 0;
          int activeCampaigns = 0;
          int completedTasks = 0;
          int pendingTasks = 0;

          if (state is DashboardLoaded) {
            totalCampaigns = state.dashboardData.totalCampaigns;
            activeCampaigns = state.dashboardData.activeCampaigns;
            completedTasks = state.dashboardData.completedTasks;
            pendingTasks = state.dashboardData.pendingTasks;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatCard('Total Campaigns', '$totalCampaigns', Icons.campaign_rounded, AppColors.primary),
              const SizedBox(height: 12),
              _buildStatCard('Active Campaigns', '$activeCampaigns', Icons.play_circle_fill_rounded, AppColors.success),
              const SizedBox(height: 12),
              _buildStatCard('Completed Tasks', '$completedTasks', Icons.check_circle_rounded, const Color(0xFF6366F1)),
              const SizedBox(height: 12),
              _buildStatCard('Pending Units', '$pendingTasks', Icons.pending_actions_rounded, AppColors.warning),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Live real-time buyer analytics',
                  style: AppTextStyles.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelMedium),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.statNumber),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
