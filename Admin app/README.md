# EarnPost Admin App

Enterprise-grade Flutter admin application for managing the EarnPost task platform.

## Features

- **Dashboard**: Platform overview with KPIs and alerts
- **Worker Management**: View, manage, and monitor worker profiles
- **Buyer Management**: Manage buyer accounts and balances
- **Order/Campaign Management**: Monitor and control campaigns
- **Service Pricing**: Configure services and margins
- **Matching Engine Config**: Control worker matching algorithm
- **Review Management**: Approve/reject task submissions
- **KYC Management**: Verify worker documents
- **Payout Management**: Process worker withdrawals
- **Analytics**: Platform metrics and insights
- **Risk/Fraud Monitoring**: Track suspicious activities
- **API/Webhook Management**: Manage external integrations
- **Audit Logs**: System activity tracking

## Architecture

### Clean Architecture Layers
```
presentation/ (UI, BLoC)
    ├── pages/
    ├── widgets/
    └── bloc/

domain/ (Business Logic)
    ├── entities/
    ├── repositories/ (interfaces)
    └── usecases/

data/ (Implementation)
    ├── models/
    ├── datasources/
    └── repositories/ (implementations)
```

### State Management
- **flutter_bloc** for predictable state management
- **BLoC pattern** with Events and States
- **Repository pattern** for data abstraction
- **Use Case pattern** for business logic isolation

### Error Handling
- Comprehensive error types (Network, Auth, Server, Cache)
- Failure objects with Either<Failure, Success> pattern
- Global error logging with stack traces
- User-friendly error messages

## Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.12.2+
- Android Studio / VS Code

### Installation

```bash
# Install dependencies
flutter pub get

# Generate code (for json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Generate Models
```bash
# Watch for changes and auto-generate
flutter pub run build_runner watch --delete-conflicting-outputs

# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs
```

## Project Structure

```
lib/
├── core/
│   ├── constants/          # App constants and enums
│   ├── di/                 # Dependency injection
│   ├── errors/             # Error handling
│   ├── network/            # Dio client, API endpoints
│   ├── routes/             # Navigation routes
│   ├── storage/            # Local and secure storage
│   ├── theme/              # App theme and colors
│   └── utils/              # Utilities and helpers
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── dashboard/
│   ├── workers/
│   ├── buyers/
│   ├── orders/
│   └── more/
│
└── main.dart
```

## Key Dependencies

- **flutter_bloc**: ^8.1.3 - State management
- **get_it**: ^8.0.2 - Dependency injection
- **dio**: ^5.7.0 - HTTP client
- **dartz**: ^0.10.1 - Functional programming (Either)
- **equatable**: ^2.0.5 - Value equality
- **json_annotation**: ^4.9.0 - JSON serialization
- **flutter_secure_storage**: ^9.2.2 - Secure token storage
- **shared_preferences**: ^2.3.4 - Local storage
- **logger**: ^2.5.0 - Logging

## Configuration

### Environment Setup
Copy `.env.example` to `.env` and configure:
```
API_BASE_URL=http://localhost:3000
```

### Build Configuration
Configure in `build.yaml` for code generation preferences.

## Code Generation

The app uses code generation for:
- JSON serialization (`json_serializable`)
- Dependency injection (future: `injectable`)

Always run build_runner after modifying:
- Data models with `@JsonSerializable()`
- Injectable classes (when using `@injectable`)

## Security

- JWT tokens stored in FlutterSecureStorage
- Automatic token refresh handling
- Encrypted shared preferences on Android
- Secure API communication with HTTPS

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

## Contributing

1. Follow Clean Architecture principles
2. Use BLoC pattern for state management
3. Add proper error handling
4. Write unit tests for use cases
5. Document complex logic
6. Run code generation after model changes

## License

Proprietary - EarnPost Platform
