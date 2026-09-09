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
  final double availableBalance;
  final double score;
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
    this.availableBalance = 0.0,
    this.score = 0.0,
    required this.tier,
    this.createdAt,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] : {};
    final double parsedRating = double.tryParse(json['rating']?.toString() ?? '4.8') ?? 4.8;
    final dynamic rawScore = json['score'] ?? json['totalScore'] ?? json['qualityScore'];
    final double calculatedScore = rawScore != null
        ? (double.tryParse(rawScore.toString()) ?? (parsedRating * 20))
        : (parsedRating * 20);

    return WorkerModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? user['id']?.toString() ?? '',
      name: json['name'] ?? user['name'] ?? user['email']?.toString().split('@').first ?? 'Worker',
      email: json['email'] ?? user['email'] ?? '',
      phone: json['phone'] ?? user['phone'] ?? '',
      status: json['status']?.toString().toUpperCase() ?? 'ACTIVE',
      kycStatus: json['kycStatus']?.toString().toUpperCase() ?? 'VERIFIED',
      rating: parsedRating,
      completedTasks: json['completedTasks'] ?? json['totalCompletedTasks'] ?? 0,
      totalEarnings: double.tryParse(json['totalEarnings']?.toString() ?? '0.0') ?? 0.0,
      availableBalance: double.tryParse(json['availableBalance']?.toString() ?? json['balance']?.toString() ?? '0.0') ?? 0.0,
      score: calculatedScore.clamp(0.0, 100.0),
      tier: json['tier']?.toString() ?? 'Silver',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'status': status,
      'kycStatus': kycStatus,
      'rating': rating,
      'completedTasks': completedTasks,
      'totalEarnings': totalEarnings,
      'availableBalance': availableBalance,
      'score': score,
      'tier': tier,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
