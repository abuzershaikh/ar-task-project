import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/usecases/get_dashboard_data_usecase.dart';

// Events
abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDashboardDataEvent extends DashboardEvent {}

class RefreshDashboardEvent extends DashboardEvent {}

// States
abstract class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardData dashboardData;

  DashboardLoaded(this.dashboardData);

  @override
  List<Object?> get props => [dashboardData];
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardDataUseCase getDashboardDataUseCase;

  DashboardBloc(this.getDashboardDataUseCase) : super(DashboardInitial()) {
    on<LoadDashboardDataEvent>(_onLoadDashboardData);
    on<RefreshDashboardEvent>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardDataEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    final result = await getDashboardDataUseCase();

    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (data) => emit(DashboardLoaded(data)),
    );
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    // Keep current data while refreshing
    final currentState = state;
    if (currentState is DashboardLoaded) {
      final result = await getDashboardDataUseCase();
      result.fold(
        (failure) => emit(DashboardError(failure.message)),
        (data) => emit(DashboardLoaded(data)),
      );
    } else {
      add(LoadDashboardDataEvent());
    }
  }
}
