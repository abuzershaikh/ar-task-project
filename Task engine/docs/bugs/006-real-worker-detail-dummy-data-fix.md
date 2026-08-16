# Bug Report: Worker & Buyer Detail Tabs Displaying Hardcoded Dummy Data

## Issue Description
When opening a real worker's or buyer's detail view (`WorkerDetailScreen` or `BuyerDetailScreen`), all sub-tabs (Overview, Orders, Tasks, KYC, Earnings, Payments, Ratings, Quality Score, Risk, Activity, Analytics) were displaying hardcoded mock strings (e.g. `₹45,200`, `VERIFIED ✓`, `1,245 tasks`, `ABC Digital Pvt Ltd`, `₹2,40,000`) instead of rendering the actual worker's or buyer's real dynamic details from the backend/database.

## Root Cause Analysis
1. `WorkerDetailScreen` and `BuyerDetailScreen` received state objects containing real `WorkerModel`, `BuyerModel`, and list data (`orders`, `tasks`, `earnings`, `payments`, `ratings`, `activity`, `risk`).
2. However, the screens did not pass these state parameters into the sub-tab widgets. They were only passing `workerId` or `buyerId`.
3. The individual sub-tab widgets had static placeholder UI values hardcoded inside them.

## Solution & Dynamic Data Binding
1. Refactored all 8 Worker Detail tab widgets (`OverviewTab`, `TasksTab`, `KycTab`, `EarningsTab`, `RatingsTab`, `QualityScoreTab`, `RiskTab`, `ActivityTab`) to accept real parameters (`worker`, `tasks`, `earnings`, `ratings`, `scoreHistory`, `risk`, `activity`).
2. Refactored all 8 Buyer Detail tab widgets (`BuyerOverviewTab`, `BuyerOrdersTab`, `BuyerTasksTab`, `BuyerPaymentsTab`, `BuyerReviewsTab`, `BuyerAnalyticsTab`, `BuyerActivityTab`, `BuyerRiskTab`) to accept real dynamic parameters (`buyer`, `orders`, `tasks`, `payments`, `activity`).
3. Updated `WorkerDetailScreen` and `BuyerDetailScreen` to inject the real state objects directly into the sub-tabs.
4. Handled empty lists with clean user-friendly empty states instead of showing hardcoded mock entries.

## Affected Files
- `lib/features/workers/presentation/pages/worker_detail_screen.dart`
- `lib/features/workers/presentation/widgets/worker_detail_tabs/*.dart`
- `lib/features/buyers/presentation/pages/buyer_detail_screen.dart`
- `lib/features/buyers/presentation/widgets/buyer_detail_tabs/*.dart`
