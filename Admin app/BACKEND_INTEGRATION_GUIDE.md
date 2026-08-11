# Backend Integration Implementation Guide

This guide provides complete implementation for backend integration with BLoC state management.

## 📁 File Structure to Create

```
lib/
├── features/
│   ├── dashboard/
│   │   ├── data/
│   │   │   ├── models/dashboard_stats_model.dart ✅
│   │   │   ├── datasources/dashboard_remote_datasource.dart
│   │   │   └── repositories/dashboard_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/dashboard_stats.dart ✅
│   │   │   ├── repositories/dashboard_repository.dart
│   │   │   └── usecases/get_dashboard_stats_usecase.dart
│   │   └── presentation/
│   │       └── bloc/dashboard_bloc.dart
│   │
│   ├── workers/
│   │   ├── data/
│   │   │   ├── models/worker_model.dart
│   │   │   ├── datasources/workers_remote_datasource.dart
│   │   │   └── repositories/workers_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/worker.dart
│   │   │   ├── repositories/workers_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_workers_usecase.dart
│   │   │       ├── get_worker_detail_usecase.dart
│   │   │       └── update_worker_status_usecase.dart
│   │   └── presentation/
│   │       └── bloc/workers_bloc.dart
│   │
│   └── orders/
│       ├── data/
│       │   ├── models/
│       │   │   ├── order_model.dart
│       │   │   └── task_model.dart
│       │   ├── datasources/orders_remote_datasource.dart
│       │   └── repositories/orders_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── order.dart
│       │   │   └── task.dart
│       │   ├── repositories/orders_repository.dart
│       │   └── usecases/
│       │       ├── get_orders_usecase.dart
│       │       └── get_order_detail_usecase.dart
│       └── presentation/
│           └── bloc/orders_bloc.dart
```

## 🔧 Implementation Steps

### Step 1: API Endpoints Configuration

Update `lib/core/network/api_endpoints.dart`:

```dart
class ApiEndpoints {
  // Dashboard
  static const String dashboard = '/admin/dashboard';
  
  // Workers
  static const String workers = '/admin/workers';
  static String workerDetail(String id) => '/admin/workers/$id';
  static String workerStatus(String id) => '/admin/workers/$id/status';
  
  // Buyers
  static const String buyers = '/admin/buyers';
  static String buyerDetail(String id) => '/admin/buyers/$id';
  static String buyerCredit(String id) => '/admin/buyers/$id/credit';
  
  // Orders
  static const String orders = '/admin/orders';
  static String orderDetail(String id) => '/admin/orders/$id';
  static String orderStatus(String id) => '/admin/orders/$id/status';
  
  // Reviews
  static const String pendingReviews = '/admin/reviews/pending';
  static String reviewDecision(String id) => '/admin/reviews/$id/decision';
  
  // KYC
  static const String pendingKyc = '/admin/kyc/pending';
  static String kycDecision(String id) => '/admin/kyc/$id/decision';
  
  // Payouts
  static const String pendingPayouts = '/admin/payouts/pending';
  static String payoutApprove(String id) => '/admin/payouts/$id/approve';
  static String payoutReject(String id) => '/admin/payouts/$id/reject';
  
  // Audit Logs
  static const String auditLogs = '/admin/audit-logs';
  
  // Services
  static const String services = '/admin/services';
  static String servicePricing(String id) => '/admin/services/$id/pricing';
}
```

### Step 2: Dashboard Repository Implementation

**File: `lib/features/dashboard/domain/repositories/dashboard_repository.dart`**

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardStats>> getDashboardStats();
}
```

**File: `lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart`**

```dart
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/dashboard_stats_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStatsModel> getDashboardStats();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient dioClient;

  DashboardRemoteDataSourceImpl(this.dioClient);

  @override
  Future<DashboardStatsModel> getDashboardStats() async {
    try {
      final response = await dioClient.get(ApiEndpoints.dashboard);
      
      if (response.statusCode == 200) {
        return DashboardStatsModel.fromJson(response.data['data']);
      } else {
        throw ServerException('Failed to fetch dashboard stats');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    }
  }
}
```

**File: `lib/features/dashboard/data/repositories/dashboard_repository_impl.dart`**

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, DashboardStats>> getDashboardStats() async {
    try {
      final result = await remoteDataSource.getDashboardStats();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }
}
```

### Step 3: Dashboard Use Case

**File: `lib/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart`**

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardStatsUseCase {
  final DashboardRepository repository;

  GetDashboardStatsUseCase(this.repository);

  Future<Either<Failure, DashboardStats>> call() async {
    return await repository.getDashboardStats();
  }
}
```

### Step 4: Dashboard BLoC Implementation

**File: `lib/features/dashboard/presentation/bloc/dashboard_bloc.dart`**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/usecases/get_dashboard_stats_usecase.dart';

// Events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardStatsRequested extends DashboardEvent {
  const DashboardStatsRequested();
}

class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
}

// States
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;

  const DashboardLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardStatsUseCase getDashboardStats;

  DashboardBloc({
    required this.getDashboardStats,
  }) : super(DashboardInitial()) {
    on<DashboardStatsRequested>(_onDashboardStatsRequested);
    on<DashboardRefreshed>(_onDashboardRefreshed);
  }

  Future<void> _onDashboardStatsRequested(
    DashboardStatsRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    
    final result = await getDashboardStats();
    
    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (stats) => emit(DashboardLoaded(stats)),
    );
  }

  Future<void> _onDashboardRefreshed(
    DashboardRefreshed event,
    Emitter<DashboardState> emit,
  ) async {
    final result = await getDashboardStats();
    
    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (stats) => emit(DashboardLoaded(stats)),
    );
  }
}
```

