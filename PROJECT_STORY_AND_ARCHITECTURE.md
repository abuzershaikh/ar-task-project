# AR Task Project: Comprehensive System Blueprint, Story & Architecture Guide

Welcome to the definitive architecture, business flow, and technical reference guide for the **AR Task Project**. This document serves as the complete "Brain Map" and intelligence manual for developers, system architects, and AI agents. It describes every flow—from service creation by Admin to order purchasing by Buyer, task allocation, worker execution, review, earning posting, and payout execution.

---

## 📖 1. System Vision & End-to-End Story Scenario

### The Problem
Modern digital campaigns, marketing promotions, app testing, and social media tasks require decentralized human action at scale. Manually hiring, assigning tasks, tracking progress, verifying proof, and handling micro-payouts for thousands of workers is inefficient, prone to fraud, and impossible to scale.

### The Solution: AR Task Project
The AR Task Project is an automated micro-task marketplace operating via **three dedicated Flutter client apps** powered by a single, central **NestJS Task Engine API (port 3000, `/api/v1`)**.

```text
+-----------------------------------------------------------------------------------+
|                                 ADMIN APP                                         |
|  1. Defines Service Catalog (e.g. Instagram Follow, App Download)                 |
|  2. Sets Buyer Unit Price & Platform Margin (Fixed or Percentage)                 |
|  3. Controls Worker Minimum Withdrawal Threshold & Approves Payouts               |
+-----------------------------------------------------------------------------------+
                                          │
                                          ▼
+-----------------------------------------------------------------------------------+
|                                 BUYER APP                                         |
|  1. Browses Service Catalog & requests Price Estimates                            |
|  2. Creates Campaign Order (Enters PAYMENT_PENDING state)                        |
|  3. Completes Online Gateway Payment (Razorpay/Mock)                              |
|  4. System locks Pricing Snapshot & generates Batch Tasks                         |
+-----------------------------------------------------------------------------------+
                                          │
                                          ▼
+-----------------------------------------------------------------------------------+
|                             CENTRAL TASK ENGINE API                               |
|  1. Batch Engine -> Places tasks in matching queue                                |
|  2. Matching & Scoring Engine -> Ranks Workers by Trust Score                     |
|  3. Allocation Engine -> Assigns tasks to top eligible Workers                    |
+-----------------------------------------------------------------------------------+
                                          │
                                          ▼
+-----------------------------------------------------------------------------------+
|                                WORKER APP                                         |
|  1. Sees Available / Assigned Tasks on Feed                                       |
|  2. Accepts Task & Starts Work (Enforces Accept & Completion Timers)              |
|  3. Submits Work Data & Proof Media (Screenshots/URLs)                            |
+-----------------------------------------------------------------------------------+
                                          │
                                          ▼
+-----------------------------------------------------------------------------------+
|                         REVIEW & EARNING SETTLEMENT                               |
|  1. Review Engine routes submission (Buyer Review / Admin / Auto)                  |
|  2. Statuses: APPROVED -> Earnings posted to Worker Wallet                       |
|                 REJECTED -> Zero pay, Worker score penalty                        |
|                 CHANGES_REQUESTED -> Re-routed to Worker for resubmission          |
|  3. Worker requests Withdrawal -> Admin approves & marks PAID                     |
+-----------------------------------------------------------------------------------+
```

---

## 🧠 2. Server Architecture & Engine Intelligence Map

The central NestJS backend is composed of decoupled micro-engines, ensuring strict transaction isolation, state machine protection, and high-concurrency scaling.

