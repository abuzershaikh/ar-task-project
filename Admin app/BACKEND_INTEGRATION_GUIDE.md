# Backend Integration Guide

## Overview

Ye guide Admin Flutter App ko Task Engine backend se connect karne ke liye hai. API Contract v1.0 already freeze ho chuka hai aur `api_endpoints.dart` update ho gaya hai.

## Prerequisites

- ✅ Task Engine backend running on `localhost:3000`
- ✅ Admin API controllers implemented in backend
- ✅ Database setup with admin users
- ✅ Flutter dependencies installed

## Integration Steps

### Phase 1: Test Authentication Flow (Priority 1)

#### Step 1: Create Test Admin User in Database

Backend mein SQL run karo:

```sql
-- Create test admin user
INSERT INTO users (id, email, password, name, role, is_active, created_at)
VALUES (
  uuid(),
  'admin@earnpost.com',
  '$2b$10$...',  -- bcrypt hash of 'admin123'
  'Super Admin',
  'SUPER_ADMIN',
  true,
  NOW()
);
```

Ya NestJS seeder use karo.

#### Step 2: Test Login API Manually

```bash
curl -X POST http://localhost:3000/api/v1/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@earnpost.com",
    "password": "admin123"
  }'
```

Expected Response:
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": "uuid",
      "email": "admin@earnpost.com",
      "name": "Super Admin",
      "role": "SUPER_ADMIN",
      "is_active": true,
      "created_at": "2024-01-01T00:00:00Z",
      "last_login_at": null
    }
  }
}
```

#### Step 3: Update Flutter baseUrl

`Admin app/lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  // For Android Emulator
  static const String baseUrl = 'http://10.0.2.2:3000';
  
  // For Physical Device (replace with your IP)
  // static const String baseUrl = 'http://192.168.1.100:3000';
  
  // For Web/Desktop
  // static const String baseUrl = 'http://localhost:3000';
  
  static const String apiPrefix = '/api/v1';
  // ... rest
}
```

#### Step 4: Test Login in Flutter

```bash
cd "Admin app"
flutter run
```

Login with:
- Email: `admin@earnpost.com`
- Password: `admin123`

**Expected Behavior:**
1. Loading state shows
2. API call made
3. Token saved in SecureStorage
4. Navigate to Dashboard
5. Check logs: `AppLogger.info('Login successful')`

**Debug Commands:**
```dart
// Add to login screen for testing
debugPrint('Token: ${await _secureStorage.read(AppConstants.tokenKey)}');
```

---

### Phase 2: Dashboard Integration (Priority 2)

#### Backend: Implement Dashboard Controller

`Task engine/apps/api/controllers/admin/dashboard.controller.ts`:

```typescript
@Controller('api/v1/admin/dashboard')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
export class DashboardController {
  
  @Get('stats')
  async getStats() {
    // Calculate from database
    const stats = {
      total_buyers: await this.userRepo.count({ role: 'BUYER' }),
      active_buyers: await this.userRepo.count({ 
        role: 'BUYER', 
        is_active: true 
      }),
      // ... calculate all stats
    };
    
    return {
      success: true,
      data: stats,
    };
  }
  
  @Get('alerts')
  async getAlerts() {
    // Return alerts
  }
  
  @Get('activity')
  async getActivity(@Query('page') page: number) {
    // Return recent activity with pagination
  }
}
```

#### Flutter: Create Dashboard Feature

**1. Create Domain Entities**

Already created: `dashboard_stats.dart`

**2. Create Data Models**

Already created: `dashboard_stats_model.dart` with `.g.dart`

**3. Create Remote Data Source**

`Admin app/lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart`:

```dart
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/dashboard_stats_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStatsModel> getStats();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient _dioClient;

  DashboardRemoteDataSourceImpl(this._dioClient);

  @override
  Future<DashboardStatsModel> getStats() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.dashboardStats);

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => DashboardStatsModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ServerException(apiResponse.message ?? 'Failed to fetch stats');
      }
    } catch (e) {
      if (e is ServerException || 
          e is NetworkException || 
          e is AuthException) {
        rethrow;
      }
      throw ServerException('Failed to fetch dashboard stats: ${e.toString()}');
    }
  }
}
```

**4. Create Repository**

`Admin app/lib/features/dashboard/domain/repositories/dashboard_repository.dart`:

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardStats>> getStats();
}
```

