import 'package:equatable/equatable.dart';
import 'campaign_summary.dart';

class DashboardData extends Equatable {
  final double totalSpend;
  final int totalCampaigns;
  final int activeCampaigns;
  final int completedCampaigns;
  final int pendingTasks;
  final int inProgressTasks;
  final int completedTasks;
  final double overallCompletion;
  final List<CampaignSummary> recentCampaigns;

  const DashboardData({
    required this.totalSpend,
    required this.totalCampaigns,
    required this.activeCampaigns,
    required this.completedCampaigns,
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.completedTasks,
    required this.overallCompletion,
    required this.recentCampaigns,
  });

  @override
  List<Object?> get props => [
    totalSpend,
    totalCampaigns,
    activeCampaigns,
    completedCampaigns,
    pendingTasks,
    inProgressTasks,
    completedTasks,
    overallCompletion,
    recentCampaigns,
  ];
}
