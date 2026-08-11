import '../../../../core/constants/enums.dart';
import '../../domain/entities/admin_user.dart';

class AdminUserModel extends AdminUser {
  const AdminUserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.phone,
    super.avatar,
    super.isActive,
    required super.createdAt,
    super.lastLoginAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    AdminRole parsedRole = AdminRole.superAdmin;
    if (json['role'] != null) {
      final roleStr = json['role'].toString().toLowerCase();
      parsedRole = AdminRole.values.firstWhere(
        (r) => r.name.toLowerCase() == roleStr || r.toString().toLowerCase().contains(roleStr),
        orElse: () => AdminRole.superAdmin,
      );
    }

    return AdminUserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? json['fullName'] as String? ?? '',
      role: parsedRole,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      isActive: json['status'] == 'ACTIVE' || json['isActive'] == true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      lastLoginAt: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'phone': phone,
      'avatar': avatar,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  AdminUser toEntity() {
    return AdminUser(
      id: id,
      email: email,
      name: name,
      role: role,
      phone: phone,
      avatar: avatar,
      isActive: isActive,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }
}
