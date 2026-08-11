# Project Structure

## Repository Layout

```
/
├── Task engine/          # Backend (NestJS)
├── Buyer app/            # Buyer Flutter app
├── Admin app/            # Admin dashboard (placeholder)
└── .kiro/                # Kiro workspace settings
```

## Backend Structure (Task Engine)

### Top-Level Organization

```
Task engine/
├── apps/                 # Application entry points
│   ├── api/             # Main REST API
│   └── worker/          # Background queue processors
├── shared/              # Shared infrastructure
│   ├── auth/           # Authentication & authorization
│   ├── common/         # Filters, interceptors, middleware
│   └── database/       # Entities, repositories, migrations
├── *-engine/           # Business logic engines (13 total)
├── package.json
├── tsconfig.json
└── .env.example
```

### Apps Directory

**`apps/api/`** - Main REST API server
- `main.ts` - Bootstrap, middleware, Swagger setup
- `app.module.ts` - Root module with all imports
- `controllers/` - Organized by user type
  - `auth/` - Registration, login, tokens
  - `worker/` - Task acceptance, submissions, earnings
  - `buyer/` - Order creation, progress tracking
  - `admin/` - Reviews, analytics, management
  - `webhooks/` - Payment callbacks, external integrations
  - `common/` - Shared endpoints

**`apps/worker/`** - Background processors
- `main.ts` - Queue worker bootstrap
- `processors/` - BullMQ job handlers

### Shared Directory

**`shared/auth/`**
- `auth.service.ts` - Login, registration, token management
- `strategies/jwt.strategy.ts` - JWT validation
- `guards/` - Route protection (jwt-auth, roles)
- `decorators/` - `@CurrentUser()`, `@Roles()`, `@Public()`
- `dto/` - Validation schemas

**`shared/database/`**
- `entities/` - TypeORM models (User, Worker, Task, Order, etc.)
- `repositories/` - Data access layer with custom queries
- `database.module.ts` - TypeORM configuration

**`shared/common/`**
- `filters/http-exception.filter.ts` - Global error handling
- `interceptors/response.interceptor.ts` - Response wrapper
- `middleware/` - Request ID, security headers, rate limiting

### Engine Modules (Business Logic)

Each engine follows the pattern: `{name}-engine/`

**Core Engines:**
- `task-engine/` - Task lifecycle, state machine, CRUD
- `matching-engine/` - Worker-task matching with filters
- `scoring-engine/` - Performance score calculation
- `ranking-engine/` - Worker ranking algorithms
- `allocation-engine/` - Task assignment strategies
- `eligibility-engine/` - Worker eligibility checks
- `reward-engine/` - Reward calculation with bonuses
- `review-engine/` - Submission review workflow
- `earning-engine/` - Earning calculation and posting
- `payout-engine/` - Withdrawal processing
- `progress-engine/` - Order/campaign/worker progress tracking
- `fraud-engine/` - Risk scoring and abuse detection
- `notification-engine/` - Multi-channel notifications

**Typical Engine Structure:**
```
{name}-engine/
├── {name}-engine.module.ts      # NestJS module
├── {name}.service.ts            # Main service
├── services/                    # Supporting services
├── types/                       # TypeScript interfaces
├── dto/                         # Data transfer objects
├── calculators/                 # Calculation logic
└── strategies/                  # Strategy pattern implementations
```

### Matching Engine (Example Deep Dive)

```
matching-engine/
├── matching-engine.module.ts
├── matching-engine.service.ts    # Orchestrates matching flow
├── services/
│   ├── context-builder.service.ts
│   ├── candidate-finder.service.ts
│   └── matching-decision.service.ts
├── filters/                      # Filter pipeline
│   ├── active-filter.service.ts
│   ├── kyc-filter.service.ts
│   ├── capacity-filter.service.ts
│   ├── location-filter.service.ts
│   ├── category-filter.service.ts
│   └── duplicate-filter.service.ts
└── types/
    └── matching-context.ts
```