```text
========================================================================================
                          TASK ENGINE API ARCHITECTURE (:3000/api/v1)
========================================================================================

    [ Admin Controllers ]        [ Buyer Controllers ]        [ Worker Controllers ]
             │                            │                            │
             ▼                            ▼                            ▼
+──────────────────────────────────────────────────────────────────────────────────────+
|                                SERVICE CATALOG ENGINE                                |
|  - Manages Service Definitions, Elements (Form schemas), & Pricing Versions         |
+──────────────────────────────────────────────────────────────────────────────────────+
                                          │
                                          ▼
+──────────────────────────────────────────────────────────────────────────────────────+
|                                   PRICING ENGINE                                     |
|  - Calculates Buyer Unit Price, Margin Amount, & Worker Reward Snapshot               |
+──────────────────────────────────────────────────────────────────────────────────────+
                                          │
                                          ▼
+──────────────────────────────────────────────────────────────────────────────────────+
|                                 TASK COMMAND ENGINE                                  |
|  - Central Authority: Validates all Task State Machine transitions                   |
+──────────────────────────────────────────────────────────────────────────────────────+
        │                      │                       │                       │
        ▼                      ▼                       ▼                       ▼
┌──────────────┐       ┌──────────────┐        ┌──────────────┐        ┌──────────────┐
│  ALLOCATION  │       │   MATCHING   │        │   SCORING    │        │   PROGRESS   │
│   ENGINE     │       │   ENGINE     │        │  & RANKING   │        │    ENGINE    │
│ Batch & Auto │       │ Candidate    │        │ Calculates   │        │ Order & Task │
│ Assignment   │       │ Selection    │        │ Worker Scores│        │ Timeline     │
└──────────────┘       └──────────────┘        └──────────────┘        └──────────────┘
        │                      │                       │                       │
        └──────────────────────┼───────────────────────┴───────────────────────┘
                               │
                               ▼
+──────────────────────────────────────────────────────────────────────────────────────+
|                             REVIEW ENGINE & EARNINGS                                 |
|  - Handles Buyer/Admin Decisions, Earning Calculations, & Wallet Postings            |
+──────────────────────────────────────────────────────────────────────────────────────+
                                          │
                                          ▼
+──────────────────────────────────────────────────────────────────────────────────────+
|                                   PAYOUT ENGINE                                      |
|  - Manages Worker Minimum Thresholds, Idempotent Withdrawals & Admin Payout Clearing|
+──────────────────────────────────────────────────────────────────────────────────────+
```

---

## 🛠️ 3. Admin Service Catalog & Pricing Engine Blueprint

### A. How Admin Defines Services
Admin creates standardized task definitions in the **Service Catalog** (`/api/v1/admin/services`).
Each service consists of:
1. **Service Code & Name:** (e.g., `INSTAGRAM_FOLLOW`, `APP_TEST_REVIEW`).
2. **Description & Form Elements:** Requirements schema (text fields, screenshot upload requirements, target URLs).
3. **Review Mode:** Standard review mode for tasks created under this service:
   - `buyer`: The campaign owner reviews submissions.
   - `admin`: Platform admins review submissions.
   - `automatic`: Auto-approved upon proof upload.

### B. Pricing & Margin Calculation Engine
The system uses automated pricing versions to ensure platform profitability. When Admin sets pricing for a service:

$$\text{Total Buyer Unit Price} = \text{Worker Reward} + \text{Platform Margin}$$

Admin can configure two types of margins:
1. **FIXED Margin:** A flat dollar/rupee amount added on top of the worker reward.
2. **PERCENTAGE Margin:** A percentage of the buyer unit price retained by the platform.

```text
Example Calculation (FIXED Margin):
  Buyer Unit Price per Task:  ₹10.00
  Platform Margin Value:      ₹4.00 (Fixed)
  -----------------------------------------
  Worker Reward Snapshot:     ₹6.00 per completed task
  
  For an order of 100 Tasks:
  Total Buyer Payable:        ₹1,000.00
  Platform Escrow Hold:       ₹1,000.00 (₹600 allocated for Workers, ₹400 Platform Revenue)
```

---

## 💳 4. Buyer Order & Campaign Lifecycle

### Step 1: Price Estimate & Order Draft
1. Buyer selects a service from the catalog and specifies the required quantity (e.g., 500 tasks).
2. The Buyer App calls `/api/v1/buyer/orders/price-estimate` to fetch a live calculation.
3. Buyer submits `/api/v1/buyer/orders` to create the campaign.
4. The system creates the Order with status `PAYMENT_PENDING` and locks a **Pricing Snapshot** (`buyerUnitPrice`, `workerRewardSnapshot`, `platformMarginSnapshot`, `pricingVersion`, `totalAmount`).

### Step 2: Payment Gateway & Task Generation
```text
  [ Buyer ]
      │
      ├─► Post /api/v1/buyer/orders/:id/payment ──► Session Initiated (Razorpay/Gateway)
      │
      ├─► Complete Payment ──► Payment Webhook / Callback Triggered
      │
      └─► Order Status updated from 'PAYMENT_PENDING' -> 'ACTIVE'
              │
              ▼
      [ Task Engine Batch Generation ]
              │
              ├─► Generates N individual Task Entities linked to Order ID
              └─► Each Task inherits workerRewardSnapshot & timing limits
```

---

## 🔄 5. Task Engine State Machine & Worker Lifecycle

The **Task Command Engine** enforces a strict state machine. No task can skip states or undergo unauthorized state mutations.

