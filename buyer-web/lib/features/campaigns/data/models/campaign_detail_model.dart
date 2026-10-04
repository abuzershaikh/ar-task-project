import '../../domain/entities/campaign_detail.dart';

class CampaignDetailModel extends CampaignDetail {
  const CampaignDetailModel({
    required super.id,
    required super.name,
    required super.serviceId,
    required super.serviceName,
    required super.status,
    required super.totalTasks,
    required super.completedTasks,
    required super.inProgressTasks,
    required super.pendingTasks,
    required super.rejectedTasks,
    required super.underReviewTasks,
    required super.completionPercentage,
    required super.totalAmount,
    required super.spentAmount,
    required super.paymentStatus,
    required super.createdAt,
    super.originalDeadline,
    super.currentDeadline,
    super.extensions,
    super.remainingTime,
    required super.instructions,
    required super.proofRequirements,
    required super.acceptWithinHours,
    required super.completeWithinHours,
    required super.reviewMode,
    required super.approvalRate,
    required super.rejectionRate,
    required super.averageReviewTimeMinutes,
    required super.pendingReviews,
  });

  factory CampaignDetailModel.fromJson(Map<String, dynamic> json) {
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

    final total = parseI(json['totalTasks'] ?? json['totalTasksRequired'], 0);
    final completed = parseI(json['completedTasks'] ?? json['tasksCompleted'], 0);
    final inProgress = parseI(json['inProgressTasks'], 0);
    final pending = parseI(json['pendingTasks'], total - completed > 0 ? total - completed : 0);
    final rejected = parseI(json['rejectedTasks'], 0);
    final underReview = parseI(json['underReviewTasks'], 0);
    final compPct = total > 0 ? (completed / total * 100.0) : parseD(json['completionPercentage'], 0.0);

    final unitPrice = parseD(json['buyerUnitPrice'], 0.0);

    return CampaignDetailModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? 'Campaign').toString(),
      serviceId: (json['serviceId'] ?? json['taskType'] ?? json['serviceCode'] ?? '').toString(),
      serviceName: (json['serviceName'] ?? json['taskType'] ?? json['serviceCode'] ?? 'Service').toString(),
      status: (json['status'] ?? 'active').toString().toLowerCase(),
      totalTasks: total,
      completedTasks: completed,
      inProgressTasks: inProgress,
      pendingTasks: pending,
      rejectedTasks: rejected,
      underReviewTasks: underReview,
      completionPercentage: compPct,
      totalAmount: parseD(json['totalAmount'], 0.0),
      spentAmount: parseD(json['spentAmount'], completed * unitPrice),
      paymentStatus: (json['paymentStatus'] ?? 'reserved').toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      originalDeadline: json['originalDeadline'] != null ? DateTime.tryParse(json['originalDeadline'].toString()) : null,
      currentDeadline: json['currentDeadline'] != null ? DateTime.tryParse(json['currentDeadline'].toString()) : null,
      remainingTime: json['remainingTime']?.toString(),
      instructions: (json['instructions'] ?? json['description'] ?? '').toString(),
      proofRequirements: json['proofRequirements'] != null && json['proofRequirements'] is List
          ? (json['proofRequirements'] as List).map((e) => e.toString()).toList()
          : <String>[],
      acceptWithinHours: parseI(json['acceptWithinHours'] ?? json['timeToAcceptHours'], 24),
      completeWithinHours: parseI(json['completeWithinHours'] ?? json['timeToCompleteHours'], 48),
      reviewMode: (json['reviewMode'] ?? 'manual').toString(),
      approvalRate: parseD(json['approvalRate'], 100.0),
      rejectionRate: parseD(json['rejectionRate'], 0.0),
      averageReviewTimeMinutes: parseI(json['averageReviewTimeMinutes'], 30),
      pendingReviews: parseI(json['pendingReviews'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'status': status,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'inProgressTasks': inProgressTasks,
      'pendingTasks': pendingTasks,
      'rejectedTasks': rejectedTasks,
      'underReviewTasks': underReviewTasks,
      'completionPercentage': completionPercentage,
      'totalAmount': totalAmount,
      'spentAmount': spentAmount,
      'paymentStatus': paymentStatus,
      'createdAt': createdAt.toIso8601String(),
      'originalDeadline': originalDeadline?.toIso8601String(),
      'currentDeadline': currentDeadline?.toIso8601String(),
      'remainingTime': remainingTime,
      'instructions': instructions,
      'proofRequirements': proofRequirements,
      'acceptWithinHours': acceptWithinHours,
      'completeWithinHours': completeWithinHours,
      'reviewMode': reviewMode,
      'approvalRate': approvalRate,
      'rejectionRate': rejectionRate,
      'averageReviewTimeMinutes': averageReviewTimeMinutes,
      'pendingReviews': pendingReviews,
    };
  }

  CampaignDetail toEntity() => this;
}

class DeadlineExtensionModel extends DeadlineExtension {
  const DeadlineExtensionModel({
    required super.originalDeadline,
    required super.newDeadline,
    required super.extensionHours,
    required super.reason,
    required super.extendedAt,
    super.isAutomatic,
  });

  factory DeadlineExtensionModel.fromJson(Map<String, dynamic> json) {
    int parseI(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return DeadlineExtensionModel(
      originalDeadline: DateTime.tryParse(json['originalDeadline'].toString()) ?? DateTime.now(),
      newDeadline: DateTime.tryParse(json['newDeadline'].toString()) ?? DateTime.now(),
      extensionHours: parseI(json['extensionHours']),
      reason: (json['reason'] ?? '').toString(),
      extendedAt: DateTime.tryParse(json['extendedAt'].toString()) ?? DateTime.now(),
      isAutomatic: json['isAutomatic'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalDeadline': originalDeadline.toIso8601String(),
      'newDeadline': newDeadline.toIso8601String(),
      'extensionHours': extensionHours,
      'reason': reason,
      'extendedAt': extendedAt.toIso8601String(),
      'isAutomatic': isAutomatic,
    };
  }

  DeadlineExtension toEntity() => this;
}
