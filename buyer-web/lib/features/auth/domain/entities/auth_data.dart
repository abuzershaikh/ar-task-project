import 'package:equatable/equatable.dart';

class AuthData extends Equatable {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String email;
  final String businessName;

  const AuthData({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
    required this.businessName,
  });

  @override
  List<Object?> get props => [accessToken, refreshToken, userId, email, businessName];
}
