// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUserModel _$AdminUserModelFromJson(Map<String, dynamic> json) =>
    AdminUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: $enumDecode(_$AdminRoleEnumMap, json['role']),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: json['last_login_at'] == null
          ? null
          : DateTime.parse(json['last_login_at'] as String),
    );

Map<String, dynamic> _$AdminUserModelToJson(AdminUserModel instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'email': instance.email,
    'name': instance.name,
    'role': _$AdminRoleEnumMap[instance.role]!,
    'is_active': instance.isActive,
    'created_at': instance.createdAt.toIso8601String(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('last_login_at', instance.lastLoginAt?.toIso8601String());
  return val;
}

const _$AdminRoleEnumMap = {
  AdminRole.superAdmin: 'SUPER_ADMIN',
  AdminRole.admin: 'ADMIN',
  AdminRole.operations: 'OPERATIONS',
  AdminRole.finance: 'FINANCE',
  AdminRole.kycReviewer: 'KYC_REVIEWER',
  AdminRole.support: 'SUPPORT',
};
