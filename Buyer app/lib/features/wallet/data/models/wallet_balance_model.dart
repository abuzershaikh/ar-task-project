import '../../domain/entities/wallet_balance.dart';

class WalletBalanceModel extends WalletBalance {
  const WalletBalanceModel({
    required super.totalBalance,
    required super.availableBalance,
    required super.reservedBalance,
    super.currency,
    required super.lastUpdated,
  });

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    final avail = ((json['availableBalance'] ?? json['available'] ?? json['balance'] as num?) ?? 0.0).toDouble();
    final reserved = ((json['reservedBalance'] ?? json['reserved'] as num?) ?? 0.0).toDouble();
    final total = ((json['totalBalance'] ?? json['total'] as num?) ?? (avail + reserved)).toDouble();

    return WalletBalanceModel(
      totalBalance: total,
      availableBalance: avail,
      reservedBalance: reserved,
      currency: (json['currency'] ?? 'INR').toString(),
      lastUpdated: json['lastUpdated'] != null ? DateTime.tryParse(json['lastUpdated'].toString()) ?? DateTime.now() : DateTime.now(),
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
