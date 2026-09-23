import '../../../../core/storage/local_avatar_cache.dart';

class BuyerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String status;
  final int totalOrders;
  final int activeCampaigns;
  final double totalSpend;
  final String? avatarUrl;
  final DateTime? createdAt;

  BuyerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.totalOrders,
    required this.activeCampaigns,
    required this.totalSpend,
    this.avatarUrl,
    this.createdAt,
  });

  factory BuyerModel.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'] is Map ? json['metrics'] : {};
    final String extractedId = json['id']?.toString() ?? json['_id']?.toString() ?? '';

    String? avatar = json['avatarUrl']?.toString() ??
        json['avatar_url']?.toString() ??
        json['photoUrl']?.toString() ??
        json['user']?['avatarUrl']?.toString() ??
        json['user']?['avatar_url']?.toString() ??
        json['user']?['photoUrl']?.toString();

    // Check local cache if not present in payload
    if (avatar == null || avatar.trim().isEmpty) {
      avatar = LocalAvatarCache.getAvatarSync(extractedId);
    } else {
      LocalAvatarCache.saveAvatar(extractedId, avatar);
    }

    return BuyerModel(
      id: extractedId,
      name: json['name'] ?? json['companyName'] ?? json['email']?.toString().split('@').first ?? 'Buyer',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status']?.toString().toUpperCase() ?? 'ACTIVE',
      totalOrders: metrics['totalOrdersCount'] ?? json['totalOrders'] ?? 0,
      activeCampaigns: metrics['activeOrdersCount'] ?? json['activeCampaigns'] ?? 0,
      totalSpend: double.tryParse(metrics['totalSpend']?.toString() ?? json['totalSpend']?.toString() ?? '0.0') ?? 0.0,
      avatarUrl: avatar,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'status': status,
      'totalOrders': totalOrders,
      'activeCampaigns': activeCampaigns,
      'totalSpend': totalSpend,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  BuyerModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? status,
    int? totalOrders,
    int? activeCampaigns,
    double? totalSpend,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return BuyerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      totalOrders: totalOrders ?? this.totalOrders,
      activeCampaigns: activeCampaigns ?? this.activeCampaigns,
      totalSpend: totalSpend ?? this.totalSpend,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
