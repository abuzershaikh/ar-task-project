# Admin App Architecture

## Overview

Enterprise-grade Flutter application following **Clean Architecture** principles with **BLoC** state management pattern. The architecture ensures:

- **Separation of Concerns**: Each layer has a single responsibility
- **Testability**: Business logic decoupled from UI and infrastructure
- **Maintainability**: Easy to modify and extend
- **Scalability**: Can grow without architectural changes
- **Error Handling**: Comprehensive error handling at every layer

## Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                     │
│  (UI, Widgets, BLoC, Pages)                             │
│  ├── Pages: Screen implementations                      │
│  ├── Widgets: Reusable UI components                    │
│  └── BLoC: State management (Events → States)           │
└─────────────────────────────────────────────────────────┘
                          ↓ ↑
┌─────────────────────────────────────────────────────────┐
│                    DOMAIN LAYER                          │
│  (Business Logic, Entities, Use Cases)                   │
│  ├── Entities: Core business objects                    │
│  ├── Repositories: Interfaces (contracts)               │
│  └── Use Cases: Application business rules              │
└─────────────────────────────────────────────────────────┘
                          ↓ ↑
┌─────────────────────────────────────────────────────────┐
│                     DATA LAYER                           │
│  (Implementation, Models, Data Sources)                  │
│  ├── Models: JSON serializable data classes             │
│  ├── Data Sources: Remote API & Local storage           │
│  └── Repositories: Implementation of interfaces         │
└─────────────────────────────────────────────────────────┘
                          ↓ ↑
┌─────────────────────────────────────────────────────────┐
│                    CORE LAYER                            │
│  (Network, Storage, Utils, Constants)                    │
│  ├── Network: HTTP client, interceptors                 │
│  ├── Storage: Secure & local storage services           │
│  ├── Errors: Exception & failure handling               │
│  └── Utils: Shared utilities, logger                    │
└─────────────────────────────────────────────────────────┘
```

## Layer Responsibilities

### 1. Presentation Layer (UI)

**Purpose**: User interface and user interaction

**Components**:
- **Pages**: Full-screen widgets (screens)
- **Widgets**: Reusable UI components
- **BLoC**: Business Logic Component (state management)

**Rules**:
- Only depends on Domain layer
- Contains no business logic
- Manages UI state via BLoC
- Displays data from entities

**Example**:
```dart
// presentation/pages/login_screen.dart
class LoginScreen extends StatelessWidget {
  // UI only - no business logic
  
  void _onLoginPressed(BuildContext context) {
    // Dispatch event to BLoC
    context.read<AuthBloc>().add(
      AuthLoginRequested(email: email, password: password),
    );
  }
}
```

### 2. Domain Layer (Business Logic)

**Purpose**: Core business rules and entities

**Components**:
- **Entities**: Pure business objects (no JSON, no DB logic)
- **Repositories**: Abstract interfaces (contracts)
- **Use Cases**: Single-purpose business operations

**Rules**:
- No dependencies on other layers
- Platform-independent
- Contains pure business logic
- Uses repository interfaces, not implementations

**Example**:
```dart
// domain/entities/admin_user.dart
class AdminUser extends Equatable {
  final String id;
  final String email;
  final AdminRole role;
  // Pure business object - no external dependencies
}

// domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<Either<Failure, AdminUser>> login(String email, String password);
  // Interface only - no implementation
}

// domain/usecases/login_usecase.dart
class LoginUseCase {
  final AuthRepository _repository;
  
  Future<Either<Failure, AdminUser>> call({
    required String email,
    required String password,
  }) async {
    // Business validation
    if (!_isValidEmail(email)) {
      return Left(ValidationFailure('Invalid email'));
    }
    
    // Delegate to repository
    return await _repository.login(email, password);
  }
}
```

### 3. Data Layer (Implementation)

**Purpose**: Data access and manipulation

**Components**:
- **Models**: JSON serializable versions of entities
- **Data Sources**: API clients, local storage
- **Repositories**: Concrete implementations

**Rules**:
- Implements domain layer interfaces
- Handles data conversion (JSON ↔ Entity)
- Manages API calls and caching
- Converts exceptions to failures

**Example**:
```dart
// data/models/admin_user_model.dart
@JsonSerializable()
class AdminUserModel extends AdminUser {
  // Extends entity, adds JSON serialization
  