### Step 5: Update Dashboard Screen with BLoC

**Update: `lib/features/dashboard/presentation/pages/dashboard_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/kpi_card.dart';
import '../widgets/action_banner.dart';
import '../widgets/quick_action_button.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DashboardBloc>()..add(const DashboardStatsRequested()),
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Command Center'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              backgroundColor: AppColors.white.withOpacity(0.2),
              child: const Icon(Icons.person, color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<DashboardBloc>().add(const DashboardRefreshed());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is DashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardBloc>().add(const DashboardRefreshed());
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Environment Switcher
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 16, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Production',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Urgent Action Banners
                    ActionBanner(
                      icon: Icons.verified_user,
                      text: '${state.stats.pendingKyc} Pending KYC Requests',
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 8),
                    ActionBanner(
                      icon: Icons.rate_review,
                      text: '${state.stats.pendingReviews} Task Reviews Needed',
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 8),
                    ActionBanner(
                      icon: Icons.account_balance_wallet,
                      text: '${state.stats.pendingPayouts} Pending Payouts',
                      color: AppColors.info,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // KPI Cards Grid
                    const Text(
                      'Master KPIs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.4,
                      children: [
                        KpiCard(
                          title: 'Total Workers',
                          value: '${state.stats.totalWorkers}',
                          subtitle: '${state.stats.activeWorkers} Active',
                          icon: Icons.people,
                          color: AppColors.primary,
                        ),
                        KpiCard(
                          title: 'Total Buyers',
                          value: '${state.stats.totalBuyers}',
                          subtitle: '${state.stats.activeBuyers} Active',
                          icon: Icons.business,
                          color: AppColors.secondary,
                        ),
                        KpiCard(
                          title: 'Active Campaigns',
                          value: '${state.stats.activeCampaigns}',
                          subtitle: 'Running Now',
                          icon: Icons.campaign,
                          color: AppColors.success,
                        ),
                        KpiCard(
                          title: 'Completed',
                          value: '${state.stats.completedCampaigns}',
                          subtitle: 'All Time',
                          icon: Icons.check_circle,
                          color: AppColors.info,
                        ),
                        KpiCard(
                          title: 'Pending Reviews',
                          value: '${state.stats.pendingReviews}',
                          subtitle: 'Awaiting Action',
                          icon: Icons.rate_review,
                          color: AppColors.warning,
                        ),
                        KpiCard(
                          title: 'Pending KYC',
                          value: '${state.stats.pendingKyc}',
                          subtitle: 'Verification Queue',
                          icon: Icons.verified_user,
                          color: AppColors.error,
                        ),
                        KpiCard(
                          title: 'Gross Volume',
                          value: '₹${(state.stats.grossVolume / 100000).toStringAsFixed(1)}L',
                          subtitle: 'Total Processed',
                          icon: Icons.currency_rupee,
                          color: AppColors.primary,
                        ),
                        KpiCard(
                          title: 'Platform Margin',
                          value: '₹${(state.stats.platformMargin / 100000).toStringAsFixed(1)}L',
                          subtitle: 'Net Profit',
                          icon: Icons.trending_up,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionButton(
                            icon: Icons.verified_user,
                            label: 'Verify KYC',
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionButton(
                            icon: Icons.account_balance_wallet,
                            label: 'Approve Payouts',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionButton(
                            icon: Icons.rate_review,
                            label: 'Review Tasks',
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionButton(
                            icon: Icons.add_business,
                            label: 'Add Service',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

### Step 6: Dependency Injection Setup

**Update: `lib/core/di/injection.dart`**

```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> initializeDependencies() async {
  // Core
  getIt.registerLazySingleton(() => SecureStorageService());
  getIt.registerLazySingleton(() => DioClient(getIt()));
  
  // Dashboard
  getIt.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => GetDashboardStatsUseCase(getIt()));
  getIt.registerFactory(() => DashboardBloc(getDashboardStats: getIt()));
  
  // Add more feature dependencies here...
}
```

## 🚀 Usage Example

After implementing the above, the dashboard will automatically:
1. ✅ Fetch data from backend on load
2. ✅ Show loading state
3. ✅ Handle errors with retry
4. ✅ Support pull-to-refresh
5. ✅ Display real API data

## 📝 Next Steps

1. Replicate this pattern for:
   - Workers Module
   - Buyers Module
   - Orders Module
   - KYC Module
   - Payouts Module

2. Each module needs:
   - Entity
   - Model
   - DataSource
   - Repository
   - UseCase
   - BLoC
   - Updated UI

This structure ensures clean architecture, testability, and maintainability!
