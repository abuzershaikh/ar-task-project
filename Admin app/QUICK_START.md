# Quick Start Guide

## Prerequisites

- Flutter SDK 3.0+
- Dart 3.12.2+
- Android Studio / VS Code
- Git

## Installation

### 1. Clone & Setup

```bash
# Navigate to Admin app directory
cd "Admin app"

# Install dependencies
flutter pub get
```

### 2. Generate Code

The app uses code generation for JSON serialization. Run:

```bash
# Generate once
flutter pub run build_runner build --delete-conflicting-outputs

# Or watch for changes (recommended during development)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 3. Configure Backend URL

Edit `lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:3000';
  // or
  static const String baseUrl = 'https://your-api.com';
}
```

For Android emulator connecting to local backend:
```dart
static const String baseUrl = 'http://10.0.2.2:3000';
```

For physical device on same network:
```dart
static const String baseUrl = 'http://192.168.1.x:3000';
```

### 4. Run the App

```bash
# Check connected devices
flutter devices

# Run on connected device
flutter run

# Or run in release mode
flutter run --release
```

## Project Structure Overview

```
lib/
├── core/                    # Shared infrastructure
│   ├── constants/          # App constants
│   ├── di/                 # Dependency injection
│   ├── errors/             # Error handling
│   ├── network/            # HTTP client
│   ├── storage/            # Local & secure storage
│   ├── theme/              # App theme
│   └── utils/              # Utilities
│
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   ├── dashboard/         # Dashboard & home
│   ├── workers/           # Worker management
│   ├── buyers/            # Buyer management
│   ├── orders/            # Order management
│   └── more/              # More menu
│
└── main.dart              # App entry point
```

## Development Workflow

### Adding New Feature

1. **Create Feature Structure**
```
features/
└── feature_name/
    ├── data/
    │   ├── datasources/
    │   ├── models/
    │   └── repositories/
    ├── domain/
    │   ├── entities/
    │   ├── repositories/
    │   └── usecases/
    └── presentation/
        ├── bloc/
        ├── pages/
        └── widgets/
```

2. **Define Domain Layer**
```dart
// domain/entities/my_entity.dart
class MyEntity extends Equatable {
  final String id;
  final String name;
  
  const MyEntity({required this.id, required this.name});
  
  @override
  List<Object?> get props => [id, name];
}

// domain/repositories/my_repository.dart
abstract class MyRepository {
  Future<Either<Failure, List<MyEntity>>> getItems();
}

// domain/usecases/get_items_usecase.dart
class GetItemsUseCase {
  final MyRepository _repository;
  
  GetItemsUseCase(this._repository);
  
  Future<Either<Failure, List<MyEntity>>> call() async {
    return await _repository.getItems();
  }
}
```

3. **Implement Data Layer**
```dart
// data/models/my_model.dart
@JsonSerializable()
class MyModel extends MyEntity {
  const MyModel({required super.id, required super.name});
  
  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);
      
  Map<String, dynamic> toJson() => _$MyModelToJson(this);
  
  MyEntity toEntity() => MyEntity(id: id, name: name);
}

// data/datasources/my_remote_datasource.dart
class MyRemoteDataSourceImpl {
  final DioClient _client;
  
  Future<List<MyModel>> getItems() async {
    try {
      final response = await _client.get('/items');
      final items = (response.data['data'] as List)
          .map((json) => MyModel.fromJson(json))
          .toList();
      return items;
    } catch (e) {
      throw ServerException('Failed to fetch items');
    }
  }
}

// data/repositories/my_repository_impl.dart
class MyRepositoryImpl implements MyRepository {
  final MyRemoteDataSource _remoteDataSource;
  
