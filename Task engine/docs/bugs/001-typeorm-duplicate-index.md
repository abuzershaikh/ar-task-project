# Bug: TypeORM Sync Crashing with "Duplicate key name"

## Issue Description
When deploying the application to production and triggering `TypeORM` synchronization, the backend crashed on startup. The error log displayed:
`QueryFailedError: Duplicate key name 'IDX_...'`
The application kept restarting and failing to connect to the database.

## Root Cause
TypeORM fails to synchronize when an entity defines a unique index both via the class-level `@Index` decorator and the property-level `@Column({ unique: true })` decorator simultaneously. 

Example of broken code:
```typescript
@Entity('users')
@Index(['email'], { unique: true }) // Duplicate index definition
export class User {
    @Column({ unique: true }) // First index definition
    email: string;
}
```
When both are present, TypeORM generates the exact same `CREATE UNIQUE INDEX` command twice within the same `CREATE TABLE` query. MySQL rejects this with a "Duplicate key name" error, causing the entire database sync to abort.

## Affected Files
- `shared/database/entities/user.entity.ts`
- `shared/database/entities/service-catalog.entity.ts`
- `shared/database/entities/task-generation-job.entity.ts`

## Solution
Removed the redundant class-level `@Index` decorators if a `@Column({ unique: true })` is already enforcing the unique constraint on the same column.

Example of fixed code:
```typescript
@Entity('users')
export class User {
    @Column({ unique: true }) 
    email: string;
}
```

## How to Prevent
When creating new entities, avoid defining `@Index` explicitly if you are already using `@Column({ unique: true })` unless you are creating a composite (multi-column) index.
