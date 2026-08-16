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
    double parseD(dynamic v, double def) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? def;
      return def;
    }
    int parseI(dynamic v, int def) {
      if (v == null) return def;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? def;
      return def;
    }

    final spend = parseD(json['totalSpent'] ?? json['totalSpend'], 0.0);
    final totalCmp = parseI(json['totalOrdersCount'] ?? json['totalCampaigns'], 0);
    final activeCmp = parseI(json['activeOrdersCount'] ?? json['activeCampaigns'], 0);
    final compCmp = parseI(json['completedOrdersCount'] ?? json['completedCampaigns'], 0);
    final compTasks = parseI(json['totalTasksCompleted'] ?? json['completedTasks'], 0);
    final pendTasks = parseI(json['pendingTasks'], 0);
    final inProgTasks = parseI(json['inProgressTasks'], 0);

    final double completionPct = (totalCmp > 0)
        ? (compCmp / totalCmp * 100.0)
        : parseD(json['overallCompletion'], 0.0);

    final rawRecent = json['recentCampaigns'] as List<dynamic>?;
    final List<CampaignSummaryModel> recent = rawRecent != null
        ? rawRecent.map((e) => CampaignSummaryModel.fromJson(Map<String, dynamic>.from(e as Map))).toList()
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
