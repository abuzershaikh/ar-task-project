import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/dashboard_repository.dart';

// Events
abstract class DashboardEvent {}
class LoadDashboardEvent extends DashboardEvent {}
class RefreshDashboardEvent extends DashboardEvent {}

// States
abstract class DashboardState {}
class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  final Map<String, dynamic> data;
  final Map<String, dynamic> financial;

  DashboardLoaded({required this.data, required this.financial});
}
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}

// Bloc
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;

  DashboardBloc({required this.repository}) : super(DashboardInitial()) {
    on<LoadDashboardEvent>(_onLoadDashboard);
    on<RefreshDashboardEvent>(_onLoadDashboard); // Same logic for refresh
  }

  Future<void> _onLoadDashboard(
    DashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final data = await repository.getMasterDashboard();
      final financial = await repository.getEarningsDashboard();
      emit(DashboardLoaded(data: data, financial: financial));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
