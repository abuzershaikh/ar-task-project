import 'package:equatable/equatable.dart';

/// Wallet balance entity with Available/Reserved split
/// 
/// Financial Flow:
/// 1. Campaign Create: Available → Reserved
/// 2. Campaign Complete: Reserved → Captured (backend)
/// 3. Campaign Cancel: Reserved → Released back to Available
class WalletBalance extends Equatable {
  /// Total balance = available + reserved
  final double totalBalance;
  
  /// Available balance that can be used for new campaigns
  final double availableBalance;
  
  /// Reserved balance locked for active campaigns
  final double reservedBalance;
  
  /// Currency code (default: INR)
  final String currency;
  
  /// Last updated timestamp
  final DateTime lastUpdated;

  const WalletBalance({
    required this.totalBalance,
    required this.availableBalance,
    required this.reservedBalance,
    this.currency = 'INR',
    required this.lastUpdated,
  });

  /// Check if buyer has sufficient balance for a campaign
  bool hasSufficientBalance(double amount) {
    return availableBalance >= amount;
  }

  /// Calculate remaining balance after campaign cost
  double getRemainingBalance(double campaignCost) {
    return availableBalance - campaignCost;
  }

  /// Check if balance is low (less than minimum threshold)
  bool isLowBalance({double threshold = 1000.0}) {
    return availableBalance < threshold;
  }

  @override
  List<Object?> get props => [
        totalBalance,
        availableBalance,
        reservedBalance,
        currency,
        lastUpdated,
      ];

  WalletBalance copyWith({
    double? totalBalance,
    double? availableBalance,
    double? reservedBalance,
    String? currency,
    DateTime? lastUpdated,
  }) {
    return WalletBalance(
      totalBalance: totalBalance ?? this.totalBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      reservedBalance: reservedBalance ?? this.reservedBalance,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
