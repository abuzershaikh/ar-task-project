class WorkerModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String status;
  final String kycStatus;
  final double rating;
  final int completedTasks;
  final double totalEarnings;
  final String tier;
  final DateTime? createdAt;

  WorkerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.kycStatus,
    required this.rating,
    required this.completedTasks,
    required this.totalEarnings,
    required this.tier,
    this.createdAt,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] : {};
    return WorkerModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? user['id']?.toString() ?? '',
      name: json['name'] ?? user['name'] ?? user['email']?.toString().split('@').first ?? 'Worker',
      email: json['email'] ?? user['email'] ?? '',
      phone: json['phone'] ?? user['phone'] ?? '',
      status: json['status']?.toString().toUpperCase() ?? 'ACTIVE',
      kycStatus: json['kycStatus']?.toString().toUpperCase() ?? 'VERIFIED',
      rating: double.tryParse(json['rating']?.toString() ?? '4.8') ?? 4.8,
      completedTasks: json['completedTasks'] ?? json['totalCompletedTasks'] ?? 0,
      totalEarnings: double.tryParse(json['totalEarnings']?.toString() ?? '0.0') ?? 0.0,
      tier: json['tier']?.toString() ?? 'Silver',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}
