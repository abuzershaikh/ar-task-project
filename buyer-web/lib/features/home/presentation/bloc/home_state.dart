import 'package:equatable/equatable.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final int activeCampaigns;
  final int completedCampaigns;
  final int totalTasks;
  final int completedTasks;
  final double completionPercentage;
  final double totalSpent;
  final double thisMonthSpent;
  final double monthlyGrowth;
  final int pendingReviews;
  final List<CampaignSummary> recentCampaigns;

  const HomeLoaded({
    required this.activeCampaigns,
    required this.completedCampaigns,
    required this.totalTasks,
    required this.completedTasks,
    required this.completionPercentage,
    required this.totalSpent,
    required this.thisMonthSpent,
    required this.monthlyGrowth,
    required this.pendingReviews,
    required this.recentCampaigns,
  });

  @override
  List<Object?> get props => [
        activeCampaigns,
        completedCampaigns,
        totalTasks,
        completedTasks,
        completionPercentage,
        totalSpent,
        thisMonthSpent,
        monthlyGrowth,
        pendingReviews,
        recentCampaigns,
      ];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

class CampaignSummary extends Equatable {
  final String id;
  final String name;
  final int completed;
  final int total;
  final double percentage;
  final double amount;
  final String status;
  final String remainingTime;

  const CampaignSummary({
    required this.id,
    required this.name,
    required this.completed,
    required this.total,
    required this.percentage,
    required this.amount,
    required this.status,
    required this.remainingTime,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        completed,
        total,
        percentage,
        amount,
        status,
        remainingTime,
      ];
}
