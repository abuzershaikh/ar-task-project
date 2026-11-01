# Bugfix Requirements Document

## Introduction

The Task Engine wallet balance system experiences race conditions and calculation bugs when multiple tasks complete simultaneously. This leads to lost wallet balance updates, duplicate earnings, incorrect order completion tracking, and worker statistics discrepancies. The bug affects the financial integrity of the platform, causing workers to receive incorrect payments and admin reports to show inaccurate data.

The core issue stems from READ-MODIFY-WRITE patterns in concurrent transaction scenarios without proper database-level isolation, resulting in lost updates when multiple earning transactions process simultaneously.

## Bug Analysis

### Current Behavior (Defect)

#### 1. Wallet Balance Race Condition

1.1 WHEN two tasks complete simultaneously for the same worker AND both transactions read the wallet balance at the same time THEN the system performs concurrent READ-MODIFY-WRITE operations where the second transaction overwrites the first, causing lost update of one earning amount

1.2 WHEN multiple earning posting transactions execute concurrently AND each reads the current `availableBalance` before incrementing THEN the system saves only the last transaction's calculated balance, discarding all previous increments

1.3 WHEN the `getTotalEarnings` SUM query executes AND a concurrent earning is being posted THEN the system may read stale balance data due to lack of read isolation, resulting in incorrect balance calculations

#### 2. Duplicate Earning Creation

1.4 WHEN two concurrent earning posting requests arrive for the same taskId within the same microsecond AND both check for existing earnings simultaneously THEN the system finds no existing record for both requests and creates duplicate earning entries

1.5 WHEN the duplicate earning check uses `findOne` with pessimistic lock AND both transactions execute before either commits THEN the system allows both transactions to proceed because neither can see the other's uncommitted earning record

#### 3. Order Completion Counter Race Condition

1.6 WHEN multiple tasks for the same order complete simultaneously AND each transaction reads `tasksCompleted` counter independently THEN the system increments from the same base value multiple times, causing lost counter increments

1.7 WHEN the `tasksCompleted` counter is incorrectly incremented due to race conditions AND the counter value is less than `totalTasksRequired` when it should equal it THEN the system fails to mark the order as COMPLETED when all tasks are actually done

1.8 WHEN the `tasksCompleted` counter is incorrectly incremented due to race conditions AND the counter value reaches `totalTasksRequired` prematurely THEN the system marks the order as COMPLETED before all tasks are actually finished

#### 4. Worker Statistics Race Condition

1.9 WHEN multiple tasks complete simultaneously for the same worker AND each transaction reads `totalEarnings` and `totalTasksCompleted` independently THEN the system performs concurrent increments that overwrite each other, resulting in incorrect worker statistics

1.10 WHEN worker statistics are updated without proper isolation AND the final saved values don't reflect all completed tasks THEN the system displays inaccurate worker performance metrics to both workers and administrators

#### 5. Available Balance Calculation Inconsistency

1.11 WHEN `getAvailableBalance` is called AND the wallet record exists but cache is stale THEN the system returns the potentially outdated `availableBalance` from the wallet table without recalculation

1.12 WHEN `getAvailableBalance` falls back to SUM query calculation AND multiple concurrent earning/withdrawal transactions are in progress THEN the system returns inconsistent balance values across simultaneous calls due to non-transactional aggregation queries

1.13 WHEN the fallback calculation uses `getTotalEarnings` and `getTotalWithdrawalsAmount` SUM queries AND these queries execute at different moments in time THEN the system may return a balance that never actually existed due to temporal inconsistency between the two queries

### Expected Behavior (Correct)

#### 1. Atomic Wallet Balance Updates

2.1 WHEN two tasks complete simultaneously for the same worker THEN the system SHALL serialize wallet balance updates using database-level atomic operations (e.g., `UPDATE wallet SET availableBalance = availableBalance + ? WHERE id = ?`) ensuring both earnings are correctly added to the final balance

2.2 WHEN multiple earning posting transactions execute concurrently for the same worker THEN the system SHALL use SQL increment operations or optimistic locking with retry logic to prevent lost updates, ensuring all earnings are accurately reflected in the wallet balance

2.3 WHEN reading wallet balance for calculation purposes THEN the system SHALL use appropriate transaction isolation level (READ COMMITTED or REPEATABLE READ) to prevent reading intermediate uncommitted states

#### 2. Duplicate Earning Prevention

2.4 WHEN two concurrent earning posting requests arrive for the same taskId THEN the system SHALL use a UNIQUE database constraint on `taskId` in the Earning table to prevent duplicate entries at the database level