## Flutter App Structure (Buyer App)

### Clean Architecture Pattern

```
lib/
├── main.dart                    # App entry point
├── core/                        # Cross-cutting concerns
│   ├── constants/              # App-wide constants
│   ├── di/                     # Dependency injection (get_it)
│   ├── errors/                 # Error types and failures
│   ├── network/                # Dio client, interceptors
│   ├── routes/                 # Navigation
│   ├── storage/                # Local/secure storage
│   └── theme/                  # App theme, colors, text styles
├── features/                    # Feature modules
│   ├── auth/
│   │   ├── data/               # Data sources, models, repositories
│   │   ├── domain/             # Entities, use cases, repository interfaces
│   │   └── presentation/       # Bloc, pages, widgets
│   ├── home/
│   ├── campaigns/
│   ├── analytics/
│   ├── payments/
│   ├── invoices/
│   ├── services/
│   ├── reviews/
│   ├── profile/
│   ├── settings/
│   ├── notifications/
│   └── support/
└── shared/
    └── presentation/           # Reusable widgets
        └── pages/
```

### Feature Module Pattern

Each feature follows clean architecture layers:

```
feature/
├── data/                       # External layer
│   ├── datasources/           # API, local DB
│   ├── models/                # JSON serializable
│   └── repositories/          # Implementation
├── domain/                     # Business logic layer
│   ├── entities/              # Business objects
│   ├── repositories/          # Interfaces
│   └── usecases/              # Business operations
└── presentation/               # UI layer
    ├── bloc/                  # State management
    ├── pages/                 # Screens
    └── widgets/               # UI components
```

## Key Architectural Patterns

### Backend
- **Modular Monolith**: Engines are independent modules, easy to extract later
- **Repository Pattern**: Centralized data access with custom queries
- **Strategy Pattern**: Pluggable algorithms (ranking, allocation)
- **Filter Pipeline**: Composable filters in matching engine
- **Event-Driven**: Engines emit events for async processing
- **Snapshot Pattern**: Immutable reward data at task creation

### Flutter Apps
- **Clean Architecture**: Separation of concerns (data/domain/presentation)
- **BLoC Pattern**: Predictable state management
- **Dependency Injection**: Loose coupling via get_it
- **Repository Pattern**: Abstract data sources
- **Use Case Pattern**: Single responsibility business operations

## Controller Organization

Controllers are thin and delegate to engines:

```typescript
// Example: Worker Task Controller
@Controller('api/v1/worker/tasks')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.WORKER)
export class TaskController {
  constructor(
    private taskEngine: TaskEngineService,
    private matchingEngine: MatchingEngineService,
  ) {}

  @Get('available')
  async getAvailableTasks(@CurrentUser() user: User) {
    // Thin controller - delegates to engine
    return this.matchingEngine.findAvailableTasksForWorker(user.id);
  }
}
```

## Path Aliases

Backend (tsconfig.json):
- `@engines/*` → Engine modules
- `@shared/*` → Shared infrastructure

## Documentation Files

- `README.md` - Current system overview, API surface
- `ARCHITECTURE.md` - Detailed architecture documentation
- `IMPLEMENTATION_SUMMARY.md` - Feature implementation status
- `SETUP.md` - Setup and running instructions

## Naming Conventions

### Backend
- **Files**: kebab-case (e.g., `matching-engine.service.ts`)
- **Classes**: PascalCase (e.g., `MatchingEngineService`)
- **Methods**: camelCase (e.g., `findAvailableWorkers()`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_TASKS_PER_WORKER`)
- **Interfaces**: PascalCase with `I` prefix optional (e.g., `MatchingContext`)

### Flutter
- **Files**: snake_case (e.g., `auth_bloc.dart`)
- **Classes**: PascalCase (e.g., `AuthBloc`)
- **Variables**: camelCase (e.g., `userName`)
- **Constants**: lowerCamelCase (e.g., `kPrimaryColor`)
- **Private**: underscore prefix (e.g., `_privateMethod()`)
