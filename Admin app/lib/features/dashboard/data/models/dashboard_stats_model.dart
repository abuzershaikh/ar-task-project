import '../../domain/entities/dashboard_stats.dart';

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.totalWorkers,
    required super.activeWorkers,
    required super.totalBuyers,
    required super.activeBuyers,
    required super.activeCampaigns,
    required super.completedCampaigns,
    required super.pendingReviews,
    required super.pendingKyc,
    required super.pendingPayouts,
    required super.grossVolume,
    required super.platformMargin,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalWorkers: json['totalWorkers'] as int,
      activeWorkers: json['activeWorkers'] as int,
      totalBuyers: json['totalBuyers'] as int,
      activeBuyers: json['activeBuyers'] as int,
      activeCampaigns: json['activeCampaigns'] as int,
      completedCampaigns: json['completedCampaigns'] as int,
      pendingReviews: json['pendingReviews'] as int,
      pendingKyc: json['pendingKyc'] as int,
      pendingPayouts: json['pendingPayouts'] as int,
      grossVolume: (json['grossVolume'] as num).toDouble(),
      platformMargin: (json['platformMargin'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalWorkers': totalWorkers,
      'activeWorkers': activeWorkers,
      'totalBuyers': totalBuyers,
      'activeBuyers': activeBuyers,
      'activeCampaigns': activeCampaigns,
      'completedCampaigns': completedCampaigns,
      'pendingReviews': pendingReviews,
      'pendingKyc': pendingKyc,
      'pendingPayouts': pendingPayouts,
      'grossVolume': grossVolume,
      'platformMargin': platformMargin,
    };
  }
}
