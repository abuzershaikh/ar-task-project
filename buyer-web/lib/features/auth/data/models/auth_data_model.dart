import '../../domain/entities/auth_data.dart';

class AuthDataModel extends AuthData {
  const AuthDataModel({
    required super.accessToken,
    required super.refreshToken,
    required super.userId,
    required super.email,
    required super.businessName,
  });

  factory AuthDataModel.fromJson(Map<String, dynamic> json) {
    return AuthDataModel(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      businessName: json['businessName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'userId': userId,
      'email': email,
      'businessName': businessName,
    };
  }
}
