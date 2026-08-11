import 'package:equatable/equatable.dart';

/// Campaign detail entity with comprehensive information
/// 
/// Used in dedicated Campaign Detail Screen with tabs:
/// - Overview: Progress, status, deadline
/// - Tasks: Task list with filters
/// - Reviews: Pending submissions
/// - Activity: Timeline of events
/// - Analytics: Campaign-specific metrics
class CampaignDetail extends Equatable {
  final String id;
  final String name;
  final String serviceId;
  final String serviceName;
  final String status; // 'active', 'paused', 'completed', 'cancelled'
  
  // Progress
  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final int pendingTasks;
  final int rejectedTasks;
  final int underReviewTasks;
  final double completionPercentage;
  
  // Financial
  final double totalAmount;
  final double spentAmount;
  final String paymentStatus; // 'reserved', 'captured', 'released'
  
  // Timing
  final DateTime createdAt;
  final DateTime? originalDeadline;
  final DateTime? currentDeadline;
  final List<DeadlineExtension>? extensions;
  final String? remainingTime; // "1d 8h" or "Expired"
  
  // Campaign settings
  final String instructions;
  final List<String> proofRequirements;
  final int acceptWithinHours;
  final int completeWithinHours;
  final String reviewMode; // 'manual', 'auto'
  
  // Metrics
  final double approvalRate;
  final double rejectionRate;
  final int averageReviewTimeMinutes;
  final int pendingReviews;

  const CampaignDetail({
    required this.id,
    required this.name,
    required this.serviceId,
    required this.serviceName,
    required this.status,
    required this.totalTasks,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.pendingTasks,
    required this.rejectedTasks,
    required this.underReviewTasks,
    required this.completionPercentage,
    required this.totalAmount,
    required this.spentAmount,
    required this.paymentStatus,
    required this.createdAt,
    this.originalDeadline,
    this.currentDeadline,
    this.extensions,
    this.remainingTime,
    required this.instructions,
    required this.proofRequirements,
    required this.acceptWithinHours,
    required this.completeWithinHours,
    required this.reviewMode,
    required this.approvalRate,
    required this.rejectionRate,
    required this.averageReviewTimeMinutes,
    required this.pendingReviews,
  });

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get hasExtensions => extensions != null && extensions!.isNotEmpty;
  bool get hasPendingReviews => pendingReviews > 0;

  @override
  List<Object?> get props => [
        id,
        name,
        serviceId,
        serviceName,
        status,
        totalTasks,
        completedTasks,
        inProgressTasks,
        pendingTasks,
        rejectedTasks,
        underReviewTasks,
        completionPercentage,
        totalAmount,
        spentAmount,
        paymentStatus,
        createdAt,
        originalDeadline,
        currentDeadline,
        extensions,
        remainingTime,
        instructions,
        proofRequirements,
        acceptWithinHours,
        completeWithinHours,
        reviewMode,
        approvalRate,
        rejectionRate,
        averageReviewTimeMinutes,
        pendingReviews,
      ];
}

/// Deadline extension record
class DeadlineExtension extends Equatable {
  final DateTime originalDeadline;
  final DateTime newDeadline;
  final int extensionHours;
  final String reason;
  final DateTime extendedAt;
  final bool isAutomatic;

  const DeadlineExtension({
    required this.originalDeadline,
    required this.newDeadline,
    required this.extensionHours,
    required this.reason,
    required this.extendedAt,
    this.isAutomatic = true,
  });

  @override
  List<Object?> get props => [
        originalDeadline,
        newDeadline,
        extensionHours,
        reason,
        extendedAt,
        isAutomatic,
      ];
}
