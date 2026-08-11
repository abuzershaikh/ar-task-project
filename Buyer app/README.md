# Marketing Pro - Buyer App

Complete Campaign Management Platform for Buyers with Enterprise-Grade UX

## Features

### Core Modules (5-Tab Navigation)
- **Home Dashboard** - Balance, campaigns overview, stats, quick actions, and pending reviews
- **Campaigns** - Browse, create, and manage campaigns with dedicated detail screens
- **Reviews** - Review worker submissions, approve/reject tasks, and rate workers
- **Analytics** - Detailed performance reports and insights with charts
- **More** - Wallet, payments, invoices, notifications, profile, settings, and support

### Key Features
- **Wallet System** - Prepaid balance with Available/Reserved split for secure payments
- **Step-by-Step Campaign Creation** - Guided wizard from service selection to payment
- **Campaign Detail Tabs** - Overview, Tasks, Reviews, Activity, Analytics per campaign
- **Real-Time Balance** - Dynamic balance updates with reservation system
- **Worker Rating** - Rate worker performance after approval

## Project Structure

```
lib/
├── core/
│   ├── constants/       # App constants and configuration
│   ├── di/             # Dependency injection setup
│   ├── errors/         # Error handling and exceptions
│   ├── network/        # Network layer (Dio, interceptors)
│   ├── routes/         # Navigation and routing
│   ├── storage/        # Local and secure storage
│   └── theme/          # App theme, colors, and text styles
├── features/
│   ├── auth/           # Authentication (login, register)
│   ├── home/           # Dashboard and overview
│   ├── campaigns/      # Campaign management
│   ├── services/       # Service catalog
│   ├── reviews/        # Worker submission reviews
│   ├── analytics/      # Reports and analytics
│   ├── payments/       # Payment processing
│   ├── invoices/       # Invoice management
│   ├── notifications/  # Push notifications
│   ├── profile/        # User profile
│   ├── support/        # Help and support
│   └── settings/       # App settings
└── shared/
    └── presentation/   # Shared widgets and pages
```

## Architecture

- **Clean Architecture** with separation of concerns
- **BLoC Pattern** for state management
- **Repository Pattern** for data access
- **Dependency Injection** with GetIt
- **Feature-based** folder structure

Each feature follows:
```
feature/
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

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android SDK
- Android Studio / VS Code

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd "Buyer app"
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure API endpoints in `lib/core/constants/app_constants.dart`

4. Run the app
```bash
flutter run
```

## Configuration

### API Base URL
Update in `lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = 'YOUR_API_BASE_URL';
```

### Payment Gateway
Configure Razorpay key:
```dart
static const String razorpayKey = 'YOUR_RAZORPAY_KEY';
```

## Build

### Debug Build
```bash
flutter build apk --debug
```

### Release Build
```bash
flutter build apk --release
```

### App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

## Key Dependencies

- **flutter_bloc** - State management
- **dio** - HTTP client
- **get_it** - Dependency injection
- **shared_preferences** - Local storage
- **flutter_secure_storage** - Secure storage for tokens
- **fl_chart** - Charts and graphs
- **razorpay_flutter** - Payment integration

## App Details

- **Package Name**: com.buy.taskpost.marketing
- **App Name**: Marketing Pro
- **Platform**: Android
- **Minimum SDK**: 21
- **Target SDK**: 34

## Features Overview

### 🏠 Home Dashboard
- Total spend and campaign statistics
- Active campaigns overview
- Recent campaign list
- Quick actions (Create, Performance, Payments)
- Campaign progress tracking

### 🛒 Services
- Browse available services
- Service details and pricing
- Buy services to create campaigns

### ➕ Create Campaign
- Select service
- Define campaign parameters
- Set quantity and timing
- Configure review settings
- Payment and checkout

### 📋 Campaigns
- View all campaigns (All, Active, In Progress, Completed, Paused, Cancelled)
- Campaign details and progress
- Task timeline and status
- Worker submissions

### ✓ Reviews
- Pending worker submissions
- Approve/Reject tasks
- Request changes
- Rate worker performance

### 📊 Analytics
- Campaign performance metrics
- Completion rates
- Task trends
- Detailed reports

### 💳 Payments
- Payment history
- Transaction details
- Payment status tracking

### 🧾 Invoices
- Download invoices
- View billing history

### 🔔 Notifications
- Real-time campaign updates
- Task completion alerts
- Payment notifications

### 👤 Profile
- Business profile management
- Account settings
- Support and help

## Development Guidelines

1. Follow clean architecture principles
2. Use BLoC for state management
3. Keep widgets small and reusable
4. Write meaningful comments
5. Handle errors gracefully
6. Use const constructors where possible

## Security

- Access tokens stored in secure storage
- Auto token refresh on 401 errors
- API requests authenticated with Bearer tokens
- Sensitive data encrypted

## Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## Troubleshooting

### Common Issues

1. **Build fails**: Run `flutter clean && flutter pub get`
2. **Hot reload not working**: Restart the app
3. **Network errors**: Check API base URL configuration

## Support

For issues and support, contact: support@taskpost.com

## License

Proprietary - All rights reserved