`Admin app/lib/features/dashboard/data/repositories/dashboard_repository_impl.dart`:

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  DashboardRepositoryImpl({
    required DashboardRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, DashboardStats>> getStats() async {
    try {
      final model = await _remoteDataSource.getStats();
      return Right(model.toEntity());
    } on AuthException catch (e) {
      AppLogger.error('Auth error fetching dashboard stats', e);
      return Left(AuthFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      AppLogger.error('Network error fetching dashboard stats', e);
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      AppLogger.error('Server error fetching dashboard stats', e);
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error fetching dashboard stats', e, stackTrace);
      return Left(UnknownFailure(e.toString()));
    }
  }
}
```

**5. Create Use Case**

`Admin app/lib/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart`:

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardStatsUseCase {
  final DashboardRepository _repository;

  GetDashboardStatsUseCase(this._repository);

  Future<Either<Failure, DashboardStats>> call() async {
    return await _repository.getStats();
  }
}
```

**6. Create BLoC**

`Admin app/lib/features/dashboard/presentation/bloc/dashboard_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/usecases/get_dashboard_stats_usecase.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardStatsUseCase _getStatsUseCase;

  DashboardBloc({
    required GetDashboardStatsUseCase getStatsUseCase,
  })  : _getStatsUseCase = getStatsUseCase,
        super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoadRequested);
    on<DashboardRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    AppLogger.info('Loading dashboard stats');

    final result = await _getStatsUseCase();

    result.fold(
      (failure) {
        AppLogger.error('Failed to load dashboard stats: ${failure.message}');
        emit(DashboardError(failure.message));
      },
      (stats) {
        AppLogger.info('Dashboard stats loaded successfully');
        emit(DashboardLoaded(stats));
      },
    );
  }

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    // Don't emit loading for refresh
    final result = await _getStatsUseCase();

    result.fold(
      (failure) {
        // Keep showing old data on refresh error
        if (state is DashboardLoaded) {
          final currentState = state as DashboardLoaded;
          emit(DashboardLoaded(currentState.stats));
        } else {
          emit(DashboardError(failure.message));
        }
      },
      (stats) {
        emit(DashboardLoaded(stats));
      },
    );
  }
}
```

**Events:**
```dart
// dashboard_event.dart
part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardLoadRequested extends DashboardEvent {
  const DashboardLoadRequested();
}

class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}
```

**States:**
```dart
// dashboard_state.dart
part of 'dashboard_bloc.dart';

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
```

**7. Register Dependencies**

`Admin app/lib/core/di/injection.dart` mein add karo:

```dart
// Dashboard Feature
// Data sources
getIt.registerLazySingleton<DashboardRemoteDataSource>(
  () => DashboardRemoteDataSourceImpl(getIt()),
);

// Repositories
getIt.registerLazySingleton<DashboardRepository>(
  () => DashboardRepositoryImpl(remoteDataSource: getIt()),
);

// Use cases
getIt.registerLazySingleton(() => GetDashboardStatsUseCase(getIt()));

// BLoC
getIt.registerFactory(
  () => DashboardBloc(getStatsUseCase: getIt()),
);
```

**8. Update Dashboard UI**

`Admin app/lib/features/dashboard/presentation/widgets/dashboard_content.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../bloc/dashboard_bloc.dart';
// ... other imports

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DashboardBloc>()
        ..add(const DashboardLoadRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [/* ... */],
        ),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is DashboardError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<DashboardBloc>()
                          .add(const DashboardLoadRequested());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is DashboardLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DashboardBloc>()
                    .add(const DashboardRefreshRequested());
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: _buildDashboardContent(state.stats),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildDashboardContent(DashboardStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Use real data from stats
          Text('Total Buyers: ${stats.totalBuyers}'),
          Text('Active Workers: ${stats.activeWorkers}'),
          // ... display all stats
        ],
      ),
    );
  }
}
```

#### Test Dashboard Integration

1. Backend running: ✓
2. Admin logged in: ✓
3. Navigate to Dashboard tab
4. Loading spinner shows
5. Stats load from API
6. Pull down to refresh
7. Check logs for API call

---

### Phase 3: Workers Integration (Priority 3)

Similar pattern as Dashboard. Steps:

1. Backend: Implement `/admin/workers` endpoint
2. Flutter: Create Worker domain/data/presentation layers
3. Create WorkersBloc
4. Update WorkersScreen to use BLoC
5. Add pagination
6. Add filters
7. Test

---

## Testing Checklist

### Authentication
- [ ] Login with valid credentials
- [ ] Login with invalid credentials (error message)
- [ ] Token saved in SecureStorage
- [ ] Token auto-injected in API calls
- [ ] Logout clears token
- [ ] Auto logout on 401

### Dashboard
- [ ] Stats load on first visit
- [ ] Loading spinner shows
- [ ] Error message on network failure
- [ ] Retry button works
- [ ] Pull-to-refresh works
- [ ] Stats display correctly

### Error Handling
- [ ] Network timeout shows proper message
- [ ] Server 500 error shows proper message
- [ ] 401 redirects to login
- [ ] 403 shows permission error

---

## Common Issues & Solutions

### Issue: Can't connect to localhost

**Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:3000';
```

**Physical Device:**
```dart
// Find your PC's IP: ipconfig (Windows) or ifconfig (Mac/Linux)
static const String baseUrl = 'http://192.168.1.100:3000';
```

### Issue: CORS Error (Web)

Backend mein CORS enable karo:
```typescript
app.enableCors({
  origin: 'http://localhost:8080', // Flutter web port
  credentials: true,
});
```

### Issue: Token not persisting

Check FlutterSecureStorage permissions in AndroidManifest:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### Issue: JSON parsing error

Check model `.g.dart` files generated properly:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Next Steps Priority

1. ✅ **Auth Integration** - MUST DO FIRST
2. ✅ **Dashboard Integration** - HIGH PRIORITY
3. **Workers List Integration** - HIGH PRIORITY
4. **Buyers List Integration** - HIGH PRIORITY
5. **Orders List Integration** - HIGH PRIORITY
6. **Worker Detail Screen** - MEDIUM PRIORITY
7. **Service Management** - MEDIUM PRIORITY
8. **Matching Config** - MEDIUM PRIORITY
9. **Reviews** - LOW PRIORITY
10. **KYC** - LOW PRIORITY

---

## Code Generation Commands

```bash
# After adding/modifying models
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-generate on save)
flutter pub run build_runner watch --delete-conflicting-outputs
```

---

## API Testing Tools

**Postman Collection:**
Import `API_CONTRACT_ADMIN_V1.md` into Postman for testing.

**cURL Examples:**
See contract document for all endpoints.

---

Happy Integration! 🚀
