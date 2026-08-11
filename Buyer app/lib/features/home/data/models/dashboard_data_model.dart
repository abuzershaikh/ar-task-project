import '../../domain/entities/dashboard_data.dart';
import 'campaign_summary_model.dart';

class DashboardDataModel extends DashboardData {
  const DashboardDataModel({
    required super.totalSpend,
    required super.totalCampaigns,
    required super.activeCampaigns,
    required super.completedCampaigns,
    required super.pendingTasks,
    required super.inProgressTasks,
    required super.completedTasks,
    required super.overallCompletion,
    required super.recentCampaigns,
  });

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) {
    return DashboardDataModel(
      totalSpend: (json['totalSpend'] ?? 0).toDouble(),
      totalCampaigns: json['totalCampaigns'] ?? 0,
      activeCampaigns: json['activeCampaigns'] ?? 0,
      completedCampaigns: json['completedCampaigns'] ?? 0,
      pendingTasks: json['pendingTasks'] ?? 0,
      inProgressTasks: json['inProgressTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      overallCompletion: (json['overallCompletion'] ?? 0).toDouble(),
      recentCampaigns: (json['recentCampaigns'] as List<dynamic>?)
          ?.map((e) => CampaignSummaryModel.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSpend': totalSpend,
      'totalCampaigns': totalCampaigns,
      'activeCampaigns': activeCampaigns,
      'completedCampaigns': completedCampaigns,
      'pendingTasks': pendingTasks,
      'inProgressTasks': inProgressTasks,
      'completedTasks': completedTasks,
      'overallCompletion': overallCompletion,
      'recentCampaigns': recentCampaigns.map((e) => (e as CampaignSummaryModel).toJson()).toList(),
    };
  }
}
