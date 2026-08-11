// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardStatsModel _$DashboardStatsModelFromJson(Map<String, dynamic> json) =>
    DashboardStatsModel(
      totalBuyers: (json['total_buyers'] as num).toInt(),
      activeBuyers: (json['active_buyers'] as num).toInt(),
      totalWorkers: (json['total_workers'] as num).toInt(),
      activeWorkers: (json['active_workers'] as num).toInt(),
      todayRevenue: (json['today_revenue'] as num).toInt(),
      workerEarnings: (json['worker_earnings'] as num).toInt(),
      platformMargin: (json['platform_margin'] as num).toInt(),
      pendingPayout: (json['pending_payout'] as num).toInt(),
      activeCampaigns: (json['active_campaigns'] as num).toInt(),
      activeTasks: (json['active_tasks'] as num).toInt(),
      pendingReview: (json['pending_review'] as num).toInt(),
      allocationPending: (json['allocation_pending'] as num).toInt(),
    );

Map<String, dynamic> _$DashboardStatsModelToJson(
        DashboardStatsModel instance) =>
    <String, dynamic>{
      'total_buyers': instance.totalBuyers,
      'active_buyers': instance.activeBuyers,
      'total_workers': instance.totalWorkers,
      'active_workers': instance.activeWorkers,
      'today_revenue': instance.todayRevenue,
      'worker_earnings': instance.workerEarnings,
      'platform_margin': instance.platformMargin,
      'pending_payout': instance.pendingPayout,
      'active_campaigns': instance.activeCampaigns,
      'active_tasks': instance.activeTasks,
      'pending_review': instance.pendingReview,
      'allocation_pending': instance.allocationPending,
    };
