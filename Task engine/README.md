# Task Platform Backend Handoff

This repository is the backend for an enterprise task platform with three clients:

- Worker Flutter Android app
- Buyer Flutter/Web app
- Admin dashboard

The old README in this repo was outdated. This file is based on the current codebase only.

## Current Backend Shape

The backend is a NestJS + TypeScript + TypeORM modular monolith using MySQL.

Current bootstrap and core wiring already exist in:

- `apps/api/main.ts`
- `apps/api/app.module.ts`
- `shared/auth/auth.module.ts`
- `shared/database/database.module.ts`

Current code already includes:

- JWT auth
- RBAC guards
- Request ID middleware
- Standard response interceptor
- Global exception filter
- Swagger bootstrap
- Core engines for task, matching, scoring, ranking, allocation, reward, review, earning, progress, eligibility, payout
- Base repository layer for major entities

## Important Rules

- Do not introduce Docker.
- Do not introduce Redis for the current backend flow.
- Do not introduce BullMQ or Kafka for the current backend flow.
- Keep MySQL as the primary database.
- Keep TypeORM.
- Keep the existing modular engine structure.
- Controllers must stay thin.
- Business logic must live in services/engines.
- Use `/api/v1`.
- Keep APIs idempotent where the operation is sensitive.
- Use transactions for money and critical state changes.
- Never trust Flutter-side calculations.
- Server is the source of truth for task, reward, wallet, earning, payout, and status.

## What Already Exists

### Auth

Files:

- `shared/auth/auth.service.ts`
- `shared/auth/auth.module.ts`
- `shared/auth/strategies/jwt.strategy.ts`
- `shared/auth/guards/jwt-auth.guard.ts`
- `shared/auth/guards/roles.guard.ts`
- `shared/auth/decorators/current-user.decorator.ts`
- `shared/auth/decorators/public.decorator.ts`
- `shared/auth/decorators/roles.decorator.ts`
- `shared/auth/dto/register.dto.ts`
- `shared/auth/dto/login.dto.ts`
- `shared/auth/dto/refresh-token.dto.ts`
- `shared/auth/dto/forgot-password.dto.ts`
- `shared/auth/dto/reset-password.dto.ts`

