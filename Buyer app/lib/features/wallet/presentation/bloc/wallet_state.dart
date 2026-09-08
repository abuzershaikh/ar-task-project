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
  final String? activeType;
  final bool isFiltering;

  const WalletLoaded({
    required this.balance,
    required this.transactions,
    this.hasMore = true,
    this.currentPage = 1,
    this.activeType,
    this.isFiltering = false,
  });

  @override
  List<Object?> get props => [balance, transactions, hasMore, currentPage, activeType, isFiltering];

  WalletLoaded copyWith({
    WalletBalance? balance,
    List<Transaction>? transactions,
    bool? hasMore,
    int? currentPage,
    String? activeType,
    bool clearActiveType = false,
    bool? isFiltering,
  }) {
    return WalletLoaded(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      activeType: clearActiveType ? null : (activeType ?? this.activeType),
      isFiltering: isFiltering ?? this.isFiltering,
    );
  }
}

class TransactionsLoadingMore extends WalletLoaded {
  const TransactionsLoadingMore({
    required super.balance,
    required super.transactions,
    required super.hasMore,
    required super.currentPage,
    super.activeType,
    super.isFiltering,
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
