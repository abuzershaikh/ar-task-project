import 'package:firebase_auth/firebase_auth.dart';

class ProfileModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String companyName;
  final String website;
  final String bio;
  final String avatarUrl;
  final String billingAddress;
  final String industry;
  final int totalOrdersCount;
  final double totalSpend;
  final String createdAt;

  ProfileModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.companyName,
    required this.website,
    required this.bio,
    required this.avatarUrl,
    required this.billingAddress,
    this.industry = 'Technology & Marketing',
    this.totalOrdersCount = 0,
    this.totalSpend = 0.0,
    this.createdAt = '',
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final meta = json['metadata'] is Map<String, dynamic>
        ? json['metadata'] as Map<String, dynamic>
        : <String, dynamic>{};

    return ProfileModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['fullName'] ??
              json['name'] ??
              json['displayName'] ??
              'Buyer Account')
          .toString(),
      phone: (json['phone'] ?? json['phoneNumber'] ?? '').toString(),
      companyName:
          (json['companyName'] ?? meta['companyName'] ?? json['company'] ?? '')
              .toString(),
      website: (json['website'] ?? meta['website'] ?? '').toString(),
      bio: (json['bio'] ?? meta['bio'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ??
              meta['avatarUrl'] ??
              json['photoURL'] ??
              FirebaseAuth.instance.currentUser?.photoURL ??
              '')
          .toString(),
      billingAddress:
          (json['billingAddress'] ?? meta['billingAddress'] ?? '').toString(),
      industry:
          (json['industry'] ?? meta['industry'] ?? 'Technology & Marketing')
              .toString(),
      totalOrdersCount:
          int.tryParse((json['totalOrdersCount'] ?? 0).toString()) ?? 0,
      totalSpend: double.tryParse((json['totalSpend'] ?? 0).toString()) ?? 0.0,
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'fullName': name,
      'phone': phone,
      'companyName': companyName,
      'website': website,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'billingAddress': billingAddress,
      'industry': industry,
      'totalOrdersCount': totalOrdersCount,
      'totalSpend': totalSpend,
      'createdAt': createdAt,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? companyName,
    String? website,
    String? bio,
    String? avatarUrl,
    String? billingAddress,
    String? industry,
    int? totalOrdersCount,
    double? totalSpend,
    String? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      website: website ?? this.website,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      billingAddress: billingAddress ?? this.billingAddress,
      industry: industry ?? this.industry,
      totalOrdersCount: totalOrdersCount ?? this.totalOrdersCount,
      totalSpend: totalSpend ?? this.totalSpend,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
