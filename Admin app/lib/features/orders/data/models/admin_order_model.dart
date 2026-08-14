class AdminOrderModel {
  final String id;
  final String campaignName;
  final String buyerId;
  final String serviceType;
  final String status;
  final int totalTasks;
  final int completedTasks;
  final double rewardPerTask;
  final double totalBudget;
  final DateTime? createdAt;

  AdminOrderModel({
    required this.id,
    required this.campaignName,
    required this.buyerId,
    required this.serviceType,
    required this.status,
    required this.totalTasks,
    required this.completedTasks,
    required this.rewardPerTask,
    required this.totalBudget,
    this.createdAt,
  });

  factory AdminOrderModel.fromJson(Map<String, dynamic> json) {
    final total = json['totalTasksRequired'] ?? json['totalTasks'] ?? 0;
    final completed = json['tasksCompleted'] ?? json['completedTasks'] ?? 0;
    final reward = double.tryParse(json['rewardPerTask']?.toString() ?? '0.0') ?? 0.0;
    final budget = double.tryParse(json['totalAmount']?.toString() ?? '0.0') ?? (total * reward);

    return AdminOrderModel(
      id: json['id']?.toString() ?? '',
      campaignName: json['title'] ?? json['campaignName'] ?? json['name'] ?? 'Campaign #${json['id']?.toString().substring(0, 6)}',
      buyerId: json['buyerId']?.toString() ?? '',
      serviceType: json['serviceType']?.toString() ?? 'TASK',
      status: json['status']?.toString().toUpperCase() ?? 'ACTIVE',
      totalTasks: total,
      completedTasks: completed,
      rewardPerTask: reward,
      totalBudget: budget,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}