2.5 WHEN an earning creation attempt violates the unique constraint on taskId THEN the system SHALL catch the duplicate key error and safely skip the duplicate earning creation without failing the entire transaction

2.6 WHEN checking for existing earnings before creation THEN the system SHALL use the database constraint as the primary prevention mechanism rather than relying solely on application-level checks with locks

#### 3. Order Completion Counter Integrity

2.7 WHEN multiple tasks for the same order complete simultaneously THEN the system SHALL use atomic SQL increment operations (`UPDATE orders SET tasksCompleted = tasksCompleted + 1 WHERE id = ?`) to ensure accurate counter updates

2.8 WHEN determining if an order is complete THEN the system SHALL compare the atomically incremented `tasksCompleted` value with `totalTasksRequired` within the same transaction to make accurate completion decisions

2.9 WHEN marking an order as COMPLETED THEN the system SHALL use conditional UPDATE with WHERE clause checking that `tasksCompleted >= totalTasksRequired` AND `status != 'COMPLETED'` to prevent duplicate completion processing

#### 4. Worker Statistics Accuracy

2.10 WHEN updating worker statistics for task completion THEN the system SHALL use atomic SQL increment operations for both `totalEarnings` and `totalTasksCompleted` to prevent lost updates in concurrent scenarios

2.11 WHEN worker statistics are updated THEN the system SHALL ensure the updates are part of the same transaction as the earning creation to maintain data consistency

#### 5. Consistent Balance Calculation

2.12 WHEN `getAvailableBalance` is called THEN the system SHALL always return the current wallet.availableBalance value from the wallet table as the single source of truth, avoiding fallback SUM query calculations that can produce inconsistent results

2.13 WHEN the wallet balance needs verification or recalculation THEN the system SHALL provide a separate administrative reconciliation function that performs the SUM query calculation within a READ COMMITTED transaction and flags discrepancies

2.14 WHEN wallet balance queries are performed THEN the system SHALL use the same transaction context to ensure all reads see a consistent snapshot of the database state

### Unchanged Behavior (Regression Prevention)

#### 1. Normal Earning Posting Flow

3.1 WHEN a single task completes without concurrent competition THEN the system SHALL CONTINUE TO post the earning, update wallet balance, increment counters, and update worker statistics as it currently does

3.2 WHEN an earning is successfully posted for a task THEN the system SHALL CONTINUE TO emit the appropriate events and notifications to the worker app

3.3 WHEN an earning fails validation checks (invalid amount, missing worker, etc.) THEN the system SHALL CONTINUE TO reject the earning and log appropriate error messages

#### 2. Transaction Rollback Behavior

3.4 WHEN any error occurs during earning posting within a transaction THEN the system SHALL CONTINUE TO rollback all changes (earning creation, wallet update, counter increments) atomically

3.5 WHEN a database constraint violation occurs (other than the new taskId unique constraint) THEN the system SHALL CONTINUE TO handle it with appropriate error logging and transaction rollback

#### 3. Existing Lock Behavior

3.6 WHEN finding a wallet record for update THEN the system SHALL CONTINUE TO use pessimistic write lock to prevent concurrent access to the same wallet row

3.7 WHEN finding an order record for update THEN the system SHALL CONTINUE TO use pessimistic write lock to serialize access to order records

#### 4. Earning Status Transitions

3.8 WHEN an earning is created THEN the system SHALL CONTINUE TO set its initial status to 'posted'

3.9 WHEN an earning needs to be reversed THEN the system SHALL CONTINUE TO support the reversal flow with status update to 'reversed'

#### 5. Balance Query for Display

3.10 WHEN the worker app requests the current wallet balance for display THEN the system SHALL CONTINUE TO return the balance value without requiring the user to refresh or wait

3.11 WHEN the admin dashboard queries worker balances THEN the system SHALL CONTINUE TO provide balance information in the same API response format

#### 6. Withdrawal Processing

3.12 WHEN a worker initiates a withdrawal AND the wallet has sufficient available balance THEN the system SHALL CONTINUE TO allow the withdrawal request to proceed

3.13 WHEN withdrawal amounts are calculated in balance verification THEN the system SHALL CONTINUE TO include withdrawals with status REQUESTED, UNDER_REVIEW, PROCESSING, and PAID in the total deducted amount

#### 7. Order Completion Events

3.14 WHEN an order's status changes to COMPLETED THEN the system SHALL CONTINUE TO trigger any existing order completion hooks, notifications, or downstream processes

3.15 WHEN checking if all tasks are completed for an order THEN the system SHALL CONTINUE TO compare `tasksCompleted` against `totalTasksRequired` as the completion criteria
