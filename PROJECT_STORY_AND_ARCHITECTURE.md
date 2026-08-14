# AR Task Project: Core Architecture & Story Guide

Welcome to the definitive guide for the **AR Task Project**. This document serves as the "brain map" and core intelligence manual for AI agents and developers. It explains the "Why", "What", and "How" of the entire ecosystem.

---

## 📖 1. The Story & Purpose (Vision)

**The Scenario:** In the modern digital economy, businesses (Buyers) need massive, decentralized human action—whether it's marketing promotion, data collection, or social media engagement. However, organizing hundreds of individuals (Workers) to execute specific micro-tasks reliably, verifying their work, and paying them securely is a logistical nightmare.

**The Purpose:** The AR Task Project bridges this gap. It acts as an intelligent, automated broker. 
- It allows **Buyers** to launch bulk campaigns seamlessly.
- It distributes these micro-tasks to thousands of vetted **Workers** who want to earn money.
- It uses a centralized, autonomous **Task Engine** (The Brain) to track, verify, and enforce quality without constant human intervention.
- The **Admin** oversees the economy, handles disputes, and manages payouts.

---

## 🧠 2. The App Brain Map (Server Intelligence)

The entire ecosystem is powered by a NestJS-based **Task Engine API**. It is the central authority that connects the three separate Flutter applications.

```text
=============================================================================
                          [ Task Engine API (NestJS) ]
                          The Central Intelligence Hub
=============================================================================
       ▲                               ▲                              ▲
       │                               │                              │
       v                               v                              v
┌──────────────┐               ┌───────────────┐              ┌──────────────┐
│  Buyer App   │<-- Campaign --│   Admin App   │-- Payouts -->│  Worker App  │
│(Marketing Pro│   Creation    │(EarnPost Admin│   Mgmt       │ (Task Reward)│
└──────────────┘               └───────────────┘              └──────────────┘
```

### The Internal "Engines" of the Server
To handle massive scale and prevent cheating, the server uses specialized sub-engines:
1. **Allocation Engine:** Distributes tasks in batches to avoid overwhelming the system.
2. **Matching Engine:** Finds the best workers for a specific task based on criteria.
3. **Scoring & Ranking Engine:** Evaluates workers. Good workers get tasks first; bad workers are penalized.
4. **Task Command Engine:** The strict State Machine. It prevents illegal state changes (e.g., you cannot approve an un-submitted task).
5. **Review Engine:** Manages approvals/rejections (by Buyer or Admin).
6. **Reward & Payout Engine:** Locks in task reward amounts, calculates earnings, and processes wallet withdrawals.

---

## 🏢 3. User Intentions & Flows

### A. The Buyer (Marketing Pro)
**Intention:** I want to get a specific job done by 500 people (e.g., share a post, download an app) as quickly and reliably as possible.
**How they use the app:**
1. **Wallet Top-up:** Adds funds to their Buyer Wallet.
2. **Campaign Creation:** Creates a new "Order" specifying the task type, instructions, required proof, total tasks needed, and reward per task.
3. **Reviewing Work:** As workers submit proofs, the Buyer reviews them. They can 'Approve', 'Reject', or 'Request Changes'.
4. **Analytics:** Tracks the completion progress of their order.

### B. The Worker (Task Reward)
**Intention:** I have free time and want to earn money by completing simple tasks.
**How they use the app:**
1. **Task Feed:** Browses available tasks pushed to them by the Matching Engine.
2. **Execution:** Accepts a task, follows the instructions, and uploads evidence (e.g., a screenshot).
3. **Earnings:** Waits for review. Upon approval, funds are instantly credited to their Worker Wallet.
4. **Withdrawal:** Requests a payout to their bank/crypto once the minimum threshold is met.

