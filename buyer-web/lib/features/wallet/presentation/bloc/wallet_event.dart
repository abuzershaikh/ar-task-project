import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

/// Get wallet balance
class GetBalanceEvent extends WalletEvent {
  const GetBalanceEvent();
}

/// Get transaction history
class GetTransactionsEvent extends WalletEvent {
  final String? type;
  final int page;
  final int limit;

  const GetTransactionsEvent({
    this.type,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [type, page, limit];
}

/// Load more transactions
class LoadMoreTransactionsEvent extends WalletEvent {
  const LoadMoreTransactionsEvent();
}

/// Initiate add balance
class InitiateAddBalanceEvent extends WalletEvent {
  final double amount;

  const InitiateAddBalanceEvent(this.amount);

  @override
  List<Object?> get props => [amount];
}

/// Verify balance payment
class VerifyBalancePaymentEvent extends WalletEvent {
  final String paymentId;

  const VerifyBalancePaymentEvent(this.paymentId);

  @override
  List<Object?> get props => [paymentId];
}

/// Refresh wallet data
class RefreshWalletEvent extends WalletEvent {
  const RefreshWalletEvent();
}
