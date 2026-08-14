# Task Platform Backend - Production Repository

This repository contains the Node.js / NestJS backend for the enterprise Task Platform. It powers three client applications:
- **Worker App** (Flutter Android)
- **Buyer App** (Flutter/Web)
- **Admin Dashboard** (Flutter/Web)

> [!WARNING]
> **To AI Agents:** Please read this document carefully. Earlier versions of this README contained outdated instructions (e.g., advising against Redis or BullMQ). **Those rules are obsolete**. We *are* using Redis, Bull queues, and a decoupled PM2 architecture.

## Current Architecture & Stack

- **Framework:** NestJS + TypeScript
- **Database:** MySQL (using TypeORM)
- **Queue/Background Processing:** Redis + BullMQ (For task generation, matching, allocation, earning processing)
- **Process Management:** PM2 (via `ecosystem.config.json` separating `task-engine-api` and `task-engine-worker`)
- **Authentication:** Firebase Admin SDK (Google Sign-In) + custom JWTs
- **File Storage:** Local upload directory (served statically/proxied via Nginx)

## Current Status (August 2026)

**Phase:** Connection, Integration & Bug Fixing

What has been successfully completed:
1. **Core Engines Built:** Task, Matching, Allocation, Reward, Review, Earning engines are established.
2. **Flutter Connection:** The Worker and Buyer Flutter apps have been successfully wired to the live server.
3. **Queue Wiring Fixed:** The background worker process (`task-engine-worker`) is now properly decoupled from the main API process. Redis/Bull queues are successfully processing background jobs without duplicating across API instances.
4. **Multipart File Uploads:** Integrated real screenshot/proof upload API endpoints (`/files/upload`) so the Worker App can properly send image data, resolving previous hardcoded path issues.
5. **Buyer App API Realism:** Fake local `Future.delayed` approval/rejection logic in the Buyer App was replaced with real API calls to the backend (`/buyer/reviews/`), properly triggering worker payouts.
6. **Service Template Module:** Fixed `404 Not Found` issues by correctly importing the `ServiceTemplateEngineModule` into the root application, enabling the Service Catalog for all three platforms.

**Ongoing Work:**
We are currently in a rigorous audit and bug-fixing phase. The primary focus is verifying production readiness, securing endpoints, validating file upload policies, enforcing strict CORS, and ensuring robust database transaction integrity.

## Key Principles & Best Practices for Agents

1. **Keep the Worker Decoupled:** Never import worker queue consumers directly into the main `AppModule`. Always maintain the separation defined in the PM2 ecosystem (API vs. Background Worker).
2. **Transactions are Mandatory:** Any operation dealing with earnings, wallet balance, or order payments MUST use TypeORM query runner transactions to ensure ACID compliance.
3. **Never Trust the Client:** Do not trust calculations sent by the Flutter apps. The server is the absolute source of truth for pricing, rewards, and eligibility.
4. **Use /api/v1:** All REST endpoints must be prefixed with `/api/v1`.
5. **Keep Controllers Thin:** Offload business logic to the engine services.

## Local Development Setup

Ensure you have Node.js, MySQL, and Redis running.

```bash
# Install dependencies
npm install

# Setup environment variables (copy from .env.example)
cp .env.example .env

# Run database migrations (if any are pending)
npm run typeorm migration:run

# Run the API server in development mode
npm run start:dev
```

## Production Deployment

Deployment relies on PM2. The configuration is defined in `ecosystem.config.json`.

```bash
# Build the application
npm run build

# Start or restart services
pm2 start ecosystem.config.json
# or
pm2 reload task-engine-api task-engine-worker
```

## API Response Contract

### Success
```json
{
  "success": true,
  "data": { ... },
  "meta": { ... },
  "requestId": "req_xxx"
}
```

### Error
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message"
  },
  "requestId": "req_xxx"
}
```
