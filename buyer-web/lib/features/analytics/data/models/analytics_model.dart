class AnalyticsModel {
  final double totalSpent;
  final int totalCampaigns;
  final int activeCampaigns;
  final int completedCampaigns;
  final int totalTasks;
  final double conversionRate;
  final List<Map<String, dynamic>> monthlyBreakdown;

  AnalyticsModel({
    required this.totalSpent,
    required this.totalCampaigns,
    required this.activeCampaigns,
    required this.completedCampaigns,
    required this.totalTasks,
    required this.conversionRate,
    required this.monthlyBreakdown,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }
    int parseI(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return AnalyticsModel(
      totalSpent: parseD(json['totalSpent'] ?? json['spent']),
      totalCampaigns: parseI(json['totalCampaigns'] ?? json['totalOrders']),
      activeCampaigns: parseI(json['activeCampaigns']),
      completedCampaigns: parseI(json['completedCampaigns']),
      totalTasks: parseI(json['totalTasks']),
      conversionRate: parseD(json['conversionRate']),
      monthlyBreakdown: (json['monthlyBreakdown'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}
