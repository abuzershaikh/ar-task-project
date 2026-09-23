import '../../../../core/storage/local_avatar_cache.dart';

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
  final String? avatarUrl;
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
    this.avatarUrl,
    this.createdAt,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] : {};
    final double parsedRating = double.tryParse(json['rating']?.toString() ?? '4.8') ?? 4.8;
    final dynamic rawScore = json['score'] ?? json['totalScore'] ?? json['qualityScore'];
    final double calculatedScore = rawScore != null
        ? (double.tryParse(rawScore.toString()) ?? (parsedRating * 20))
        : (parsedRating * 20);

    final String extractedId = json['id']?.toString() ?? json['_id']?.toString() ?? '';
    final String extractedUserId = json['userId']?.toString() ?? user['id']?.toString() ?? '';

    String? avatar = json['avatarUrl']?.toString() ??
        json['avatar_url']?.toString() ??
        json['photoUrl']?.toString() ??
        user['avatarUrl']?.toString() ??
        user['avatar_url']?.toString() ??
        user['photoUrl']?.toString();

    // Check local cache if not present in payload
    if (avatar == null || avatar.trim().isEmpty) {
      avatar = LocalAvatarCache.getAvatarSync(extractedId) ??
          LocalAvatarCache.getAvatarSync(extractedUserId);
    } else {
      LocalAvatarCache.saveAvatar(extractedId, avatar);
      if (extractedUserId.isNotEmpty) {
        LocalAvatarCache.saveAvatar(extractedUserId, avatar);
      }
    }

    return WorkerModel(
      id: extractedId,
      userId: extractedUserId,
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
      avatarUrl: avatar,
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
      'avatarUrl': avatarUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  WorkerModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? status,
    String? kycStatus,
    double? rating,
    int? completedTasks,
    double? totalEarnings,
    double? availableBalance,
    double? score,
    String? tier,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      kycStatus: kycStatus ?? this.kycStatus,
      rating: rating ?? this.rating,
      completedTasks: completedTasks ?? this.completedTasks,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      availableBalance: availableBalance ?? this.availableBalance,
      score: score ?? this.score,
      tier: tier ?? this.tier,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
