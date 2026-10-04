import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/add_balance.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/usecases/get_wallet_balance.dart';
import '../../domain/usecases/verify_balance_payment.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final GetWalletBalance getWalletBalance;
  final GetTransactions getTransactions;
  final AddBalance addBalance;
  final VerifyBalancePayment verifyBalancePayment;

  WalletBloc({
    required this.getWalletBalance,
    required this.getTransactions,
    required this.addBalance,
    required this.verifyBalancePayment,
  }) : super(const WalletInitial()) {
    on<GetBalanceEvent>(_onGetBalance);
    on<GetTransactionsEvent>(_onGetTransactions);
    on<LoadMoreTransactionsEvent>(_onLoadMoreTransactions);
    on<InitiateAddBalanceEvent>(_onInitiateAddBalance);
    on<VerifyBalancePaymentEvent>(_onVerifyBalancePayment);
    on<RefreshWalletEvent>(_onRefreshWallet);
  }

  Future<void> _onGetBalance(
    GetBalanceEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());

    final balanceResult = await getWalletBalance();
    final transactionsResult = await getTransactions(page: 1, limit: 20);

    await balanceResult.fold(
      (failure) async => emit(WalletError(failure.message)),
      (balance) async {
        await transactionsResult.fold(
          (failure) async => emit(WalletError(failure.message)),
          (transactions) async => emit(WalletLoaded(
            balance: balance,
            transactions: transactions,
            hasMore: transactions.length >= 20,
            currentPage: 1,
          )),
        );
      },
    );
  }

  Future<void> _onGetTransactions(
    GetTransactionsEvent event,
    Emitter<WalletState> emit,
  ) async {
    if (state is! WalletLoaded) {
      emit(const WalletLoading());
    }

    final result = await getTransactions(
      type: event.type,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(WalletError(failure.message)),
      (transactions) {
        if (state is WalletLoaded) {
          final currentState = state as WalletLoaded;
          emit(currentState.copyWith(
            transactions: transactions,
            currentPage: event.page,
            hasMore: transactions.length >= event.limit,
          ));
        }
      },
    );
  }

  Future<void> _onLoadMoreTransactions(
    LoadMoreTransactionsEvent event,
    Emitter<WalletState> emit,
  ) async {
    if (state is! WalletLoaded) return;

    final currentState = state as WalletLoaded;
    if (!currentState.hasMore) return;

    emit(TransactionsLoadingMore(
      balance: currentState.balance,
      transactions: currentState.transactions,
      hasMore: currentState.hasMore,
      currentPage: currentState.currentPage,
    ));

    final result = await getTransactions(
      page: currentState.currentPage + 1,
      limit: 20,
    );

    result.fold(
      (failure) => emit(WalletError(failure.message)),
      (newTransactions) {
        emit(WalletLoaded(
          balance: currentState.balance,
          transactions: [...currentState.transactions, ...newTransactions],
          currentPage: currentState.currentPage + 1,
          hasMore: newTransactions.length >= 20,
        ));
      },
    );
  }

  Future<void> _onInitiateAddBalance(
    InitiateAddBalanceEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());

    final result = await addBalance(event.amount);

    result.fold(
      (failure) => emit(WalletError(failure.message)),
      (paymentData) => emit(AddBalanceInitiated(paymentData)),
    );
  }

  Future<void> _onVerifyBalancePayment(
    VerifyBalancePaymentEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(const BalancePaymentVerifying());

    final result = await verifyBalancePayment(event.paymentId);

    result.fold(
      (failure) => emit(WalletError(failure.message)),
      (updatedBalance) => emit(BalancePaymentVerified(updatedBalance)),
    );
  }

  Future<void> _onRefreshWallet(
    RefreshWalletEvent event,
    Emitter<WalletState> emit,
  ) async {
    add(const GetBalanceEvent());
  }
}
