# Data Flow Architecture

## Database Access Pattern

```
API Controller
    ↓
Engine/Service
    ↓
Repository (TypeORM)
    ↓
MySQL Database
```

## Example: Scoring Engine se data read karna

```typescript
// scoring-engine/scoring.service.ts
import { WorkerScoreRepository } from '../shared/database/repositories/worker-score.repository';

@Injectable()
export class ScoringEngineService {
  constructor(
    private readonly scoreRepository: WorkerScoreRepository  // Direct Repository Inject
  ) {}

  async calculateWorkerScore(workerId: string) {
    // Direct MySQL se data read
    const existingScore = await this.scoreRepository.findByWorkerId(workerId);
    
    // Score calculate karo
    const newScore = this.calculate(workerId);
    
    // MySQL me save karo
    await this.scoreRepository.upsert(workerId, newScore);
    
    return newScore;
  }
}
```

## Example: Task Assignment Flow

```
1. Buyer API → Order create karta hai
   POST /api/buyer/orders
   
2. Order saved → MySQL orders table
   
3. Queue me task → Task Engine trigger
   
4. Task Engine → Tasks create karta hai
   - TaskRepository.create()
   - MySQL tasks table me save
   
5. Matching Engine → Workers find karta hai
   - WorkerRepository.findActiveWorkers()
   - MySQL se active workers read
   
6. Eligibility Engine → Check karta hai
   - TaskRepository, WorkerRepository se data read
   
7. Scoring Engine → Score calculate
   - WorkerScoreRepository se scores read
   
8. Allocation Engine → Task assign
   - TaskRepository.update() → MySQL update
```

## Repository Pattern Benefits

✅ **Direct Database Access** - No API overhead
✅ **Type Safety** - TypeORM entities
✅ **Transaction Support** - ACID guaranteed
✅ **Query Optimization** - Direct SQL queries
✅ **Bulk Operations** - Efficient batch processing

## Connection Pool

```typescript
// Database Config
poolSize: 10  // 10 connections pool
```

Multiple engines parallel me kaam kar sakti hain without blocking.

## Key Points

1. **No API calls between engines** - Sab directly MySQL se communicate
2. **Shared Repositories** - All engines use same repository layer
3. **TypeORM Entities** - Type-safe database operations
4. **Transaction Support** - Complex operations me consistency
5. **Connection Pooling** - Parallel processing efficient

## Migration Strategy

```bash
# Development
npm run migration:generate -- AddWorkerScores
npm run migration:run

# Production
npm run migration:run
```
