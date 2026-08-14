class BuyerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String status;
  final int totalOrders;
  final int activeCampaigns;
  final double totalSpend;
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
    this.createdAt,
  });

  factory BuyerModel.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'] is Map ? json['metrics'] : {};
    return BuyerModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? json['companyName'] ?? json['email']?.toString().split('@').first ?? 'Buyer',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status']?.toString().toUpperCase() ?? 'ACTIVE',
      totalOrders: metrics['totalOrdersCount'] ?? json['totalOrders'] ?? 0,
      activeCampaigns: metrics['activeOrdersCount'] ?? json['activeCampaigns'] ?? 0,
      totalSpend: double.tryParse(metrics['totalSpend']?.toString() ?? json['totalSpend']?.toString() ?? '0.0') ?? 0.0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}