```text
                      ┌───────────────────────────────────────────────┐
                      │              TASK STATE MACHINE               │
                      └───────────────────────────────────────────────┘

                                      ┌──────────┐
                                      │  DRAFT   │
                                      └────┬─────┘
                                           │ (Order Paid)
                                           ▼
                                      ┌──────────┐
                                      │  ACTIVE  │
                                      └────┬─────┘
                                           │ (Assigned by Allocation Engine)
                                           ▼
                                      ┌──────────┐
                                      │ ASSIGNED │
                                      └────┬─────┘
                                           │ (Worker Accepts)
                                           ▼
                                      ┌──────────┐
                                      │ ACCEPTED │
                                      └────┬─────┘
                                           │ (Worker Starts Work)
                                           ▼
                                  ┌─────────────────┐
                                  │   IN_PROGRESS   │
                                  └───┬─────────┬───┘
                                      │         │
                   (Worker Submits)   │         │ (Accept/Complete Time Exceeded)
                                      ▼         ▼
                              ┌───────────┐ ┌───────────┐
                              │ SUBMITTED │ │  EXPIRED  │
                              └─────┬─────┘ └─────┬─────┘
                                    │             │
              (Routed to Reviewer)  ▼             │ (Score Penalty & Recycled to ACTIVE)
                            ┌──────────────┐      │
                            │ UNDER_REVIEW │      │
                            └──────┬───────┘      │
                                   │              │
      ┌────────────────────────────┼──────────────┴────────────────────────────┐
      │                            │                                           │
      ▼                            ▼                                           ▼
┌──────────┐                 ┌──────────┐                             ┌───────────────────┐
│ APPROVED │                 │ REJECTED │                             │ CHANGES_REQUESTED │
└────┬─────┘                 └──────────┘                             └─────────┬─────────┘
     │                                                                          │
     ▼                                                                          ▼
 (Earnings Posted                                                       (Task returns to
  to Worker Wallet)                                                      IN_PROGRESS for
                                                                         proof resubmission)
```

---

## 🚨 6. Worker Execution, Timeouts, Drops & Penalty Logic

### A. Strict Timers
Every task has two configurable timing constraints inherited from the Order/Service definition:
- `timeToAcceptHours`: Maximum time allowed for a worker to accept an assigned task (default: 24h).
- `timeToCompleteHours`: Maximum time allowed for a worker to complete and submit work after starting (default: 48h).

### B. What Happens When a Worker Fails or Drops a Task?

#### Scenario 1: Worker Misses Accept/Completion Deadline
1. The background cron/service detects the timeout.
2. The state machine transitions the task status to `EXPIRED`.
3. The `TaskReleaseListener` fires automatically:
   - Increments worker's penalty count (`totalTasksRejected` / `tasksExpired`).
   - Decreases worker's **Trust Score** in `ScoringEngine`.
4. **Task Recycling:** The task drops its `assignedTo` association and resets to `ACTIVE`, making it immediately available for another eligible worker to claim.

#### Scenario 2: Worker Manually Cancels / Drops Task
1. Worker clicks "Drop Task" in Worker App.
2. Task state transitions to `CANCELLED` for that specific assignment.
3. Worker score is penalized for dropping active work.
4. The task is reset back to `ACTIVE` and sent back into the Matching Engine pool.

#### Scenario 3: Submission Rejected by Buyer/Admin
1. Reviewer sets status to `REJECTED` with reason notes.
2. Worker gets ₹0 reward.
3. Worker score is penalised.
4. The task capacity spot for the Order is freed so a new task can be completed to fulfill the Buyer's required quantity.

---

## 💰 7. Review Engine, Earning Settlement & Wallet Flow

### A. Review Decision Routing
When a worker submits proof via `/api/v1/worker/tasks/:id/submit`, a `TaskSubmission` entity is created.
The **Review Engine** routes the review based on the Order's `reviewMode`:
- **BUYER Review:** Shows up in Buyer App review list (`/api/v1/buyer/reviews`). Buyer can Approve, Reject, or Request Changes.
- **ADMIN Review:** Shows up in Admin App review list (`/api/v1/admin/reviews`). Admin can Approve or Reject.
- **AUTOMATIC Review:** Instantly approves submission upon proof receipt.

### B. Approval & Earning Ledger Posting
```text
  Reviewer Action: APPROVED
             │
             ▼
  TaskEngine.approveTask() ──► Updates Task Status to APPROVED
             │
             ▼
  EarningEngine.calculateEarning()
  (Uses workerRewardSnapshot locked at task creation)
             │
             ▼
  EarningRepository.create() ──► Inserts Earning record into DB
             │
             ▼
  Worker Available Balance Incremented
  Available Balance = Total Approved Earnings - Total Active/Paid Withdrawals
```

