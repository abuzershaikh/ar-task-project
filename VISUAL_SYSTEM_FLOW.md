# AR Task Project - Visual System Flow Diagram

## 🎯 Complete System Architecture (Visual)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         AR TASK PROJECT ECOSYSTEM                        │
└─────────────────────────────────────────────────────────────────────────┘

┌───────────────────┐      ┌───────────────────┐      ┌───────────────────┐
│   ADMIN APP       │      │   BUYER APP       │      │   WORKER APP      │
│   (Flutter)       │      │   (Flutter)       │      │   (Flutter)       │
│                   │      │                   │      │                   │
│ • Service Mgmt    │      │ • Browse Services │      │ • View Tasks      │
│ • Pricing Setup   │      │ • Create Campaign │      │ • Accept/Submit   │
│ • Payout Approval │      │ • Make Payment    │      │ • Upload Proof    │
│ • Analytics       │      │ • Review Tasks    │      │ • Track Earnings  │
│ • Dispute Mgmt    │      │ • Track Progress  │      │ • Request Payout  │
└─────────┬─────────┘      └─────────┬─────────┘      └─────────┬─────────┘
          │                          │                          │
          │    HTTP REST APIs        │                          │
          │    (Port 3000)           │                          │
          └──────────────┬───────────┴──────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    TASK ENGINE (NestJS Backend)                          │
