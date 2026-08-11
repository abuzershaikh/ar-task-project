import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/admin_user.dart';
import '../../../../core/constants/enums.dart';

part 'admin_user_model.g.dart';

@JsonSerializable()
class AdminUserModel extends AdminUser {
  const AdminUserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    required super.isActive,
    required super.createdAt,
    super.lastLoginAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) =>
      _$AdminUserModelFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUserModelToJson(this);

  factory AdminUserModel.fromEntity(AdminUser entity) {
    return AdminUserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      role: entity.role,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      lastLoginAt: entity.lastLoginAt,
    );
  }

  AdminUser toEntity() {
    return AdminUser(
      id: id,
      email: email,
      name: name,
      role: role,
      isActive: isActive,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }
}
