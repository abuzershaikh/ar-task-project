# Backend Bug Fix Report: 500 Schema Errors & 403 Forbidden Auth Issue

This document outlines two critical bugs that caused the admin dashboard to fail, the root causes for each, and the step-by-step methods used to identify and fix them. This will serve as a reference so future occurrences can be resolved in minutes.

---

## Bug 1: 500 Internal Server Error (Database Schema Mismatch)

### Symptom (What the user sees)
When opening specific pages in the frontend (such as the Dashboard or Orders page), the UI shows an error or fails to load data. The backend logs report a silent `500 Internal Server Error`, or if stack traces are enabled, `QueryFailedError: Unknown column 'Entity.column_name' in 'field list'`.

### Cause
The TypeORM entities in the backend code (e.g., `KycProfile`, `Order`) had new columns added to them (like `paypal_id`, `extension_count`). However, the production MySQL database did not have these new columns because schema changes do not automatically sync on production by default. 

### How it was Identified
1. The backend originally returned a generic 500 error without details.
2. The `HttpExceptionFilter` (`shared/common/filters/http-exception.filter.ts`) was updated to log the actual `exception.stack` for 500 errors to the PM2 error logs.
3. Checking the PM2 error logs revealed exactly which SQL query failed and which column was missing (`paypal_id` and later `extension_count`).

### How it was Fixed (Cure)
Manually add the missing columns to the production database using `ALTER TABLE`.
For example, a quick Node script over SSH (or direct MySQL connection) was used:
```sql
ALTER TABLE kyc_profiles ADD COLUMN paypal_id VARCHAR(255) NULL;
ALTER TABLE orders ADD COLUMN extension_count INT DEFAULT 0;
ALTER TABLE orders ADD COLUMN extension_history JSON NULL;
```
*Note: In the future, this can be permanently prevented by ensuring a proper database migration strategy is run during the CI/CD deployment phase before the app restarts.*

---

## Bug 2: 403 Forbidden on Missing/Invalid Tokens (Frontend App Lockup)

### Symptom (What the user sees)
The user opens the Admin (or Worker/Buyer) Flutter app and receives a server error ("Insufficient Permissions"). They are stuck on a broken screen, and the app does not automatically redirect them to the Login page. 

### Cause
In the `JwtAuthGuard` (`shared/auth/guards/jwt-auth.guard.ts`), there was a "development fallback" that assigned a default `UserRole.WORKER` object to `request.user` if the `Authorization` header was missing or `null`. 
When the Flutter app encountered an old/invalid token, it cleared its local token but did not navigate to the login screen. On the next request, the app sent NO token. 
1. `JwtAuthGuard` saw no token and assigned the dummy `WORKER` role.
2. `RolesGuard` (`shared/auth/guards/roles.guard.ts`) evaluated the request for an admin endpoint.
3. It saw `WORKER` instead of `ADMIN/SUPER_ADMIN` and threw a `403 Forbidden`.
4. The Flutter app's `DioClient` intercepts `401 Unauthorized` to clear the session and force a logout, but it **did not handle `403 Forbidden`**. As a result, the user was permanently stuck on the error screen without being logged out.

### How it was Identified
1. `RolesGuard` logs were added to print `Got: WORKER` during 403 errors.
2. PM2 Out logs confirmed the app was hitting `GET /api/v1/admin/dashboard` returning `403` instead of the expected `401` when unauthenticated.
3. Reviewing `JwtAuthGuard` revealed the hardcoded fallback.

### How it was Fixed (Cure)
The insecure fallback was removed entirely from `JwtAuthGuard`. 
Now, if a request does not contain a valid `Authorization` header, the guard explicitly throws an `UnauthorizedException(401)`.

```typescript
// Removed the dummy fallback and replaced it with:
if (headers['authorization']) {
  return (await super.canActivate(context)) as boolean;
}
throw new UnauthorizedException('No authorization token provided');
```
With this fix, the backend accurately responds with `401 Unauthorized`. The frontend's `DioClient` automatically catches the `401`, clears the token properly, and throws an exception that will force the user back to the Login screen.

---

## Quick Debugging Checklist for the Future

If similar API issues occur:
1. **Check Logs:** Run `pm2 logs task-engine-api --err --lines 100` on the server to see real-time error traces.
2. **Missing Columns:** If you see `Unknown column`, create a quick SQL migration script in `deploy.js` to `ALTER TABLE` and add the missing columns.
3. **Auth Issues (401 vs 403):** 
   - `401 Unauthorized`: Token is missing, expired, or the `userId` in the payload no longer exists in the DB.
   - `403 Forbidden`: Token is valid, but the user's role in the database does not have permission for the endpoint. Check their role in the `users` table.
