import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

import '../../domain/repositories/dashboard_repository.dart';
import '../../../../core/di/injection.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DashboardRepository repository = getIt<DashboardRepository>();

  HomeBloc() : super(const HomeInitial()) {
    on<LoadHomeDashboardEvent>(_onLoadHomeDashboard);
    on<RefreshHomeDashboardEvent>(_onRefreshHomeDashboard);
  }

  Future<void> _onLoadHomeDashboard(
    LoadHomeDashboardEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());

    try {
      final result = await repository.getDashboardData();
      
      result.fold(
        (failure) {
          emit(const HomeError('Failed to load dashboard data'));
        },
        (data) {
          emit(HomeLoaded(
            activeCampaigns: data.activeCampaigns,
            completedCampaigns: data.completedCampaigns,
            totalTasks: data.pendingTasks + data.inProgressTasks + data.completedTasks,
            completedTasks: data.completedTasks,
            completionPercentage: data.overallCompletion,
            totalSpent: data.totalSpend,
            thisMonthSpent: data.totalSpend,
            monthlyGrowth: 0.0,
            pendingReviews: data.pendingTasks,
            recentCampaigns: data.recentCampaigns.map((c) => CampaignSummary(
              id: c.id,
              name: c.name,
              completed: c.completedTasks,
              total: c.totalTasks,
              percentage: c.totalTasks > 0 ? (c.completedTasks / c.totalTasks * 100) : 0.0,
              amount: 0.0,
              status: c.status,
              remainingTime: c.expiresIn ?? '',
            )).toList(),
          ));
        }

      );
    } catch (e) {
      emit(const HomeError('An unexpected error occurred'));
    }
  }

  Future<void> _onRefreshHomeDashboard(
    RefreshHomeDashboardEvent event,
    Emitter<HomeState> emit,
  ) async {
    add(const LoadHomeDashboardEvent());
  }

  // Mock removed
}
