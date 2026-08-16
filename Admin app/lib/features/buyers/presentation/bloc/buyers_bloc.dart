import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/buyers_repository.dart';
import '../../data/models/buyer_model.dart';

abstract class BuyersEvent {}
class LoadBuyersEvent extends BuyersEvent {}
class RefreshBuyersEvent extends BuyersEvent {}
class LoadBuyerDetailEvent extends BuyersEvent {
  final String buyerId;
  LoadBuyerDetailEvent(this.buyerId);
}
class RefreshBuyerDetailEvent extends BuyersEvent {
  final String buyerId;
  RefreshBuyerDetailEvent(this.buyerId);
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
class BuyerDetailLoading extends BuyersLoaded {
  BuyerDetailLoading(List<BuyerModel> buyers) : super(buyers);
}
class BuyerDetailLoaded extends BuyersLoaded {
  final BuyerModel buyer;
  final List<dynamic> orders;
  final List<dynamic> tasks;
  final List<dynamic> payments;
  final List<dynamic> activity;
  final Map<String, dynamic> analytics;

  BuyerDetailLoaded({
    required List<BuyerModel> buyers,
    required this.buyer,
    required this.orders,
    required this.tasks,
    required this.payments,
    required this.activity,
    required this.analytics,
  }) : super(buyers);
}
class BuyersError extends BuyersState {
  final String message;
  BuyersError(this.message);
}

class BuyersBloc extends Bloc<BuyersEvent, BuyersState> {
  final BuyersRepository repository;
  List<BuyerModel> _cachedBuyers = [];

  BuyersBloc({required this.repository}) : super(BuyersInitial()) {
    on<LoadBuyersEvent>(_onLoadBuyers);
    on<RefreshBuyersEvent>(_onRefreshBuyers);
    on<LoadBuyerDetailEvent>(_onLoadBuyerDetail);
    on<RefreshBuyerDetailEvent>(_onRefreshBuyerDetail);
    on<UpdateBuyerStatusEvent>(_onUpdateStatus);
    on<AdjustBuyerBalanceEvent>(_onAdjustBalance);
  }

  Future<void> _onLoadBuyers(LoadBuyersEvent event, Emitter<BuyersState> emit) async {
    if (_cachedBuyers.isEmpty) {
      emit(BuyersLoading());
    } else {
      emit(BuyersLoaded(_cachedBuyers));
    }
    try {
      final buyers = await repository.getBuyers();
      _cachedBuyers = buyers;
      emit(BuyersLoaded(_cachedBuyers));
    } catch (e) {
      if (_cachedBuyers.isNotEmpty) {
        emit(BuyersLoaded(_cachedBuyers));
      } else {
        emit(BuyersError(e.toString()));
      }
    }
  }

  Future<void> _onRefreshBuyers(RefreshBuyersEvent event, Emitter<BuyersState> emit) async {
    try {
      final buyers = await repository.getBuyers(forceRefresh: true);
      _cachedBuyers = buyers;
      emit(BuyersLoaded(_cachedBuyers));
    } catch (e) {
      if (_cachedBuyers.isNotEmpty) {
        emit(BuyersLoaded(_cachedBuyers));
      } else {
        emit(BuyersError(e.toString()));
      }
    }
  }

  Future<void> _onLoadBuyerDetail(LoadBuyerDetailEvent event, Emitter<BuyersState> emit) async {
    emit(BuyerDetailLoading(_cachedBuyers));
    try {
      final buyer = await repository.getBuyerDetail(event.buyerId);
      final orders = await repository.getBuyerOrders(event.buyerId).catchError((_) => <dynamic>[]);
      final tasks = await repository.getBuyerTasks(event.buyerId).catchError((_) => <dynamic>[]);
      final payments = await repository.getBuyerPayments(event.buyerId).catchError((_) => <dynamic>[]);
      final activity = await repository.getBuyerActivity(event.buyerId).catchError((_) => <dynamic>[]);
      final analytics = await repository.getBuyerAnalytics(event.buyerId).catchError((_) => <String, dynamic>{});

      emit(BuyerDetailLoaded(
        buyers: _cachedBuyers,
        buyer: buyer,
        orders: orders,
        tasks: tasks,
        payments: payments,
        activity: activity,
        analytics: analytics,
      ));
    } catch (e) {
      if (_cachedBuyers.isNotEmpty) {
        emit(BuyersLoaded(_cachedBuyers));
      } else {
        emit(BuyersError(e.toString()));
      }
    }
  }

  Future<void> _onRefreshBuyerDetail(RefreshBuyerDetailEvent event, Emitter<BuyersState> emit) async {
    try {
      final buyer = await repository.getBuyerDetail(event.buyerId, forceRefresh: true);
      final orders = await repository.getBuyerOrders(event.buyerId).catchError((_) => <dynamic>[]);
      final tasks = await repository.getBuyerTasks(event.buyerId).catchError((_) => <dynamic>[]);
      final payments = await repository.getBuyerPayments(event.buyerId).catchError((_) => <dynamic>[]);
      final activity = await repository.getBuyerActivity(event.buyerId).catchError((_) => <dynamic>[]);
      final analytics = await repository.getBuyerAnalytics(event.buyerId).catchError((_) => <String, dynamic>{});

      emit(BuyerDetailLoaded(
        buyers: _cachedBuyers,
        buyer: buyer,
        orders: orders,
        tasks: tasks,
        payments: payments,
        activity: activity,
        analytics: analytics,
      ));
    } catch (e) {
      if (_cachedBuyers.isNotEmpty) {
        emit(BuyersLoaded(_cachedBuyers));
      } else {
        emit(BuyersError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateStatus(UpdateBuyerStatusEvent event, Emitter<BuyersState> emit) async {
    try {
      await repository.updateBuyerStatus(event.buyerId, event.status);
      add(LoadBuyerDetailEvent(event.buyerId));
    } catch (e) {
      if (_cachedBuyers.isNotEmpty) {
        emit(BuyersLoaded(_cachedBuyers));
      } else {
        emit(BuyersError(e.toString()));
      }
    }
  }

  Future<void> _onAdjustBalance(AdjustBuyerBalanceEvent event, Emitter<BuyersState> emit) async {
    try {
      await repository.adjustBuyerBalance(event.buyerId, event.amount, event.reason);
      add(LoadBuyerDetailEvent(event.buyerId));
    } catch (e) {
      if (_cachedBuyers.isNotEmpty) {
        emit(BuyersLoaded(_cachedBuyers));
      } else {
        emit(BuyersError(e.toString()));
      }
    }
  }
}