### C. The Admin (EarnPost Admin)
**Intention:** I want to ensure the platform runs smoothly, resolve conflicts, and process real-world money transfers.
**How they use the app:**
1. **Oversight:** Monitors active campaigns, user signups, and system health.
2. **Dispute Resolution:** If a Buyer unfairly rejects a task, the Admin can override the decision and approve it.
3. **Payout Processing:** Reviews worker withdrawal requests and marks them as `PAID` once the actual money transfer is executed.

---

## ⚙️ 4. Logic Deep Dive: What Happens When a Worker Fails?

The Task Engine is unforgiving. It uses strict logic to maintain quality.

```text
[ DRAFT ] --> [ ACTIVE ] --> [ ASSIGNED ] --> [ ACCEPTED ] --> [ IN_PROGRESS ]
                                  │                │                 │
                                  │                │                 │
                             (Time Limit)     (User Drops)      (Time Limit)
                                  │                │                 │
                                  v                v                 v
                               [ EXPIRED ]    [ CANCELLED ]     [ EXPIRED ]
                                      \            │               /
                                       \           │              /
                                        v          v             v
                                     [ SCORE PENALTY APPLIED ]
                                                 │
                                                 v
                                   [ TASK RETURNED TO POOL ]
```

**Scenario 1: Worker Ignores Task (Expiry)**
If a worker is assigned a task or starts it but misses the deadline:
1. The Task State Machine shifts the task to `EXPIRED`.
2. The `TaskReleaseListener` catches this event.
3. The worker receives a **Score Penalty** (their profile takes a hit, meaning they get fewer tasks in the future).
4. The task is recycled back to `ACTIVE` so another worker can pick it up.

**Scenario 2: Worker Drops Task Manually**
If a worker clicks "Cancel/Drop" after accepting:
1. The task goes to `CANCELLED` (for that specific assignment).
2. The worker's `totalTasksRejected` metric increments, damaging their trust score.
3. The matching engine immediately re-assigns the task to the next candidate.

**Scenario 3: Bad Quality Work**
If the worker submits bad proof:
1. The Buyer marks it as `REJECTED`.
2. The worker gets zero pay.
3. The Scoring Engine heavily drops their ranking. If the score falls below a threshold, the system might soft-ban them.

---

## 🎯 5. Core Application Features

### Admin App Features
- **Global Dashboard:** Metrics on total liquidity, active orders, and pending payouts.
- **User Management:** Ban/Suspend fraudulent workers or buyers.
- **Financial Control:** Process withdrawal requests and monitor escrow balances.
- **Override Capabilities:** Force-approve or force-reject tasks to settle disputes.

### Buyer App Features
- **Order Wizard:** Step-by-step campaign creator with targeting options.
- **Review Pipeline:** Swipe/click interface to rapidly approve/reject incoming worker proofs.
- **Wallet & Billing:** Add funds securely; view transaction history.
- **Order Progress:** Live tracking of completion rates.

### Worker App Features
- **Smart Task Feed:** Displays tasks the worker is actually eligible for (based on score/region).
- **Execution Environment:** Built-in timers and proof-upload utilities.
- **Wallet & Earnings:** Transparent view of pending, approved, and rejected earnings.
- **Profile & Trust Score:** A gamified score that motivates them to maintain high quality.

---

## 🚨 Guidelines for AI Agents (How to use this doc for Debugging)

If you are an AI reading this to fix a bug, remember these system rules:
1. **Never bypass the State Machine:** Do not use direct database updates (e.g., `update(status: 'assigned')`). Always use `TaskCommandService` (e.g., `assignTask()`).
2. **Handle Enumerations Carefully:** Statuses are Enums (e.g., `TaskStatus.IN_PROGRESS`), not random strings. Always use `taskRepo.matchesStatus()` when querying.
3. **Data Consistency is King:** In payout and review scenarios, ensure the Task Engine executes *first*, and only if it succeeds, update the local DB (e.g., Submission DB).
4. **Idempotency:** Payment endpoints and state transitions must be idempotent. A double-click should not grant double money.
