# Buyer App Architecture

## Overview

Marketing Pro Buyer App follows **Clean Architecture** principles with clear separation of concerns and feature-based organization.

## Architecture Layers

```
┌─────────────────────────────────────┐
│     Presentation Layer (UI)         │
│  - Pages, Widgets, BLoC/State       │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Domain Layer (Business)        │
│  - Entities, Use Cases, Repos       │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│       Data Layer (External)         │
│  - Models, DataSources, Repo Impl   │
└─────────────────────────────────────┘
```

## Layer Responsibilities

### 1. Presentation Layer
- **Pages**: Screen implementations
- **Widgets**: Reusable UI components
- **BLoC**: State management and business logic coordination
- **Dependency**: Only on Domain layer

### 2. Domain Layer
- **Entities**: Core business objects (campaign, order, submission)
- **Use Cases**: Single-responsibility business operations
- **Repository Interfaces**: Abstract data contracts
- **Dependency**: None (pure Dart)

### 3. Data Layer
- **Models**: JSON serializable data classes
- **DataSources**: API communication (remote) or storage (local)
- **Repository Implementations**: Concrete data operations
- **Dependency**: Domain layer interfaces

## Feature Structure

Each feature follows this structure:

```
feature/
├── data/
│   ├── datasources/
│   │   └── feature_remote_datasource.dart
│   ├── models/
│   │   └── feature_model.dart
│   └── repositories/
│       └── feature_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── feature_entity.dart
│   ├── repositories/
│   │   └── feature_repository.dart
│   └── usecases/
│       └── get_feature_usecase.dart
└── presentation/
    ├── bloc/
    │   └── feature_bloc.dart
    ├── pages/
    │   └── feature_page.dart
    └── widgets/
        └── feature_widget.dart
```

## Core Modules

### Network Layer
- **DioClient**: HTTP client wrapper
- **AuthInterceptor**: Auto token refresh on 401
- **Error Handling**: Converts exceptions to failures

### Storage Layer
- **SecureStorage**: Token and sensitive data (encrypted)
- **LocalStorage**: User preferences (SharedPreferences)

### Dependency Injection
- **GetIt**: Service locator pattern
- **Lazy Loading**: Services created on-demand
- **Singleton**: Network, storage, repositories

## State Management (BLoC Pattern)

```dart
Event → BLoC → State → UI

// Example Flow:
LoginEvent 
  → AuthBloc processes
  → AuthLoading (show loader)
  → API call via UseCase
  → AuthSuccess/AuthError
  → UI updates
```

### BLoC Benefits
- **Predictable**: Events in, states out
- **Testable**: Pure business logic
- **Reactive**: Stream-based updates
- **Separation**: UI decoupled from logic

## Data Flow

### Request Flow (e.g., Create Campaign)
```
UI (CreateCampaignPage)
  ↓ triggers event
BLoC (CampaignBloc)
  ↓ calls
UseCase (CreateCampaignUseCase)
  ↓ calls
Repository (CampaignRepository)
  ↓ calls
DataSource (CampaignRemoteDataSource)
  ↓ makes
API Call (POST /buyer/orders)
  ↓ returns
Response → Model → Entity → State → UI
```

### Response Flow
```
API Response (JSON)
  ↓ parsed to
Model (data layer)
  ↓ converted to
Entity (domain layer)
  ↓ wrapped in
Either<Failure, Entity>
  ↓ emitted as
State (presentation)
  ↓ updates
UI (page rebuilds)
```

## Error Handling

### Exception → Failure Pattern
```dart
// Data Layer throws Exception
throw ServerException('Server error');

// Repository catches and converts
} on ServerException catch (e) {
  return Left(ServerFailure(e.message));
}

// BLoC receives Either<Failure, Data>
result.fold(
  (failure) => emit(ErrorState(failure.message)),
  (data) => emit(SuccessState(data)),
);
```

### Error Types
- **NetworkException**: Connection issues
- **ServerException**: 5xx errors
- **UnauthorizedException**: 401 (auto-refresh token)
- **ValidationException**: 422 with field errors
- **NotFoundException**: 404

