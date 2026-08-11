import 'package:equatable/equatable.dart';
import '../../../../core/constants/enums.dart';

class AdminUser extends Equatable {
  final String id;
  final String email;
  final String name;
  final AdminRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        role,
        isActive,
        createdAt,
        lastLoginAt,
      ];
}
