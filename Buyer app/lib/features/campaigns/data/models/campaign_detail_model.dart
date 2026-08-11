import '../../domain/entities/campaign_detail.dart';

// @JsonSerializable() - Commented for build
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
    return CampaignDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      serviceId: json['serviceId'] as String,
      serviceName: json['serviceName'] as String,
      status: json['status'] as String,
      totalTasks: json['totalTasks'] as int,
      completedTasks: json['completedTasks'] as int,
      inProgressTasks: json['inProgressTasks'] as int,
      pendingTasks: json['pendingTasks'] as int,
      rejectedTasks: json['rejectedTasks'] as int,
      underReviewTasks: json['underReviewTasks'] as int,
      completionPercentage: (json['completionPercentage'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num).toDouble(),
      paymentStatus: json['paymentStatus'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      originalDeadline: json['originalDeadline'] != null ? DateTime.parse(json['originalDeadline'] as String) : null,
      currentDeadline: json['currentDeadline'] != null ? DateTime.parse(json['currentDeadline'] as String) : null,
      remainingTime: json['remainingTime'] as String?,
      instructions: json['instructions'] as String,
      proofRequirements: (json['proofRequirements'] as List<dynamic>).cast<String>(),
      acceptWithinHours: json['acceptWithinHours'] as int,
      completeWithinHours: json['completeWithinHours'] as int,
      reviewMode: json['reviewMode'] as String,
      approvalRate: (json['approvalRate'] as num).toDouble(),
      rejectionRate: (json['rejectionRate'] as num).toDouble(),
      averageReviewTimeMinutes: json['averageReviewTimeMinutes'] as int,
      pendingReviews: json['pendingReviews'] as int,
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

// @JsonSerializable() - Commented for build
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
    return DeadlineExtensionModel(
      originalDeadline: DateTime.parse(json['originalDeadline'] as String),
      newDeadline: DateTime.parse(json['newDeadline'] as String),
      extensionHours: json['extensionHours'] as int,
      reason: json['reason'] as String,
      extendedAt: DateTime.parse(json['extendedAt'] as String),
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
