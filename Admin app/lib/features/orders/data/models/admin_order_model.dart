class AdminOrderModel {
  final String id;
  final String campaignName;
  final String buyerId;
  final String buyerName;
  final String buyerEmail;
  final String serviceType;
  final String status;
  final int totalTasks;
  final int completedTasks;
  final double rewardPerTask;
  final double buyerUnitPrice;
  final double platformMargin;
  final double workerReward;
  final double totalBudget;
  final DateTime? createdAt;

  AdminOrderModel({
    required this.id,
    required this.campaignName,
    required this.buyerId,
    required this.buyerName,
    required this.buyerEmail,
    required this.serviceType,
    required this.status,
    required this.totalTasks,
    required this.completedTasks,
    required this.rewardPerTask,
    required this.buyerUnitPrice,
    required this.platformMargin,
    required this.workerReward,
    required this.totalBudget,
    this.createdAt,
  });

  factory AdminOrderModel.fromJson(Map<String, dynamic> json) {
    final total = json['totalTasksRequired'] ?? json['totalTasks'] ?? 0;
    final completed = json['tasksCompleted'] ?? json['completedTasks'] ?? 0;
    final reward = double.tryParse(json['rewardPerTask']?.toString() ?? '0.0') ?? 0.0;
    final budget = double.tryParse(json['totalAmount']?.toString() ?? '0.0') ?? (total * reward);

    final rawBuyerName = json['buyerName'] ?? json['buyer']?['name'];
    final rawBuyerEmail = json['buyerEmail'] ?? json['buyer']?['email'] ?? '';
    final fallbackName = rawBuyerEmail.isNotEmpty 
        ? rawBuyerEmail.split('@').first 
        : (json['buyerId'] != null && json['buyerId'].toString().isNotEmpty ? 'Buyer #${json['buyerId'].toString().substring(0, 6)}' : 'Direct Buyer');

    final buyerPrice = double.tryParse(json['buyerUnitPrice']?.toString() ?? '') ?? (reward > 0 ? reward * 1.3 : 0.0);
    final margin = double.tryParse(json['platformMarginSnapshot']?.toString() ?? '') ?? (reward > 0 ? reward * 0.3 : 0.0);
    final workerSnap = double.tryParse(json['workerRewardSnapshot']?.toString() ?? '') ?? reward;

    return AdminOrderModel(
      id: json['id']?.toString() ?? '',
      campaignName: json['title'] ?? json['campaignName'] ?? json['name'] ?? 'Campaign #${json['id']?.toString().substring(0, 6)}',
      buyerId: json['buyerId']?.toString() ?? '',
      buyerName: rawBuyerName?.toString() ?? fallbackName,
      buyerEmail: rawBuyerEmail.toString(),
      serviceType: json['serviceType'] ?? json['taskType'] ?? 'TASK',
      status: json['status']?.toString().toUpperCase() ?? 'ACTIVE',
      totalTasks: total,
      completedTasks: completed,
      rewardPerTask: reward,
      buyerUnitPrice: buyerPrice,
      platformMargin: margin,
      workerReward: workerSnap,
      totalBudget: budget,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

