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
    super.amount = 0.0,
    super.expiresIn,
    required super.createdAt,
  });

  factory CampaignSummaryModel.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v, double def) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? def;
      return def;
    }

    return CampaignSummaryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      serviceType: json['serviceType'] ?? '',
      status: json['status'] ?? '',
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      pendingTasks: json['pendingTasks'] ?? 0,
      inProgressTasks: json['inProgressTasks'] ?? 0,
      amount: parseD(json['amount'] ?? json['totalAmount'], 0.0),
      expiresIn: json['expiresIn'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
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
      'amount': amount,
      'expiresIn': expiresIn,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