Implemented auth endpoints:

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/logout`
- `POST /api/v1/auth/forgot-password`
- `POST /api/v1/auth/reset-password`
- `GET /api/v1/auth/me`

### Bootstrap and API Standards

Already wired:

- Global validation pipe
- Global exception filter
- Global response wrapper
- Request ID middleware
- Basic security headers middleware
- In-memory rate limiting middleware
- Swagger docs at `/api/docs`
- CORS enabled

### Existing Engine Modules

Already present:

- Task engine
- Matching engine
- Eligibility engine
- Scoring engine
- Ranking engine
- Allocation engine
- Reward engine
- Review engine
- Earning engine
- Payout engine
- Progress engine

### Existing Entities

Already present in `shared/database/entities`:

- `user.entity.ts`
- `worker.entity.ts`
- `worker-score.entity.ts`
- `order.entity.ts`
- `task.entity.ts`
- `submission.entity.ts`
- `earning.entity.ts`
- `withdrawal.entity.ts`
- `kyc.entity.ts`
- `payment-method.entity.ts`
- `rating.entity.ts`
- `file.entity.ts`
- `notification.entity.ts`
- `audit-log.entity.ts`

### Existing Controllers

Already wired in `apps/api/app.module.ts`:

- `apps/api/controllers/auth/auth.controller.ts`
- `apps/api/controllers/worker/task.controller.ts`
- `apps/api/controllers/worker/earning.controller.ts`
- `apps/api/controllers/buyer/order.controller.ts`
- `apps/api/controllers/admin/review.controller.ts`
- `apps/api/controllers/admin/analytics.controller.ts`

## Current API Surface

### Worker

Current worker task endpoints exist:

- `GET /api/v1/worker/tasks/available`
- `GET /api/v1/worker/tasks/assigned`
- `POST /api/v1/worker/tasks/:id/accept`
- `POST /api/v1/worker/tasks/:id/start`
- `POST /api/v1/worker/tasks/:id/submit`
- `GET /api/v1/worker/tasks/progress`

Current worker earning endpoints exist:

- `GET /api/v1/worker/earnings`
- `GET /api/v1/worker/earnings/balance`
- `POST /api/v1/worker/earnings/withdraw`
- `GET /api/v1/worker/earnings/withdrawals`

### Buyer

Current buyer order endpoints exist:

- `POST /api/v1/buyer/orders`
- `GET /api/v1/buyer/orders`
- `GET /api/v1/buyer/orders/:id`
- `GET /api/v1/buyer/orders/:id/progress`
- `POST /api/v1/buyer/orders/:id/cancel`

### Admin

Current admin endpoints exist:

- `GET /api/v1/admin/reviews/pending`
- `POST /api/v1/admin/reviews/:submissionId/approve`
- `POST /api/v1/admin/reviews/:submissionId/reject`
- `GET /api/v1/admin/reviews/stats`
- `GET /api/v1/admin/analytics/overview`
- `GET /api/v1/admin/analytics/tasks`
- `GET /api/v1/admin/analytics/workers`
- `GET /api/v1/admin/analytics/revenue`

## What Still Needs To Be Built

This is the actual remaining work for the backend.

### 1. Worker App APIs

Build:

- Worker profile
- Worker dashboard
- Worker stats
- Available/assigned/accepted/in-progress/submitted/review/approved/rejected/completed task lists
- Worker task detail access with ownership checks
- Worker proof upload and proof metadata APIs
- Worker KYC create/submit/status/documents APIs
- Worker ratings and rating summary APIs
- Worker earnings history/pending/available/detail APIs
- Worker wallet summary and transactions APIs
- Worker payment methods CRUD
- Worker withdrawals CRUD and state transitions
- Worker notifications list/read/read-all/unread-count

### 2. Buyer App APIs

Build:

- Buyer dashboard
- Buyer order detail with ownership validation
- Buyer order progress and task/submission views
- Buyer review queue
- Buyer task rating
- Buyer payments and invoices
- Buyer wallet/billing views
- Buyer notifications

### 3. Admin Dashboard APIs

Build:

- Admin dashboard
- Buyer management
- Worker management
- Task management
- Review management
- KYC management
- Payout management
- Matching visibility APIs
- Scoring configuration APIs
- Progress overview APIs
- Audit log APIs
- Notifications overview

### 4. File / Proof / KYC Storage

Build proper APIs and service layer for:

- File upload
- File metadata persistence
- Proof-to-task/submission linkage
- KYC document storage
- Secure file references
- Private file access rules

### 5. Financial Safety

Need real implementations for:

- Reward snapshot usage
- Earning posting
- Wallet ledger/source of truth
- Withdrawal idempotency
- Payout reconciliation
- Duplicate transaction protection
- Transaction-based state updates

### 6. Audit Logging

Need centralized append-only audit logging for:

- login/logout
- task assignment/acceptance/submission
- review actions
- KYC actions
- payout actions
- permission changes
- admin actions

### 7. Tests

Need:

- Unit tests for state machine and engines
- Integration tests for accept/submit/approve/earning/withdrawal/payout
- E2E flow tests for worker, buyer, and admin journeys

### 8. Database Migrations

No migration strategy is finished yet for the current entity changes.

Need migrations for:

- auth token/reset-token columns
- any new missing entity columns
- indexes for task/order/earning/payout/kyc/audit usage

### 9. Cleanup / Compatibility

The codebase still has older queue-related and Redis/Bull references in some areas.

Need to either:

- remove them from active runtime paths, or
- replace them with a non-Redis abstraction

## Data Contract For Mobile And Dashboard Clients

### Success

```json
{
  "success": true,
  "data": {},
  "meta": {},
  "requestId": "req_xxx"
}
```

### Error

```json
{
  "success": false,
  "error": {
    "code": "TASK_NOT_FOUND",
    "message": "Task not found"
  },
  "requestId": "req_xxx"
}
```

## Recommended Build Order For The Next AI Agent

### Phase 1

- Finish auth hardening
- Finish global error handling
- Add missing DTOs and validation for all surfaces
- Add Swagger decorators and examples

### Phase 2

- Worker profile/dashboard/tasks/proofs/KYC/ratings/earnings/wallet/payment methods/withdrawals

### Phase 3

- Buyer dashboard/orders/progress/reviews/payments/invoices

### Phase 4

- Admin dashboard and management APIs

### Phase 5

- Audit logs
- Notifications
- Migrations
- Tests
- Security hardening

## Current Core Files To Continue Editing

If the next agent needs the main entry points, start here:

- `apps/api/main.ts`
- `apps/api/app.module.ts`
- `shared/auth/auth.service.ts`
- `shared/auth/auth.module.ts`
- `shared/common/filters/http-exception.filter.ts`
- `shared/common/interceptors/response.interceptor.ts`
- `shared/database/database.module.ts`
- `shared/database/repositories/*.ts`
- `task-engine/task-engine.service.ts`
- `task-engine/handlers/task-command.service.ts`
- `progress-engine/progress.service.ts`
- `payout-engine/payout.service.ts`
- `review-engine/review.service.ts`

## Local Run Notes

Expected commands:

```bash
npm install
npm run start:dev
npm run build
npm run migration:run
```

Expected env vars:

```bash
PORT
DB_HOST
DB_PORT
DB_USERNAME
DB_PASSWORD
DB_DATABASE
JWT_SECRET
JWT_REFRESH_SECRET
```

## Important Reminder

Do not trust the old README. Use the source code in this repository as the source of truth.
