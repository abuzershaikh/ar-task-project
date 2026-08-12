# Bug: TypeORM ER_NO_SUCH_TABLE in Production (Webpack Build)

## Issue Description
When running the NestJS application in production (compiled via Webpack into a single `main.js` file), API requests crashed with `ER_NO_SUCH_TABLE` (e.g., `Table 'task_platform.users' doesn't exist`). However, the database tables were never created upon startup despite `synchronize: true` being enabled in development environments.

## Root Cause
In `database.config.ts`, entities were being loaded using glob string patterns:
```typescript
entities: [__dirname + '/../**/*.entity{.ts,.js}']
```
When Webpack compiles the NestJS application, it bundles everything into a single `main.js` file. The original file structure (and the `.entity.js` files) no longer exists in the output directory. Therefore, TypeORM's glob pattern fails to find any entities, resulting in an empty database schema during synchronization.

## Affected Files
- `shared/config/database.config.ts`
- `apps/api/main.ts` (Requires `.env` loading)

## Solution
1. Switched from glob patterns to using `autoLoadEntities: true` in `TypeOrmModule.forRootAsync()`.
2. Ensure that entities are explicitly registered in the feature modules via `TypeOrmModule.forFeature([Entity1, Entity2])`. `autoLoadEntities` will automatically collect any entities registered this way without relying on file system paths.

Example of fixed configuration (`database.config.ts`):
```typescript
export const databaseConfig: TypeOrmModuleOptions = {
    // ...
    autoLoadEntities: true, 
    synchronize: process.env.NODE_ENV === 'development',
};
```

## How to Prevent
Never use `__dirname` or glob patterns for loading entities, migrations, or subscribers in a NestJS project that uses Webpack for bundling. Always use explicit class references or `autoLoadEntities: true`.