  factory AdminUserModel.fromJson(Map<String, dynamic> json) =>
      _$AdminUserModelFromJson(json);
  
  AdminUser toEntity() => AdminUser(...);
}

// data/datasources/auth_remote_datasource.dart
class AuthRemoteDataSourceImpl {
  Future<LoginResponse> login(String email, String password) async {
    final response = await _dioClient.post('/login', data: {...});
    // Handles HTTP communication
    return LoginResponse.fromJson(response.data);
  }
}

// data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<Either<Failure, AdminUser>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _remoteDataSource.login(email, password);
      await _secureStorage.write('token', response.accessToken);
      return Right(response.user.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }
}
```

### 4. Core Layer (Infrastructure)

**Purpose**: Shared utilities and services

**Components**:
- **Network**: HTTP client, interceptors, API endpoints
- **Storage**: Secure and local storage services
- **Errors**: Exception and failure classes
- **Utils**: Logger, validators, formatters
- **Constants**: App-wide constants and enums
- **Theme**: Colors, text styles, app theme

**Example**:
```dart
// core/network/dio_client.dart
class DioClient {
  final Dio _dio;
  
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e); // Convert to app exceptions
    }
  }
}

// core/storage/secure_storage_service.dart
class SecureStorageService {
  Future<bool> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return true;
    } catch (e) {
      AppLogger.error('Failed to write', e);
      return false;
    }
  }
}
```

## State Management (BLoC Pattern)

### Flow:

```
User Action → Event → BLoC → Use Case → Repository → Data Source
                                                         ↓
User sees UI ← State ← BLoC ← Either<Failure, Success> ←┘
```

### Components:

**Event**: User actions
```dart
abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
}
```

**State**: UI states
```dart
abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final AdminUser user;
}
class AuthError extends AuthState {
  final String message;
}
```

**BLoC**: Event handler
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await _loginUseCase(
      email: event.email,
      password: event.password,
    );
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }
}
```

## Error Handling Architecture

### Exception → Failure Flow:

```
Data Source throws Exception
        ↓
Repository catches Exception
        ↓
Repository returns Either<Failure, Success>
        ↓
Use Case returns Either<Failure, Success>
        ↓
BLoC emits Error State with Failure message
        ↓
UI shows error to user
```

### Exception Types:
- **ServerException**: API errors (4xx, 5xx)
- **NetworkException**: Connection errors
- **AuthException**: Authentication failures
- **CacheException**: Local storage errors

### Failure Types:
- **ServerFailure**: Server-side errors
- **NetworkFailure**: Network connectivity issues
- **AuthFailure**: Auth/authorization failures
- **ValidationFailure**: Input validation errors
- **CacheFailure**: Storage errors
- **UnknownFailure**: Unexpected errors

### Error Handling Example:
```dart
try {
  final response = await _dioClient.post('/login');
  return Right(response.data);
} on AuthException catch (e) {
  AppLogger.error('Auth error', e);
  return Left(AuthFailure(e.message));
} on NetworkException catch (e) {
  AppLogger.error('Network error', e);
  return Left(NetworkFailure(e.message));
} on ServerException catch (e) {
  AppLogger.error('Server error', e);
  return Left(ServerFailure(e.message));
} catch (e, stackTrace) {
  AppLogger.error('Unexpected error', e, stackTrace);
  return Left(UnknownFailure(e.toString()));
}
```

## Dependency Injection (GetIt)

### Registration Pattern:

```dart
// External dependencies
getIt.registerLazySingleton(() => SharedPreferences.getInstance());
getIt.registerLazySingleton(() => FlutterSecureStorage());

// Core services
getIt.registerLazySingleton(() => DioClient(getIt()));
getIt.registerLazySingleton(() => SecureStorageService(getIt()));
getIt.registerLazySingleton(() => LocalStorageService(getIt()));

// Feature: Auth
// Data sources
getIt.registerLazySingleton<AuthRemoteDataSource>(
  () => AuthRemoteDataSourceImpl(getIt()),
);

// Repositories
getIt.registerLazySingleton<AuthRepository>(
  () => AuthRepositoryImpl(
    remoteDataSource: getIt(),
    secureStorage: getIt(),
    localStorage: getIt(),
  ),
);

// Use cases
getIt.registerLazySingleton(() => LoginUseCase(getIt()));

// BLoC (Factory - new instance each time)
getIt.registerFactory(() => AuthBloc(
  loginUseCase: getIt(),
  logoutUseCase: getIt(),
));
```