│                        Port 3000 - /api/v1/*                            │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                    API GATEWAY LAYER                            │    │
│  │  • Authentication & Authorization                               │    │
│  │  • Request Validation                                           │    │
│  │  • Response Formatting                                          │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌─────────────────────── CORE ENGINES ─────────────────────────┐      │
│  │                                                                │      │
│  │  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓  │      │
│  │  ┃         SERVICE CATALOG & PRICING ENGINE              ┃  │      │
│  │  ┃  • Service Definitions                                ┃  │      │
│  │  ┃  • Form Element Schemas                               ┃  │      │
│  │  ┃  • Price Calculation (Buyer + Margin + Worker)        ┃  │      │
│  │  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛  │      │
│  │                          ↓                                     │      │
│  │  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓  │      │
│  │  ┃              ORDER MANAGEMENT ENGINE                   ┃  │      │
│  │  ┃  • Order Creation (PAYMENT_PENDING)                    ┃  │      │
│  │  ┃  • Payment Gateway Integration                         ┃  │      │
│  │  ┃  • Pricing Snapshot Lock                               ┃  │      │
│  │  ┃  • Status: PAYMENT_PENDING → ACTIVE                    ┃  │      │
│  │  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛  │      │
│  │                          ↓                                     │      │
│  │  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓  │      │
│  │  ┃              TASK GENERATION ENGINE                    ┃  │      │
│  │  ┃  • Creates N Task Entities from Order                  ┃  │      │
│  │  ┃  • Inherits workerRewardSnapshot                       ┃  │      │
│  │  ┃  • Sets Accept & Complete Timers                       ┃  │      │
│  │  ┃  • Status: DRAFT → ACTIVE                              ┃  │      │
│  │  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛  │      │
│  │                          ↓                                     │      │
│  │  ┌────────────────────────────────────────────────────────┐  │      │
│  │  │        MATCHING ENGINE                                 │  │      │
│  │  │  • Find Eligible Workers                               │  │      │
│  │  │  • Filter by Location, Skills, History                 │  │      │
│  │  │  • Generate Candidate Pool                             │  │      │
│  │  └──────────────────────┬─────────────────────────────────┘  │      │
│  │                          ↓                                     │      │
│  │  ┌────────────────────────────────────────────────────────┐  │      │
│  │  │        SCORING ENGINE                                  │  │      │
│  │  │  • Calculate Trust Scores                              │  │      │
│  │  │  • Performance History Analysis                        │  │      │
│  │  │  • Penalty & Bonus Tracking                            │  │      │
│  │  └──────────────────────┬─────────────────────────────────┘  │      │
│  │                          ↓                                     │      │
│  │  ┌────────────────────────────────────────────────────────┐  │      │
│  │  │        ALLOCATION ENGINE                               │  │      │
│  │  │  • Rank Workers by Score                               │  │      │
│  │  │  • Assign Task to Top Worker                           │  │      │
│  │  │  • Status: ACTIVE → ASSIGNED                           │  │      │
│  │  └────────────────────────────────────────────────────────┘  │      │
│  │                                                                │      │
│  └────────────────────────────────────────────────────────────────      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                      WORKER TASK LIFECYCLE                               │
│                                                                          │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────────┐  │
│  │ ASSIGNED │ ──→ │ ACCEPTED │ ──→ │IN_PROGRESS│ ──→ │  SUBMITTED   │  │
│  └──────────┘     └──────────┘     └──────────┘     └──────────────┘  │
│       ↓                ↓                   ↓                  ↓          │
│   [Timer]        [Worker          [Worker          [Proof Upload]      │
│   [Starts]        Accepts]         Starts]          [Media/URL]        │
│                                                                          │
│  Timeout Handling:                                                       │
│  ├─ Accept Timeout → Status: EXPIRED → Task Released → Back to ACTIVE   │
│  └─ Complete Timeout → Status: EXPIRED → Score Penalty → Task Released  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                       REVIEW & APPROVAL ENGINE                           │
│                                                                          │
│  ┌──────────────┐                                                        │
│  │  SUBMITTED   │                                                        │
│  └──────┬───────┘                                                        │
│         │                                                                │
│         ├─────── Review Mode: BUYER ────→ Buyer App Review List         │
│         ├─────── Review Mode: ADMIN ────→ Admin App Review List         │
│         └─────── Review Mode: AUTO ─────→ Instant Approval              │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────┐       │
│  │                  REVIEWER DECISION                           │       │
│  │                                                              │       │
│  │  ✅ APPROVED                                                 │       │
│  │     └→ Task Status: APPROVED                                 │       │
│  │     └→ Earning Posted to Worker Wallet                       │       │
│  │     └→ Worker Score +10 points                               │       │
│  │                                                              │       │
│  │  ❌ REJECTED                                                 │       │
│  │     └→ Task Status: REJECTED                                 │       │
│  │     └→ Zero Payment                                          │       │
│  │     └→ Worker Score Penalty                                  │       │
│  │     └→ Task Capacity Freed                                   │       │
│  │                                                              │       │
│  │  🔄 CHANGES_REQUESTED                                        │       │
│  │     └→ Task Status: Back to IN_PROGRESS                      │       │
│  │     └→ Worker can Resubmit Proof                             │       │
│  │     └→ No Score Penalty                                      │       │
│  └─────────────────────────────────────────────────────────────┘       │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                    EARNING & WALLET ENGINE                               │
│                                                                          │
│  Worker Wallet Structure:                                                │
│  ┌─────────────────────────────────────────────────────────────┐       │
│  │  Total Approved Earnings:        ₹ 5,000.00                 │       │
│  │  Active Withdrawals (Locked):    ₹   500.00                 │       │
│  │  Paid Withdrawals:               ₹ 2,000.00                 │       │
│  │  ──────────────────────────────────────────                 │       │
│  │  AVAILABLE BALANCE:              ₹ 2,500.00                 │       │
│  └─────────────────────────────────────────────────────────────┘       │
│                                                                          │
│  Formula:                                                                │
│  Available Balance = Total Earnings - Active Withdrawals - Paid Amounts │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                       PAYOUT & WITHDRAWAL ENGINE                         │
│                                                                          │
│  ┌──────────────┐       ┌──────────────┐       ┌──────────────┐       │
│  │  REQUESTED   │  ───→ │  PROCESSING  │  ───→ │     PAID     │       │
│  └──────────────┘       └──────────────┘       └──────────────┘       │
│        │                       │                        │               │
│   [Worker          [Admin marks          [Admin inputs             │
│    Creates          processing           bank/UPI ref.             │
│    Request]         with bank]           Worker gets               │
│                                          confirmation]              │
│                                                                          │
│  Validation Checks:                                                      │
│  ✓ Balance >= minWithdrawalLimit (Set by Admin)                        │
│  ✓ Idempotency Key (Prevent Duplicates)                                │
│  ✓ Amount immediately locked from Available Balance                     │
│                                                                          │
│  If REJECTED:                                                            │
│  └→ Locked Amount REFUNDED back to Worker Wallet                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 State Machine Flow (Task Status Transitions)

```
                    ┌──────────────────────────────────┐
                    │    TASK STATE MACHINE            │
                    │    (Strictly Enforced)           │
                    └──────────────────────────────────┘

                              ┌─────────┐
                              │  DRAFT  │
                              └────┬────┘
                                   │ (Order Payment Complete)
                                   ↓
                              ┌─────────┐
                              │ ACTIVE  │ ←─────────────────┐
                              └────┬────┘                   │
                                   │                        │
                  (Allocation      │                        │
                   Engine)         ↓                        │
                              ┌──────────┐                  │
                              │ASSIGNED  │                  │
                              └────┬─────┘                  │
                                   │                        │
                  (Worker          │                        │
                   Accepts)        ↓                        │
                              ┌──────────┐                  │
                              │ACCEPTED  │                  │
                              └────┬─────┘                  │
                                   │                        │
                  (Worker          │                        │
                   Starts)         ↓                        │
                          ┌────────────────┐                │
                          │  IN_PROGRESS   │                │
                          └───┬────────┬───┘                │
                              │        │                    │
              (Submit Proof)  │        │ (Timeout)          │
                              ↓        ↓                    │
                      ┌───────────┐  ┌─────────┐           │
                      │SUBMITTED  │  │EXPIRED  │───────────┘
                      └─────┬─────┘  └─────────┘   (Task Released
                            │                       & Reassigned)
        (Review Mode)       │
                            ↓
                    ┌───────────────┐
                    │ UNDER_REVIEW  │
                    └───────┬───────┘
                            │
            ┌───────────────┼───────────────┐
            │               │               │
            ↓               ↓               ↓
      ┌──────────┐   ┌──────────┐   ┌─────────────────┐
      │APPROVED  │   │REJECTED  │   │CHANGES_REQUESTED│
      └────┬─────┘   └──────────┘   └────────┬────────┘
           │                                  │
   (Earning Posted)                   (Back to IN_PROGRESS
    to Worker Wallet)                  for Resubmission)
```

---

## 🔄 Data Flow Example (End-to-End Campaign)

### Scenario: Instagram Follow Campaign

```
STEP 1: Admin Creates Service
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Admin App → POST /api/v1/admin/services
{
  "code": "INSTAGRAM_FOLLOW",
  "name": "Instagram Follow",
  "buyerUnitPrice": 10.00,
  "platformMargin": 4.00 (FIXED),
  "workerReward": 6.00,
  "reviewMode": "buyer"
}

STEP 2: Buyer Creates Campaign
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Buyer App → POST /api/v1/buyer/orders
{
  "serviceCode": "INSTAGRAM_FOLLOW",
  "quantity": 100,
  "targetUrl": "@mybrand"
}

Response:
{
  "orderId": "ORD-12345",
  "status": "PAYMENT_PENDING",
  "totalAmount": 1000.00,
  "buyerUnitPrice": 10.00,
  "workerRewardSnapshot": 6.00,
  "platformMarginSnapshot": 4.00
}

STEP 3: Payment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Buyer App → POST /api/v1/buyer/orders/ORD-12345/payment
Razorpay Gateway → Payment Success → Webhook
Order Status: PAYMENT_PENDING → ACTIVE

STEP 4: Task Generation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Task Engine → Creates 100 Tasks
Each Task:
- status: DRAFT → ACTIVE
- workerRewardSnapshot: ₹6.00
- timeToAcceptHours: 24
- timeToCompleteHours: 48

STEP 5: Task Allocation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Matching Engine → Finds 50 eligible workers
Scoring Engine → Ranks by trust score
Allocation Engine → Assigns Task-001 to Worker-A (Score: 95)

Task-001 Status: ACTIVE → ASSIGNED
Worker-A sees notification in Worker App

STEP 6: Worker Execution
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Worker App (Worker-A):
1. Clicks "Accept Task" → Status: ACCEPTED (Timer: 48h starts)
2. Opens Instagram → Follows @mybrand
3. Takes Screenshot
4. Clicks "Submit" → Uploads screenshot
   Status: ACCEPTED → SUBMITTED → UNDER_REVIEW

STEP 7: Review
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Buyer App → Reviews submission
Buyer sees screenshot of Instagram follow
Buyer clicks "APPROVE"

Task Status: UNDER_REVIEW → APPROVED

STEP 8: Earning Posted
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Earning Engine → Creates Earning record
{
  "workerId": "Worker-A",
  "taskId": "Task-001",
  "amount": 6.00,
  "status": "APPROVED"
}

Worker-A Wallet:
Total Earnings: +₹6.00
Available Balance: ₹6.00

Worker-A Trust Score: +10 points

STEP 9: Withdrawal
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(After Worker-A completes 50 more tasks)
Worker-A Wallet:
Total Earnings: ₹306.00
Available Balance: ₹306.00

Worker App → POST /api/v1/worker/earnings/withdraw
{
  "amount": 300.00,
  "upiId": "worker@upi"
}

Withdrawal Status: REQUESTED
Available Balance: ₹6.00 (₹300 locked)

STEP 10: Admin Payout
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Admin App → Reviews withdrawal request
Admin marks: REQUESTED → PROCESSING → PAID
Admin adds bank reference: "TXN-ABC123"

Worker receives ₹300.00 in bank account
Withdrawal Status: PAID
Worker Available Balance: ₹6.00
```

---

## 🎯 Technology Stack Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    MOBILE APPS LAYER                         │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Admin App   │  │  Buyer App   │  │  Worker App  │     │
│  │              │  │              │  │              │     │
│  │  Flutter     │  │  Flutter     │  │  Flutter     │     │
│  │  Dart        │  │  Dart        │  │  Dart        │     │
│  │  Riverpod    │  │  Riverpod    │  │  Provider    │     │
│  │  Dio (HTTP)  │  │  Dio (HTTP)  │  │  Dio (HTTP)  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                          ↓ REST API
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND API LAYER                         │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │           NestJS (TypeScript/Node.js)              │    │
│  │                                                     │    │
│  │  • Controllers (REST endpoints)                    │    │
│  │  • Services (Business logic)                       │    │
│  │  • Engines (Specialized microservices)             │    │
│  │  • TypeORM (Database ORM)                          │    │
│  │  • JWT Authentication                              │    │
│  │  • Validation Pipes                                │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                          ↓ SQL
┌─────────────────────────────────────────────────────────────┐
│                    DATABASE LAYER                            │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │                   MySQL                             │    │
│  │                                                     │    │
│  │  Tables:                                            │    │
│  │  • users (Admin/Buyer/Worker)                      │    │
│  │  • services (Service catalog)                      │    │
│  │  • orders (Campaign orders)                        │    │
│  │  • tasks (Individual tasks)                        │    │
│  │  • task_submissions (Worker proofs)                │    │
│  │  • earnings (Worker earnings)                      │    │
│  │  • withdrawals (Payout requests)                   │    │
│  │  • worker_scores (Trust scores)                    │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

**یہ visual guide آپ کو پوری system کی flow اور architecture کو clearly سمجھنے میں مدد کرے گی!**

**यह विज़ुअल गाइड आपको पूरे सिस्टम की फ्लो और आर्किटेक्चर को स्पष्ट रूप से समझने में मदद करेगी!**
