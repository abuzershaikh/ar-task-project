import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/wallet_balance.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final WalletBalance balance;
  final List<Transaction> transactions;
  final bool hasMore;
  final int currentPage;

  const WalletLoaded({
    required this.balance,
    required this.transactions,
    this.hasMore = true,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [balance, transactions, hasMore, currentPage];

  WalletLoaded copyWith({
    WalletBalance? balance,
    List<Transaction>? transactions,
    bool? hasMore,
    int? currentPage,
  }) {
    return WalletLoaded(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class TransactionsLoadingMore extends WalletLoaded {
  const TransactionsLoadingMore({
    required super.balance,
    required super.transactions,
    required super.hasMore,
    required super.currentPage,
  });
}

class AddBalanceInitiated extends WalletState {
  final Map<String, dynamic> paymentData;

  const AddBalanceInitiated(this.paymentData);

  @override
  List<Object?> get props => [paymentData];
}

class BalancePaymentVerifying extends WalletState {
  const BalancePaymentVerifying();
}

class BalancePaymentVerified extends WalletState {
  final WalletBalance updatedBalance;

  const BalancePaymentVerified(this.updatedBalance);

  @override
  List<Object?> get props => [updatedBalance];
}

class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);

  @override
  List<Object?> get props => [message];
}