  @override
  Future<Either<Failure, List<MyEntity>>> getItems() async {
    try {
      final models = await _remoteDataSource.getItems();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

4. **Create BLoC**
```dart
// presentation/bloc/my_bloc.dart
class MyBloc extends Bloc<MyEvent, MyState> {
  final GetItemsUseCase _getItemsUseCase;
  
  MyBloc({required GetItemsUseCase getItemsUseCase})
      : _getItemsUseCase = getItemsUseCase,
        super(MyInitial()) {
    on<MyLoadRequested>(_onLoadRequested);
  }
  
  Future<void> _onLoadRequested(
    MyLoadRequested event,
    Emitter<MyState> emit,
  ) async {
    emit(MyLoading());
    
    final result = await _getItemsUseCase();
    
    result.fold(
      (failure) => emit(MyError(failure.message)),
      (items) => emit(MyLoaded(items)),
    );
  }
}
```

5. **Register Dependencies**
```dart
// core/di/injection.dart
// Add to initializeDependencies():

// Data sources
getIt.registerLazySingleton<MyRemoteDataSource>(
  () => MyRemoteDataSourceImpl(getIt()),
);

// Repositories
getIt.registerLazySingleton<MyRepository>(
  () => MyRepositoryImpl(remoteDataSource: getIt()),
);

// Use cases
getIt.registerLazySingleton(() => GetItemsUseCase(getIt()));

// BLoC
getIt.registerFactory(() => MyBloc(getItemsUseCase: getIt()));
```

6. **Generate Code**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

7. **Create UI**
```dart
// presentation/pages/my_screen.dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MyBloc>()..add(MyLoadRequested()),
      child: Scaffold(
        appBar: AppBar(title: Text('My Feature')),
        body: BlocBuilder<MyBloc, MyState>(
          builder: (context, state) {
            if (state is MyLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is MyError) {
              return Center(child: Text(state.message));
            } else if (state is MyLoaded) {
              return ListView.builder(
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return ListTile(title: Text(item.name));
                },
              );
            }
            return SizedBox();
          },
        ),
      ),
    );
  }
}
```

## Common Commands

```bash
# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes
flutter pub run build_runner watch --delete-conflicting-outputs

# Clean generated files
flutter pub run build_runner clean

# Run app
flutter run

# Run with flavor
flutter run --flavor dev

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Analyze code
flutter analyze

# Format code
dart format lib/

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## Testing the App

### Mock Login
Since backend might not be ready, you can:

1. **Option A: Mock Data**
   - Modify `AuthRemoteDataSourceImpl` to return mock data
   - Comment out actual API calls temporarily

2. **Option B: Use Test Backend**
   - Start your Task Engine backend
   - Update `baseUrl` in constants
   - Create test admin user in database

3. **Option C: JSON Server (Quick Mock)**
```bash
# Install json-server globally
npm install -g json-server

# Create db.json
{
  "admin": {
    "login": {
      "success": true,
      "data": {
        "access_token": "mock-token",
        "refresh_token": "mock-refresh",
        "user": {
          "id": "1",
          "email": "admin@test.com",
          "name": "Test Admin",
          "role": "SUPER_ADMIN",
          "is_active": true,
          "created_at": "2024-01-01T00:00:00Z"
        }
      }
    }
  }
}

# Run server
json-server --watch db.json --port 3000
```

## Troubleshooting

### Issue: Build fails with "part of" errors
**Solution**: Run code generation
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: DI error "GetIt: Object/factory with ... is not registered"
**Solution**: Check if dependency is registered in `injection.dart`

### Issue: Can't connect to localhost backend from emulator
**Solution**: Use `10.0.2.2` instead of `localhost` for Android emulator

### Issue: SSL handshake failed
**Solution**: 
- Use HTTP for development
- Or configure SSL certificates properly
- Or add `badCertificateCallback` for development only

### Issue: Token not persisting
**Solution**: Check FlutterSecureStorage permissions in AndroidManifest

## Next Steps

1. ✅ Setup complete? Move to backend integration
2. ✅ Backend connected? Implement detail screens
3. ✅ Basic features working? Add advanced features
4. ✅ Features complete? Polish UI/UX
5. ✅ Polish done? Add testing
6. ✅ Testing done? Deploy to production

## Getting Help

- Check `ARCHITECTURE.md` for architecture details
- Check `IMPLEMENTATION_CHECKLIST.md` for feature status
- Check `README.md` for overview
- Review code comments in existing features
- Look at similar implemented features as examples

## Development Tips

1. **Always run code generation after modifying models**
2. **Check BLoC events and states are properly defined**
3. **Use logger for debugging** (`AppLogger.debug()`)
4. **Test error handling** by simulating network failures
5. **Keep use cases simple** - single responsibility
6. **Don't put business logic in BLoC** - use use cases
7. **Use const constructors** for better performance
8. **Follow existing patterns** in other features

Happy coding! 🚀
