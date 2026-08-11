import '../../domain/entities/campaign_summary.dart';

class CampaignSummaryModel extends CampaignSummary {
  const CampaignSummaryModel({
    required super.id,
    required super.name,
    required super.serviceType,
    required super.status,
    required super.totalTasks,
    required super.completedTasks,
    required super.pendingTasks,
    required super.inProgressTasks,
    super.expiresIn,
    required super.createdAt,
  });

  factory CampaignSummaryModel.fromJson(Map<String, dynamic> json) {
    return CampaignSummaryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      serviceType: json['serviceType'] ?? '',
      status: json['status'] ?? '',
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      pendingTasks: json['pendingTasks'] ?? 0,
      inProgressTasks: json['inProgressTasks'] ?? 0,
      expiresIn: json['expiresIn'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'serviceType': serviceType,
      'status': status,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'pendingTasks': pendingTasks,
      'inProgressTasks': inProgressTasks,
      'expiresIn': expiresIn,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
