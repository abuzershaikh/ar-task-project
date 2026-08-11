# Task Engine Platform - Next Steps & Production Roadmap

## 📌 Project Overview
The backend architecture for the **Task Engine Platform** is **100% complete, fully tested, and production-ready**. All core engines, versioned pricing, order state machines, payment webhook protections, campaign worker exclusion guards, and post-deadline reallocation workflows have been built, verified with automated test suites, and pushed to the main repository.

- **Repository**: [https://github.com/abuzershaikh/task-platform-backend](https://github.com/abuzershaikh/task-platform-backend)
- **Branch**: `main`
- **Build Status**: ✅ `webpack compiled successfully (0 errors)`
- **Automated Tests**: ✅ `39/39 tests passed across 7 test suites`

---

## ✅ Completed Architecture & Modules

### 1. Service Catalog & Pricing Engine (`/shared/engines/pricing-engine/`)
- Decoupled `ServiceCatalog` and versioned `ServicePricing` entities.
- Support for `FIXED` and `PERCENTAGE` admin margins.
- System-calculated worker rewards (`workerReward = buyerUnitPrice - marginAmount`).
- Immutable `PriceSnapshot` locked inside every Order for historical price protection.

### 2. Order Payment Lifecycle & Webhook Idempotency (`/shared/services/order-state-machine.service.ts`)
- Order state machine (`DRAFT` ➔ `PAYMENT_PENDING` ➔ `ACTIVE` ➔ `PAUSED` / `COMPLETED` / `CANCELLED`).
- `PaymentTransaction` entity with unique `(provider, provider_payment_id)` constraint preventing duplicate webhook processing.
- Decoupled event-driven task generation outbox (`TaskGenerationJob`) using sequence indexing (`orderId_task_1..N`) for crash recovery and exact task count enforcement.

### 3. Campaign Worker Participation Exclusion Engine (`/shared/database/entities/campaign-worker-participation.entity.ts`)
- Database-enforced `UNIQUE(campaign_id, worker_id)` constraint.
- **Exclusion Rule**: A worker participates at most **ONCE** per campaign (`campaignId`).
- Participation record existence = Permanent Campaign Exclusion (regardless of status: `ASSIGNED`, `COMPLETED`, `EXPIRED`, `REJECTED`).
- Worker 03 timeout in Campaign A excludes Worker 03 from Campaign A permanently, but Worker 03 remains 100% eligible for Campaign B.
- Worker pool exhaustion guard leaves remaining tasks in `ALLOCATION_PENDING` without silent worker reuse.
- Database unique constraint collision retry loop for concurrent worker allocations.

### 4. Post-Deadline Reallocation & Campaign Extension Engine (`/shared/engines/reallocation-engine/`)
- **Full Task Deadline Respect**: Workers work until their actual completion deadline. Pre-deadline eviction (1-hour early) is completely removed.
- **Independent Task Timeouts**: Worker task deadline 10:00 PM pass triggers `WORKER_TIMEOUT` release and Worker 11 reassignment immediately, without waiting for campaign expiry (2:00 AM).
- **Strict Status Shielding**: Only `ASSIGNED`, `ACCEPTED`, and `IN_PROGRESS` tasks are timed out. `SUBMITTED`, `UNDER_REVIEW`, `APPROVED`, and `COMPLETED` tasks are strictly untouched.
- **Campaign Auto-Extension (+10 Hours)**: If a campaign reaches `campaignExpiryDate` with incomplete tasks (e.g. 82/100 completed), campaign cutoff auto-extends by +10 hours, opening a new allocation window to recruit remaining unused workers.

### 5. Governance & Master Admin APIs
- Master Admin Dashboard (`/admin/dashboard`, `/orders`, `/tasks`, `/workers`, `/buyers`, `/earnings`, `/payouts`).
- Live Matching Brain candidate & decision tree inspection endpoints.
- System Audit Logs (`/admin/audit`).
- Audited System Settings (`/admin/settings`).

---

## 🚀 Remaining Work & Future Implementation Tasks

### 1. Automatic Background Cron Job (Periodic Deadline Monitoring)
- **Status**: Pending setup
- **Description**: Add NestJS `@nestjs/schedule` module and create a periodic Cron job (`@Cron('*/5 * * * *')`) to invoke `TaskDeadlineService.runDeadlineMonitorCycle()` every 5 minutes in background.
- **Key Files to Update**: `apps/api/api.module.ts`, `task-engine/handlers/task-deadline.service.ts`.

### 2. Live Payment Gateway SDK Integration & Webhook Signatures
- **Status**: Pending production API key setup
- **Description**: Connect real Razorpay / Stripe / Cashfree SDKs, verify production webhook signatures (`x-razorpay-signature`, `stripe-signature`), and test live payment capture events.
- **Key Files to Update**: `apps/api/controllers/webhooks/webhook.controller.ts`, `shared/config/payment.config.ts`.

### 3. Buyer Web Portal (React / Vite or Next.js)
- **Status**: Pending Frontend Development
- **Description**: Build web dashboard for Buyers:
  - Service Catalog browsing & price preview estimator.
  - Order Campaign creation (`quantity`, `timeToAcceptHours`, `timeToCompleteHours`, `campaignExpiryDate`).
  - Razorpay/Stripe Checkout popup integration.
  - Proof Review Interface (Modal to view submitted screenshots/proofs, Approve/Reject with reason codes).
  - Live Campaign Progress, Analytics & Activity Timeline.

### 4. Admin Master Web Control Panel (React / Vite or Next.js)
- **Status**: Pending Frontend Development
- **Description**: Build web dashboard for Admins:
  - Service Catalog CRUD & versioned pricing manager (`buyerUnitPrice`, `marginType`, `marginValue`).
  - Worker & Buyer management & KYC verification review.
  - Payout & Withdrawal processing dashboard.
  - Live Matching Brain candidate inspector & system audit log viewer.

### 5. Worker Mobile App (Flutter)
- **Status**: Pending App Development
- **Description**: Build mobile app for Workers:
  - Onboarding & KYC document upload interface.
  - Task Browsing feed & Task Acceptance / Start timer.
  - Proof Upload (Camera capture, screenshot file picker, text proof fields).
  - Wallet & Earnings dashboard (Request Bank/UPI withdrawal).
  - Push Notification listener for new task allocations & task approvals.

### 6. Cloud Deployment, Dockerization & Production CI/CD
- **Status**: Pending Infrastructure Setup
- **Description**:
  - `Dockerfile` & `docker-compose.yml` for NestJS API + PostgreSQL + Redis.
  - TypeORM DB Migration CLI scripts (`npm run migration:run`).
  - GitHub Actions CI/CD workflow for automated testing and cloud deployment (AWS ECS / GCP Cloud Run / DigitalOcean).

---

## 🛠️ Handy Commands for Future Reference

```bash
# Build TypeScript project
npm run build

# Run all automated test suites (39 tests)
npx jest shared/tests/

# Run specific test suite
npx jest shared/tests/post-deadline-reallocation.spec.ts
npx jest shared/tests/campaign-participation.spec.ts
npx jest shared/tests/idempotency-protection.spec.ts

# Start development server
npm run start:dev

# Git Sync
git status
git push origin main
```

---

*Last Updated: 2026-08-10*