### C. Request Changes Flow
If proof is insufficient but fixable:
1. Buyer selects `CHANGES_REQUESTED` with explanatory notes.
2. Task Engine moves status back to `IN_PROGRESS`.
3. Worker receives push notification and can resubmit updated proof via `/api/v1/worker/tasks/:id/resubmit`.

---

## 🏦 8. Payout Engine & Financial Withdrawal Flow

Worker earnings accumulation and withdrawal process:

```text
[ Worker App ]
   │
   ├─► Views Wallet Balance (/api/v1/worker/earnings/wallet)
   │   Checks: Available Balance >= Global minWithdrawalLimit (Configured by Admin)
   │
   ├─► Requests Withdrawal (/api/v1/worker/earnings/withdraw)
   │   - Enforces Idempotency Key
   │   - Validates balance & minimum limit
   │   - Creates Withdrawal Entity with status 'REQUESTED'
   │
   └─► Balance is immediately locked (Deducted from Available Balance)
```

### Admin Payout Clearing Pipeline
In the Admin App (`/api/v1/admin/payouts`):

```text
 ┌────────────────┐       ┌─────────────────┐       ┌────────────────┐
 │   REQUESTED    │ ───►  │   PROCESSING    │ ───►  │      PAID      │
 └────────────────┘       └─────────────────┘       └────────────────┘
   Initial Worker           Admin marks when          Admin inputs bank/UPI
   request created          processing with bank      transaction ref.
                                                      Worker receives confirmation.
                                  │
                                  │ (If Fraud or Incorrect Details)
                                  ▼
                          ┌─────────────────┐
                          │    REJECTED     │
                          └─────────────────┘
                            Withdrawal rejected.
                            Locked funds REFUNDED
                            back to Worker Wallet.
```

---

## 📱 9. Role-by-Role Feature Matrix

| Feature Module | EarnPost Admin App | Marketing Pro Buyer App | Task Reward Worker App |
| :--- | :--- | :--- | :--- |
| **Authentication & Profile** | Admin Auth, System Roles | Buyer Auth, Company Profile | Worker Auth, KYC Verification |
| **Service Catalog** | Create/Update Services & Pricing Margins | Browse Active Services & Form Schemas | N/A (Sees assigned/available tasks) |
| **Campaign & Orders** | Monitor All Platform Orders | Create Campaign, Price Preview, Gateway Pay | N/A |
| **Task Management** | Force-Approve / Force-Reject Tasks | View Order Progress, Task Timelines | Accept, Start, Submit Proof, Resubmit |
| **Reviews & Quality** | Dispute Resolution, Audit Logs | Review Worker Proofs (Approve/Reject/Fix) | View Rejection Reasons & Feedback |
| **Wallet & Finance** | Configure Min Threshold, Approve Payouts | Add Funds, View Invoices & In-flight Spend | Track Earnings, Request Withdrawals |
| **Analytics & Engine** | Global Platform Metrics, Engine Config | Order Completion & Performance Analytics | Score Card, Level, Trust Score Metrics |

---

## 🚨 10. Developer & AI Agent Rules for Debugging & Maintenance

When modifying or debugging this repository, **all AI Agents and Developers MUST strictly observe the following rules**:

1. **State Machine Authority:** NEVER bypass `TaskCommandService` or write direct raw SQL updates on task status fields. Always use the command service methods (`assignTask`, `acceptTask`, `startTask`, `submitTask`, `approveTask`, `rejectTask`, `requestChangesTask`).
2. **Status Aliases:** Task statuses use Enums. Always use `taskRepo.matchesStatus(actual, expected)` or `taskRepo.filterByStatus(tasks, expected)` rather than literal string comparisons like `status === 'pending'`.
3. **Execution Sequence in Reviews:** In `ReviewDecisionService`, ALWAYS call `TaskEngineService` to transition task status **BEFORE** updating the submission entity in the database.
4. **Idempotency & Lock Integrity:** Financial actions (Order Payment, Withdrawal Requests, Earning Postings) must validate idempotency keys to prevent duplicate payout transactions.
5. **No Loss of Reward Snapshots:** Never recalculate worker rewards using current service catalog prices for existing tasks. Always read from `task.metadata.rewardSnapshot` or `order.workerRewardSnapshot`.
