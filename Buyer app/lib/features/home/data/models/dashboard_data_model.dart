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
    final spend = ((json['totalSpent'] ?? json['totalSpend'] as num?) ?? 0).toDouble();
    final totalCmp = (json['totalOrdersCount'] ?? json['totalCampaigns'] as num?)?.toInt() ?? 0;
    final activeCmp = (json['activeOrdersCount'] ?? json['activeCampaigns'] as num?)?.toInt() ?? 0;
    final compCmp = (json['completedOrdersCount'] ?? json['completedCampaigns'] as num?)?.toInt() ?? 0;
    final compTasks = (json['totalTasksCompleted'] ?? json['completedTasks'] as num?)?.toInt() ?? 0;
    final pendTasks = (json['pendingTasks'] as num?)?.toInt() ?? 0;
    final inProgTasks = (json['inProgressTasks'] as num?)?.toInt() ?? 0;

    final double completionPct = (totalCmp > 0)
        ? (compCmp / totalCmp * 100.0)
        : (((json['overallCompletion'] as num?) ?? 0.0).toDouble());

    final rawRecent = json['recentCampaigns'] as List<dynamic>?;
    final List<CampaignSummaryModel> recent = rawRecent != null
        ? rawRecent.map((e) => CampaignSummaryModel.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    return DashboardDataModel(
      totalSpend: spend,
      totalCampaigns: totalCmp,
      activeCampaigns: activeCmp,
      completedCampaigns: compCmp,
      pendingTasks: pendTasks,
      inProgressTasks: inProgTasks,
      completedTasks: compTasks,
      overallCompletion: completionPct,
      recentCampaigns: recent,
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