## Security

### Token Management
1. Access token stored in SecureStorage (encrypted)
2. Refresh token stored in SecureStorage
3. AuthInterceptor adds Bearer token to all requests
4. On 401: Auto refresh token, retry request
5. On refresh failure: Logout user

### Data Security
- No sensitive calculations on client (prices, rewards)
- Server is source of truth for all business data
- Client only displays data from backend
- All financial operations require server validation

## Navigation

### Router Pattern
- Named routes in `AppRouter`
- Type-safe route arguments
- Centralized navigation logic

```dart
// Navigation
Navigator.pushNamed(context, AppRouter.campaignDetail, arguments: campaignId);

// Route generation
case campaignDetail:
  final id = settings.arguments as String;
  return MaterialPageRoute(builder: (_) => CampaignDetailPage(id: id));
```

## Testing Strategy

### Unit Tests
- Use Cases (business logic)
- BLoC (event → state)
- Models (JSON serialization)
- Utilities (formatters, validators)

### Widget Tests
- Individual widgets
- Page layouts
- User interactions

### Integration Tests
- Full user flows
- API integration
- State persistence

## Performance

### Optimizations
- Const constructors for immutable widgets
- ListView.builder for long lists
- Cached network images
- Pagination for large datasets
- Shimmer loading states

### Memory Management
- Dispose controllers and blocs
- Cancel streams
- Clear caches

## Backend Integration

### API Contract
Buyer app consumes these backend endpoints:

**Authentication**
- POST /auth/login
- POST /auth/logout
- POST /auth/refresh

**Orders (Campaigns)**
- GET /buyer/orders (list campaigns)
- POST /buyer/orders (create campaign)
- GET /buyer/orders/:id (detail)
- PATCH /buyer/orders/:id/pause
- PATCH /buyer/orders/:id/resume
- DELETE /buyer/orders/:id/cancel

**Submissions (Reviews)**
- GET /buyer/submissions (pending reviews)
- POST /buyer/submissions/:id/approve
- POST /buyer/submissions/:id/reject
- POST /buyer/submissions/:id/request-changes

**Analytics**
- GET /buyer/analytics/overview
- GET /buyer/analytics/campaign/:id

**Payments**
- POST /buyer/payments/initiate
- POST /buyer/payments/verify
- GET /buyer/payments (history)

### Data Models Match Backend

All models align with backend entities:
- Order → Campaign
- Submission → Worker Task Submission
- Service → Task Type
- Payment → Transaction

## Key Design Decisions

### Why Clean Architecture?
- **Testability**: Each layer independently testable
- **Maintainability**: Clear boundaries and responsibilities
- **Scalability**: Easy to add features without breaking existing code
- **Flexibility**: Swap implementations (e.g., API → Mock for testing)

### Why BLoC?
- **Reactive**: Natural fit for Flutter's reactive framework
- **Separation**: Business logic separate from UI
- **Predictable**: Events and states are traceable
- **Testable**: Pure functions, easy to test

### Why GetIt?
- **Simple**: Easy service locator pattern
- **Lazy**: Services created only when needed
- **Scoped**: Different lifetimes (singleton, factory)

### Why Either<Failure, Data>?
- **Explicit**: Forces error handling
- **Type-safe**: Compiler ensures all paths handled
- **Functional**: Railway-oriented programming

## Best Practices

1. **Never trust client calculations** - Server validates all business logic
2. **Use const constructors** - Performance optimization
3. **Dispose resources** - Prevent memory leaks
4. **Handle all states** - Loading, success, error, empty
5. **Validate input** - Before sending to server
6. **Log errors** - For debugging and monitoring
7. **Use meaningful names** - Code should be self-documenting
8. **Keep widgets small** - Single responsibility
9. **Reuse components** - DRY principle
10. **Test critical paths** - Authentication, payments, submissions

## Future Enhancements

- Offline support with local database (Hive/SQLite)
- Push notifications (FCM)
- Deep linking
- In-app updates
- Crash reporting (Sentry/Crashlytics)
- Analytics tracking (Firebase/Mixpanel)
- A/B testing
- Multi-language support