### Usage:
```dart
// In widget
BlocProvider(
  create: (context) => getIt<AuthBloc>(),
  child: MyWidget(),
)

// Direct access (rare)
final authRepo = getIt<AuthRepository>();
```

## Data Flow Example: Login

```
1. User enters credentials and taps login
   ↓
2. LoginScreen dispatches AuthLoginRequested event
   ↓
3. AuthBloc receives event
   ↓
4. AuthBloc emits AuthLoading state
   ↓
5. AuthBloc calls LoginUseCase
   ↓
6. LoginUseCase validates input
   ↓
7. LoginUseCase calls AuthRepository.login()
   ↓
8. AuthRepositoryImpl calls AuthRemoteDataSource
   ↓
9. DataSource makes HTTP request via DioClient
   ↓
10. Server returns JWT token and user data
   ↓
11. DataSource returns LoginResponse model
   ↓
12. Repository saves token to SecureStorage
   ↓
13. Repository converts model to entity
   ↓
14. Repository returns Right(AdminUser)
   ↓
15. Use Case returns Right(AdminUser)
   ↓
16. BLoC emits AuthAuthenticated state
   ↓
17. UI rebuilds and navigates to dashboard
```

## Testing Strategy

### Unit Tests:
- **Use Cases**: Test business logic
- **Repositories**: Test data handling
- **BLoC**: Test state transitions

### Widget Tests:
- Test UI components
- Test user interactions
- Mock BLoC states

### Integration Tests:
- Test complete flows
- Test API integration

## Best Practices

### DO:
✅ Keep entities pure (no external dependencies)
✅ Use repository interfaces in domain layer
✅ Handle all errors with Either<Failure, Success>
✅ Log errors with stack traces
✅ Use const constructors where possible
✅ Use Equatable for value comparison
✅ Follow single responsibility principle
✅ Write descriptive BLoC event names

### DON'T:
❌ Access UI from domain/data layers
❌ Put business logic in BLoC
❌ Throw exceptions from use cases
❌ Skip error handling
❌ Use dynamic types without reason
❌ Ignore null safety
❌ Create God classes
❌ Mix presentation and business logic

## Code Organization

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── enums.dart
│   ├── di/
│   │   └── injection.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   ├── dio_client.dart
│   │   ├── api_endpoints.dart
│   │   ├── api_response.dart
│   │   └── network_info.dart
│   ├── storage/
│   │   ├── secure_storage_service.dart
│   │   └── local_storage_service.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   └── utils/
│       ├── logger.dart
│       └── validators.dart
│
├── features/
│   └── auth/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── auth_remote_datasource.dart
│       │   ├── models/
│       │   │   ├── login_request.dart
│       │   │   ├── login_response.dart
│       │   │   └── admin_user_model.dart
│       │   └── repositories/
│       │       └── auth_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── admin_user.dart
│       │   ├── repositories/
│       │   │   └── auth_repository.dart
│       │   └── usecases/
│       │       ├── login_usecase.dart
│       │       ├── logout_usecase.dart
│       │       └── get_current_user_usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── auth_bloc.dart
│           │   ├── auth_event.dart
│           │   └── auth_state.dart
│           ├── pages/
│           │   └── login_screen.dart
│           └── widgets/
│               └── login_form.dart
│
└── main.dart
```

## Security Considerations

1. **Token Storage**: JWT tokens stored in FlutterSecureStorage
2. **Auto Logout**: Clear tokens on 401 responses
3. **Token Refresh**: Automatic token refresh mechanism
4. **Secure Communication**: HTTPS only
5. **Input Validation**: Validate at use case level
6. **Error Messages**: Don't expose sensitive info

## Performance Optimizations

1. **Lazy Loading**: Dependencies registered as lazy singletons
2. **Const Constructors**: Reduce widget rebuilds
3. **BLoC Factory**: New instance for each usage
4. **Response Caching**: Cache frequently used data
5. **Image Caching**: Use cached_network_image
6. **List Optimization**: Use ListView.builder for large lists

## Scalability

Adding new features:
1. Create feature folder under `features/`
2. Implement data layer (models, data sources, repositories)
3. Define domain layer (entities, interfaces, use cases)
4. Build presentation layer (BLoC, pages, widgets)
5. Register dependencies in `injection.dart`
6. Add routes if needed

The architecture supports unlimited features without structural changes.
