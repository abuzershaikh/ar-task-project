import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/orders_repository.dart';
import '../../data/models/admin_order_model.dart';

abstract class OrdersEvent {}
class LoadOrdersEvent extends OrdersEvent {}
class LoadOrderDetailEvent extends OrdersEvent {
  final String orderId;
  LoadOrderDetailEvent(this.orderId);
}
class PauseOrderEvent extends OrdersEvent {
  final String orderId;
  PauseOrderEvent(this.orderId);
}
class ResumeOrderEvent extends OrdersEvent {
  final String orderId;
  ResumeOrderEvent(this.orderId);
}
class CancelOrderEvent extends OrdersEvent {
  final String orderId;
  final String reason;
  CancelOrderEvent({required this.orderId, required this.reason});
}

abstract class OrdersState {}
class OrdersInitial extends OrdersState {}
class OrdersLoading extends OrdersState {}
class OrdersLoaded extends OrdersState {
  final List<AdminOrderModel> orders;
  OrdersLoaded(this.orders);
}
class OrderDetailLoading extends OrdersLoaded {
  OrderDetailLoading(List<AdminOrderModel> orders) : super(orders);
}
class OrderDetailLoaded extends OrdersLoaded {
  final AdminOrderModel order;
  final List<dynamic> tasks;
  final List<dynamic> submissions;

  OrderDetailLoaded({
    required List<AdminOrderModel> orders,
    required this.order,
    required this.tasks,
    required this.submissions,
  }) : super(orders);
}
class OrdersError extends OrdersState {
  final String message;
  OrdersError(this.message);
}

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrdersRepository repository;
  List<AdminOrderModel> _cachedOrders = [];

  OrdersBloc({required this.repository}) : super(OrdersInitial()) {
    on<LoadOrdersEvent>(_onLoadOrders);
    on<LoadOrderDetailEvent>(_onLoadOrderDetail);
    on<PauseOrderEvent>(_onPauseOrder);
    on<ResumeOrderEvent>(_onResumeOrder);
    on<CancelOrderEvent>(_onCancelOrder);
  }

  Future<void> _onLoadOrders(LoadOrdersEvent event, Emitter<OrdersState> emit) async {
    if (_cachedOrders.isEmpty) {
      emit(OrdersLoading());
    } else {
      emit(OrdersLoaded(_cachedOrders));
    }
    try {
      final orders = await repository.getOrders();
      _cachedOrders = orders;
      emit(OrdersLoaded(_cachedOrders));
    } catch (e) {
      if (_cachedOrders.isNotEmpty) {
        emit(OrdersLoaded(_cachedOrders));
      } else {
        emit(OrdersError(e.toString()));
      }
    }
  }

  Future<void> _onLoadOrderDetail(LoadOrderDetailEvent event, Emitter<OrdersState> emit) async {
    emit(OrderDetailLoading(_cachedOrders));
    try {
      final order = await repository.getOrderDetail(event.orderId);
      final tasks = await repository.getOrderTasks(event.orderId).catchError((_) => <dynamic>[]);
      final submissions = await repository.getOrderSubmissions(event.orderId).catchError((_) => <dynamic>[]);

      emit(OrderDetailLoaded(
        orders: _cachedOrders,
        order: order,
        tasks: tasks,
        submissions: submissions,
      ));
    } catch (e) {
      if (_cachedOrders.isNotEmpty) {
        emit(OrdersLoaded(_cachedOrders));
      } else {
        emit(OrdersError(e.toString()));
      }
    }
  }

  Future<void> _onPauseOrder(PauseOrderEvent event, Emitter<OrdersState> emit) async {
    try {
      await repository.pauseOrder(event.orderId);
      add(LoadOrderDetailEvent(event.orderId));
    } catch (e) {
      if (_cachedOrders.isNotEmpty) {
        emit(OrdersLoaded(_cachedOrders));
      } else {
        emit(OrdersError(e.toString()));
      }
    }
  }

  Future<void> _onResumeOrder(ResumeOrderEvent event, Emitter<OrdersState> emit) async {
    try {
      await repository.resumeOrder(event.orderId);
      add(LoadOrderDetailEvent(event.orderId));
    } catch (e) {
      if (_cachedOrders.isNotEmpty) {
        emit(OrdersLoaded(_cachedOrders));
      } else {
        emit(OrdersError(e.toString()));
      }
    }
  }

  Future<void> _onCancelOrder(CancelOrderEvent event, Emitter<OrdersState> emit) async {
    try {
      await repository.cancelOrder(event.orderId, event.reason);
      add(LoadOrderDetailEvent(event.orderId));
    } catch (e) {
      if (_cachedOrders.isNotEmpty) {
        emit(OrdersLoaded(_cachedOrders));
      } else {
        emit(OrdersError(e.toString()));
      }
    }
  }
}
