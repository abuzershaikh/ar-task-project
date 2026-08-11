












import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalWorkers;
  final int activeWorkers;
  final int totalBuyers;
  final int activeBuyers;
  final int activeCampaigns;
  final int completedCampaigns;
  final int pendingReviews;
  final int pendingKyc;
  final int pendingPayouts;
  final double grossVolume;
  final double platformMargin;

  const DashboardStats({
    required this.totalWorkers,
    required this.activeWorkers,
    required this.totalBuyers,
    required this.activeBuyers,
    required this.activeCampaigns,
    required this.completedCampaigns,
    required this.pendingReviews,
    required this.pendingKyc,
    required this.pendingPayouts,
    required this.grossVolume,
    required this.platformMargin,
  });

  @override
  List<Object?> get props => [
        totalWorkers,
        activeWorkers,
        totalBuyers,
        activeBuyers,
        activeCampaigns,
        completedCampaigns,
        pendingReviews,
        pendingKyc,
        pendingPayouts,
        grossVolume,
        platformMargin,
      ];
}
