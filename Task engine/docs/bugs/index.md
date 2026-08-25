# Bug Log & Solutions

This directory serves as a centralized knowledge base for all critical bugs encountered during the development and deployment of the Task Engine.

## Bug Registry

| Bug ID | Title | Module | Date Fixed |
| :--- | :--- | :--- | :--- |
| [001](./001-typeorm-duplicate-index.md) | TypeORM Duplicate Key Name on Sync | Database / TypeORM | Aug 2026 |
| [002](./002-webpack-entity-resolution.md) | Webpack Entity Glob Pattern Resolution Failure | Database / Webpack | Aug 2026 |
| [003](./003-backend-auth-and-schema-bugs.md) | 500 Schema Errors & 403 Auth Missing Token Issue | Database / Auth | Aug 2026 |
| [004](./004-admin-app-auth-logout-bugs.md) | Admin App AuthException, Logout Failure & Bad State Bug | Frontend / Auth | Aug 2026 |
| [005](./005-screen-state-disappearing-bug.md) | BLoC State Inheritance & List Disappearing Bug | Frontend / Architecture | Aug 2026 |
| [006](./006-real-worker-detail-dummy-data-fix.md) | Worker Detail Tabs Displaying Hardcoded Dummy Data | Frontend / Dynamic Data Binding | Aug 2026 |
| [007](./007-service-publish-string-type-fix.md) | Service Publish Type Cast Failure (`String is not num`) | Frontend / Service Builder | Aug 2026 |
| [008](./008-buyer-app-service-catalog-fix.md) | Buyer App Missing Services & Type Cast Error | Frontend / Buyer Services | Aug 2026 |
| [009](./009-worker-app-403-insufficient-permissions-and-fetch-failure.md) | Worker App 403 Insufficient Permissions & Auth Failure | Backend & Frontend / Auth | Aug 2026 |

## How to add a new bug
1. Create a new markdown file named `XXX-bug-name.md`.
2. Follow the standard template:
   - **Issue Description:** What was happening?
   - **Root Cause:** Why did it happen?
   - **Affected Files:** Where was the fix applied?
   - **Solution:** How was it fixed (include code snippets)?
   - **How to Prevent:** Guidelines for the future.
3. Add an entry to the `Bug Registry` table in this `index.md` file.
