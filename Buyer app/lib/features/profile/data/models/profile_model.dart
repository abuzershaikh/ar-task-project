class ProfileModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String companyName;
  final String website;
  final String bio;
  final String avatarUrl;

  ProfileModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.companyName,
    required this.website,
    required this.bio,
    required this.avatarUrl,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? json['displayName'] ?? 'Buyer').toString(),
      phone: (json['phone'] ?? json['phoneNumber'] ?? '').toString(),
      companyName: (json['companyName'] ?? json['company'] ?? '').toString(),
      website: (json['website'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? json['photoURL'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'companyName': companyName,
      'website': website,
      'bio': bio,
      'avatarUrl': avatarUrl,
    };
  }
}
