import 'package:equatable/equatable.dart';
import '../../../../core/constants/enums.dart';

class AdminUser extends Equatable {
  final String id;
  final String email;
  final String name;
  final AdminRole role;
  final String? phone;
  final String? avatar;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.avatar,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        role,
        phone,
        avatar,
        isActive,
        createdAt,
        lastLoginAt,
      ];
}
