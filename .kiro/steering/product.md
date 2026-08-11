# Product Overview

## What This Is

An enterprise task platform that connects three types of users:

- **Workers** (Flutter Android app): People who perform micro-tasks and earn money
- **Buyers** (Flutter/Web app): Businesses that create and manage campaigns with tasks
- **Admins** (Dashboard): Platform moderators who review submissions and manage the system

## Core Business Flow

1. Buyers create orders (e.g., "1000 YouTube comments needed")
2. Backend breaks orders into individual tasks
3. Matching engine assigns tasks to eligible workers based on performance scores
4. Workers accept, complete, and submit tasks with proof
5. Reviews happen (buyer/admin/automatic modes)
6. Approved submissions trigger earnings
7. Workers withdraw money to their accounts

## Key Principles

- **Server is source of truth**: Never trust client-side calculations for money, rewards, or status
- **Transactional integrity**: All financial operations use database transactions
- **Idempotency**: Critical operations (payouts, withdrawals) are idempotent
- **Reward snapshots**: Lock rewards at task creation to prevent manipulation
- **Performance-based allocation**: Workers ranked by quality, completion rate, ratings, and reliability

## Platform Components

**Backend**: NestJS modular monolith with 13 specialized engines (Task, Matching, Scoring, Ranking, Allocation, Reward, Review, Earning, Payout, Progress, Eligibility, Fraud, Notification)

**Worker App**: Flutter Android app for task performers

**Buyer App**: Flutter/Web app for campaign creators

**Admin Dashboard**: Management interface for platform operations
