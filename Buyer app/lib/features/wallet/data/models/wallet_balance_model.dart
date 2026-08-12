import '../../domain/entities/wallet_balance.dart';

// @JsonSerializable() - Commented for build
class WalletBalanceModel extends WalletBalance {
  const WalletBalanceModel({
    required super.totalBalance,
    required super.availableBalance,
    required super.reservedBalance,
    super.currency,
    required super.lastUpdated,
  });

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    return WalletBalanceModel(
      totalBalance: (json['totalBalance'] as num?)?.toDouble() ?? 0.0,
      availableBalance: (json['availableBalance'] as num?)?.toDouble() ?? 0.0,
      reservedBalance: (json['reservedBalance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  factory WalletBalanceModel.empty() {
    return WalletBalanceModel(
      totalBalance: 0.0,
      availableBalance: 0.0,
      reservedBalance: 0.0,
      currency: 'INR',
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBalance': totalBalance,
      'availableBalance': availableBalance,
      'reservedBalance': reservedBalance,
      'currency': currency,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory WalletBalanceModel.fromEntity(WalletBalance entity) {
    return WalletBalanceModel(
      totalBalance: entity.totalBalance,
      availableBalance: entity.availableBalance,
      reservedBalance: entity.reservedBalance,
      currency: entity.currency,
      lastUpdated: entity.lastUpdated,
    );
  }

  WalletBalance toEntity() {
    return WalletBalance(
      totalBalance: totalBalance,
      availableBalance: availableBalance,
      reservedBalance: reservedBalance,
      currency: currency,
      lastUpdated: lastUpdated,
    );
  }
}
