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
    return AnalyticsModel(
      totalSpent: ((json['totalSpent'] ?? json['spent'] as num?) ?? 0.0).toDouble(),
      totalCampaigns: ((json['totalCampaigns'] ?? json['totalOrders'] as num?) ?? 0).toInt(),
      activeCampaigns: ((json['activeCampaigns'] as num?) ?? 0).toInt(),
      completedCampaigns: ((json['completedCampaigns'] as num?) ?? 0).toInt(),
      totalTasks: ((json['totalTasks'] as num?) ?? 0).toInt(),
      conversionRate: ((json['conversionRate'] as num?) ?? 0.0).toDouble(),
      monthlyBreakdown: (json['monthlyBreakdown'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}
