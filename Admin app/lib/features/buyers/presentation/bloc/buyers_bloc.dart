import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/buyers_repository.dart';
import '../../data/models/buyer_model.dart';

abstract class BuyersEvent {}
class LoadBuyersEvent extends BuyersEvent {}
class LoadBuyerDetailEvent extends BuyersEvent {
  final String buyerId;
  LoadBuyerDetailEvent(this.buyerId);
}
class UpdateBuyerStatusEvent extends BuyersEvent {
  final String buyerId;
  final String status;
  UpdateBuyerStatusEvent({required this.buyerId, required this.status});
}
class AdjustBuyerBalanceEvent extends BuyersEvent {
  final String buyerId;
  final double amount;
  final String reason;
  AdjustBuyerBalanceEvent({required this.buyerId, required this.amount, required this.reason});
}

abstract class BuyersState {}
class BuyersInitial extends BuyersState {}
class BuyersLoading extends BuyersState {}
class BuyersLoaded extends BuyersState {
  final List<BuyerModel> buyers;
  BuyersLoaded(this.buyers);
}
class BuyerDetailLoaded extends BuyersState {
  final BuyerModel buyer;
  final List<dynamic> orders;
  final List<dynamic> tasks;
  final List<dynamic> payments;
  final List<dynamic> activity;
  final Map<String, dynamic> analytics;

  BuyerDetailLoaded({
    required this.buyer,
    required this.orders,
    required this.tasks,
    required this.payments,
    required this.activity,
    required this.analytics,
  });
}
class BuyersError extends BuyersState {
  final String message;
  BuyersError(this.message);
}

class BuyersBloc extends Bloc<BuyersEvent, BuyersState> {
  final BuyersRepository repository;

  BuyersBloc({required this.repository}) : super(BuyersInitial()) {
    on<LoadBuyersEvent>(_onLoadBuyers);
    on<LoadBuyerDetailEvent>(_onLoadBuyerDetail);
    on<UpdateBuyerStatusEvent>(_onUpdateStatus);
    on<AdjustBuyerBalanceEvent>(_onAdjustBalance);
  }

  Future<void> _onLoadBuyers(LoadBuyersEvent event, Emitter<BuyersState> emit) async {
    emit(BuyersLoading());
    try {
      final buyers = await repository.getBuyers();
      emit(BuyersLoaded(buyers));
    } catch (e) {
      emit(BuyersError(e.toString()));
    }
  }

  Future<void> _onLoadBuyerDetail(LoadBuyerDetailEvent event, Emitter<BuyersState> emit) async {
    emit(BuyersLoading());
    try {
      final buyer = await repository.getBuyerDetail(event.buyerId);
      final orders = await repository.getBuyerOrders(event.buyerId).catchError((_) => <dynamic>[]);
      final tasks = await repository.getBuyerTasks(event.buyerId).catchError((_) => <dynamic>[]);
      final payments = await repository.getBuyerPayments(event.buyerId).catchError((_) => <dynamic>[]);
      final activity = await repository.getBuyerActivity(event.buyerId).catchError((_) => <dynamic>[]);
      final analytics = await repository.getBuyerAnalytics(event.buyerId).catchError((_) => <String, dynamic>{});

      emit(BuyerDetailLoaded(
        buyer: buyer,
        orders: orders,
        tasks: tasks,
        payments: payments,
        activity: activity,
        analytics: analytics,
      ));
    } catch (e) {
      emit(BuyersError(e.toString()));
    }
  }

  Future<void> _onUpdateStatus(UpdateBuyerStatusEvent event, Emitter<BuyersState> emit) async {
    try {
      await repository.updateBuyerStatus(event.buyerId, event.status);
      add(LoadBuyerDetailEvent(event.buyerId));
    } catch (e) {
      emit(BuyersError(e.toString()));
    }
  }

  Future<void> _onAdjustBalance(AdjustBuyerBalanceEvent event, Emitter<BuyersState> emit) async {
    try {
      await repository.adjustBuyerBalance(event.buyerId, event.amount, event.reason);
      add(LoadBuyerDetailEvent(event.buyerId));
    } catch (e) {
      emit(BuyersError(e.toString()));
    }
  }
}
