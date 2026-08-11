import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/dashboard_stats.dart';

part 'dashboard_stats_model.g.dart';

@JsonSerializable()
class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.totalBuyers,
    required super.activeBuyers,
    required super.totalWorkers,
    required super.activeWorkers,
    required super.todayRevenue,
    required super.workerEarnings,
    required super.platformMargin,
    required super.pendingPayout,
    required super.activeCampaigns,
    required super.activeTasks,
    required super.pendingReview,
    required super.allocationPending,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardStatsModelToJson(this);

  DashboardStats toEntity() {
    return DashboardStats(
      totalBuyers: totalBuyers,
      activeBuyers: activeBuyers,
      totalWorkers: totalWorkers,
      activeWorkers: activeWorkers,
      todayRevenue: todayRevenue,
      workerEarnings: workerEarnings,
      platformMargin: platformMargin,
      pendingPayout: pendingPayout,
      activeCampaigns: activeCampaigns,
      activeTasks: activeTasks,
      pendingReview: pendingReview,
      allocationPending: allocationPending,
    );
  }
}
