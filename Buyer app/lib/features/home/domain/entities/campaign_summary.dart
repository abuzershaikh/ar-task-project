import 'package:equatable/equatable.dart';

class CampaignSummary extends Equatable {
  final String id;
  final String name;
  final String serviceType;
  final String status;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int inProgressTasks;
  final double amount;
  final String? expiresIn;
  final DateTime createdAt;

  const CampaignSummary({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.status,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.inProgressTasks,
    this.amount = 0.0,
    this.expiresIn,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    serviceType,
    status,
    totalTasks,
    completedTasks,
    pendingTasks,
    inProgressTasks,
    amount,
    expiresIn,
    createdAt,
  ];
}
