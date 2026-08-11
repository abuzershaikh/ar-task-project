# Technology Stack

## Backend (Task Engine)

### Core Stack
- **Runtime**: Node.js with TypeScript 5.1+
- **Framework**: NestJS 10.x (modular monolith architecture)
- **Database**: MySQL with TypeORM 0.3.17
- **Queue System**: BullMQ + Redis (for background processing)
- **Authentication**: JWT (passport-jwt)
- **API Documentation**: Swagger/OpenAPI
- **Validation**: class-validator + class-transformer

### Key Dependencies
- `@nestjs/common`, `@nestjs/core`, `@nestjs/platform-express`
- `@nestjs/typeorm`, `@nestjs/config`, `@nestjs/jwt`, `@nestjs/passport`
- `typeorm`, `mysql2`, `bull`, `ioredis`
- `bcrypt` (password hashing), `uuid`, `dayjs`

### TypeScript Configuration
- Target: ES2021
- Module: CommonJS
- Decorators: Enabled (experimental)
- Path aliases: `@engines/*`, `@shared/*`
- Strict checks: Relaxed for faster development

## Mobile Apps

### Worker App (Android)
- **Framework**: Flutter 3.0+
- **Language**: Dart
- **State Management**: flutter_bloc + equatable
- **Dependency Injection**: get_it
- **Networking**: dio + retrofit
- **Storage**: shared_preferences + flutter_secure_storage

### Buyer App (Flutter/Web)
- **Framework**: Flutter 3.0+
- **State Management**: flutter_bloc
- **UI Libraries**: 
  - Charts: fl_chart, syncfusion_flutter_charts
  - Forms: flutter_form_builder
  - Images: cached_network_image, image_picker
- **Payment**: razorpay_flutter
- **PDF**: pdf + printing packages
- **Notifications**: firebase_messaging + firebase_core

## Common Commands

### Backend (Task Engine)

```bash
# Install dependencies
npm install

# Development
npm run start:dev          # Start with hot reload
npm run start:debug        # Start in debug mode

# Build & Production
npm run build              # Compile TypeScript
npm run start:prod         # Run production build

# Database
npm run migration:generate # Generate migration
npm run migration:run      # Apply migrations
npm run migration:revert   # Rollback migration

# Testing
npm test                   # Run tests
npm run test:watch         # Watch mode
npm run test:cov           # With coverage

# Code Quality
npm run lint               # ESLint with auto-fix
```

### Flutter Apps

```bash
# Install dependencies
flutter pub get

# Run apps
flutter run                # Run on connected device
flutter run --release      # Release build

# Build
flutter build apk          # Build Android APK
flutter build appbundle    # Build Android App Bundle
flutter build web          # Build web version

# Code generation (for dio/retrofit)
flutter pub run build_runner build --delete-conflicting-outputs

# Analysis
flutter analyze            # Static analysis
```

## Important Technical Constraints

### Do NOT Introduce
- ❌ Docker (local setup only)
- ❌ Microservices architecture (keep modular monolith)
- ❌ Additional databases beyond MySQL
- ❌ GraphQL (REST API only)
- ❌ Message brokers like Kafka

### Keep As-Is
- ✅ MySQL as primary database
- ✅ TypeORM for data access
- ✅ Modular engine structure
- ✅ Direct database access (engines don't call APIs)
- ✅ `/api/v1` prefix for all endpoints

## Environment Variables (Backend)

Required in `.env`:
```
PORT=3000
DB_HOST=localhost
DB_PORT=3306
DB_USERNAME=root
DB_PASSWORD=your_password
DB_DATABASE=task_platform
JWT_SECRET=your_jwt_secret
JWT_REFRESH_SECRET=your_refresh_secret
```
