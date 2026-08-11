import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeInitial()) {
    on<LoadHomeDashboardEvent>(_onLoadHomeDashboard);
    on<RefreshHomeDashboardEvent>(_onRefreshHomeDashboard);
  }

  Future<void> _onLoadHomeDashboard(
    LoadHomeDashboardEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());

    // TODO: Replace with actual API calls
    await Future.delayed(const Duration(seconds: 1));

    emit(HomeLoaded(
      activeCampaigns: 12,
      completedCampaigns: 38,
      totalTasks: 5000,
      completedTasks: 4280,
      completionPercentage: 85.6,
      totalSpent: 124500,
      thisMonthSpent: 28500,
      monthlyGrowth: 12.0,
      pendingReviews: 23,
      recentCampaigns: _getMockCampaigns(),
    ));
  }

  Future<void> _onRefreshHomeDashboard(
    RefreshHomeDashboardEvent event,
    Emitter<HomeState> emit,
  ) async {
    add(const LoadHomeDashboardEvent());
  }

  List<CampaignSummary> _getMockCampaigns() {
    return [
      const CampaignSummary(
        id: 'CAMP-001',
        name: 'Product Testing',
        completed: 320,
        total: 500,
        percentage: 64.0,
        amount: 12500,
        status: 'active',
        remainingTime: '1d 8h',
      ),
      const CampaignSummary(
        id: 'CAMP-002',
        name: 'Review Campaign',
        completed: 180,
        total: 200,
        percentage: 90.0,
        amount: 5000,
        status: 'active',
        remainingTime: '4h 30m',
      ),
      const CampaignSummary(
        id: 'CAMP-003',
        name: 'Survey Collection',
        completed: 450,
        total: 1000,
        percentage: 45.0,
        amount: 15000,
        status: 'active',
        remainingTime: '2d 12h',
      ),
    ];
  }
}
