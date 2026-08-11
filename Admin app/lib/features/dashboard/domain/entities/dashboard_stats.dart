import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalBuyers;
  final int activeBuyers;
  final int totalWorkers;
  final int activeWorkers;
  final int todayRevenue;
  final int workerEarnings;
  final int platformMargin;
  final int pendingPayout;
  final int activeCampaigns;
  final int activeTasks;
  final int pendingReview;
  final int allocationPending;

  const DashboardStats({
    required this.totalBuyers,
    required this.activeBuyers,
    required this.totalWorkers,
    required this.activeWorkers,
    required this.todayRevenue,
    required this.workerEarnings,
    required this.platformMargin,
    required this.pendingPayout,
    required this.activeCampaigns,
    required this.activeTasks,
    required this.pendingReview,
    required this.allocationPending,
  });

  @override
  List<Object?> get props => [
        totalBuyers,
        activeBuyers,
        totalWorkers,
        activeWorkers,
        todayRevenue,
        workerEarnings,
        platformMargin,
        pendingPayout,
        activeCampaigns,
        activeTasks,
        pendingReview,
        allocationPending,
      ];
}
