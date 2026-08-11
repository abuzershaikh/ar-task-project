# Buyer App - Implementation Roadmap

## 🎯 Current Status

### ✅ Foundation Complete
- Clean Architecture setup
- Core infrastructure (DI, network, storage, theme)
- Authentication flow
- Basic navigation structure
- Initial pages and widgets
- Documentation

### 🆕 New Structure Defined
- 5-tab bottom navigation (Home, Campaigns, Reviews, Analytics, More)
- Wallet/Prepaid Balance system with Available/Reserved split
- Dedicated Campaign Detail screen with tabs
- Step-by-step Campaign Creation wizard
- Enhanced Home Dashboard
- Worker Rating system

---

## 📋 Phase 1: Core Features (Priority 1)

### 1.1 Wallet Module 💰 (NEW - HIGHEST PRIORITY)

**Entities Created:** ✅
- `WalletBalance` entity with Available/Reserved split
- `Transaction` entity with types (credit, debit, reserved, captured, released)

**Need to Create:**
- [ ] Wallet Repository (interface + implementation)
- [ ] Wallet Use Cases:
  - [ ] `GetWalletBalanceUseCase`
  - [ ] `GetTransactionsUseCase`
  - [ ] `AddBalanceUseCase`
  - [ ] `VerifyBalancePaymentUseCase`
- [ ] Wallet BLoC with states and events
- [ ] Wallet Screens:
  - [ ] `WalletScreen` (balance + transaction list)
  - [ ] `AddBalanceScreen` (quick amounts + custom)
  - [ ] `TransactionDetailScreen`
- [ ] Wallet Widgets:
  - [ ] `BalanceCard` (Available/Reserved display)
  - [ ] `TransactionListItem`
  - [ ] `QuickAmountButton`

**API Integration:**
- [ ] GET `/buyer/wallet/balance`
- [ ] GET `/buyer/wallet/transactions`
- [ ] POST `/buyer/wallet/add-balance`
- [ ] POST `/buyer/wallet/verify-payment`

**Financial Flow:**
```
Campaign Create → Check Balance → Reserve Amount
                                    ↓
                          Available Balance ↓
                          Reserved Balance ↑
                                    ↓
Campaign Complete → Capture (backend handles)
                                    ↓
Campaign Cancel → Release Amount
                                    ↓
                          Available Balance ↑
                          Reserved Balance ↓
```

---

### 1.2 Enhanced Home Dashboard 🏠

**Current Status:** Basic structure exists
**Needs Enhancement:**

- [ ] Add `BalanceCard` widget at top
- [ ] Update `DashboardBloc` to fetch wallet balance
- [ ] Add "Action Required" card for pending reviews
- [ ] Show top 3 active campaigns only
- [ ] Update quick actions with wallet navigation
- [ ] Integrate real-time data from backend

**Screens:**
- [ ] Update `HomePage` with new layout
- [ ] Add pull-to-refresh for all data

**Widgets to Create:**
- [ ] `WalletBalanceCard` (compact version for home)
- [ ] `ActionRequiredCard` (dynamic based on pending reviews)
- [ ] `CampaignProgressCard` (mini version)
- [ ] `SpendingCard` (total + this month)

---

### 1.3 Campaign Detail Screen 📋 (NEW)

**Entity Created:** ✅
- `CampaignDetail` with comprehensive info
- `DeadlineExtension` for tracking extensions

**Need to Create:**
- [ ] Campaign Detail Repository methods
- [ ] Campaign Detail Use Cases:
  - [ ] `GetCampaignDetailUseCase`
  - [ ] `GetCampaignTasksUseCase`
  - [ ] `GetCampaignReviewsUseCase`
  - [ ] `GetCampaignActivityUseCase`
  - [ ] `GetCampaignAnalyticsUseCase`
  - [ ] `PauseCampaignUseCase`
  - [ ] `ResumeCampaignUseCase`
  - [ ] `CancelCampaignUseCase`
- [ ] Campaign Detail BLoC
- [ ] Campaign Detail Screen with 5 tabs:
  - [ ] `OverviewTab` - Progress, status, deadline
  - [ ] `TasksTab` - Task list with filters
  - [ ] `ReviewsTab` - Pending submissions
  - [ ] `ActivityTab` - Timeline of events
  - [ ] `AnalyticsTab` - Campaign-specific metrics

**Widgets:**
- [ ] `CampaignDetailHeader`
- [ ] `CampaignProgressSection`
- [ ] `CampaignInfoCard`
- [ ] `DeadlineStatusCard` (with extensions)
- [ ] `TaskListItem`
- [ ] `ActivityTimelineItem`
- [ ] `CampaignMetricsCard`

**API Integration:**
- [ ] GET `/buyer/orders/:id` (full detail)
- [ ] GET `/buyer/orders/:id/overview`
- [ ] GET `/buyer/orders/:id/tasks`
- [ ] GET `/buyer/orders/:id/reviews`
- [ ] GET `/buyer/orders/:id/activity`
- [ ] GET `/buyer/orders/:id/analytics`
- [ ] PATCH `/buyer/orders/:id/pause`
- [ ] PATCH `/buyer/orders/:id/resume`
- [ ] DELETE `/buyer/orders/:id/cancel`

---

### 1.4 Step-by-Step Campaign Creation Wizard ➕

**Current Status:** Basic create campaign page exists
**Needs Complete Rewrite:**

- [ ] Create Campaign Wizard BLoC (manages 6 steps)
- [ ] Step 1: `ChooseServiceScreen`
- [ ] Step 2: `CampaignDetailsScreen`
- [ ] Step 3: `ProofRequirementsScreen`
- [ ] Step 4: `TimingScreen`
- [ ] Step 5: `ReviewRulesScreen`
- [ ] Step 6: `SummaryPaymentScreen`
- [ ] `CampaignSuccessScreen`

**Wizard State:**
```dart
class CampaignWizardState {
  final CampaignCreationStep currentStep;
  final ServiceModel? selectedService;
  final String? campaignName;
  final int? quantity;
  final String? instructions;
  final List<ProofType> proofRequirements;
  final int? acceptWithinHours;
  final int? completeWithinHours;
  final DateTime? deadline;
  final ReviewMode? reviewMode;
  final double? estimatedCost;
  final WalletBalance? walletBalance;
  final bool hasSufficientBalance;
}
```

**Key Features:**
- [ ] Progress indicator (Step X/6)
- [ ] Back/Continue navigation
- [ ] Form validation per step
- [ ] Balance check at final step
- [ ] "Add Balance" if insufficient
- [ ] Server-side price calculation
- [ ] Success confirmation screen

**API Integration:**
- [ ] GET `/buyer/services` (Step 1)
- [ ] GET `/buyer/services/:id` (service details)
- [ ] GET `/buyer/wallet/balance` (Step 6 - balance check)
- [ ] POST `/buyer/orders` (create campaign)

---

### 1.5 Review & Rating System ⭐

**Current Status:** Basic structure exists
**Needs Implementation:**

- [ ] Update Review BLoC with rating events
- [ ] Create `ReviewDetailScreen` with proof display
- [ ] Create `RateWorkerScreen` (multiple ratings + comment)
- [ ] Image/video proof viewer
- [ ] Approve/Reject/Request Changes actions

**Screens:**
- [ ] Update `ReviewsScreen` with tabs (Pending, Approved, Rejected)
- [ ] Create `ReviewDetailScreen`
- [ ] Create `RateWorkerScreen`

**Widgets:**
- [ ] `SubmissionProofViewer` (images, videos, links)
- [ ] `RatingStars` (interactive 1-5 stars)
- [ ] `ReviewActionButtons`
- [ ] `WorkerRatingCard`

**API Integration:**
- [ ] GET `/buyer/submissions` (with filters)
- [ ] GET `/buyer/submissions/:id` (detail with proof)
- [ ] POST `/buyer/submissions/:id/approve`
- [ ] POST `/buyer/submissions/:id/reject`
- [ ] POST `/buyer/submissions/:id/request-changes`
- [ ] POST `/buyer/submissions/:id/rate` (worker rating)

---

## 📋 Phase 2: Advanced Features (Priority 2)

### 2.1 Analytics Dashboard 📊

- [ ] Analytics BLoC
- [ ] Overall analytics screen
- [ ] Campaign-specific analytics
- [ ] Charts integration (fl_chart, syncfusion)
- [ ] Date range filters
- [ ] Export reports (PDF, CSV)

**Metrics:**
- Completion rates
- Approval/rejection rates
- Average review time
- Tasks per hour
- Spending trends
- Campaign comparison

---

### 2.2 Payments & Invoices 💳

- [ ] Payment history screen
- [ ] Payment detail screen
- [ ] Invoice list screen
- [ ] Invoice detail screen
- [ ] PDF generation and download
- [ ] Invoice sharing

---

### 2.3 Notifications 🔔

- [ ] Firebase messaging setup
- [ ] Local notifications
- [ ] Notification center screen
- [ ] Push notification handling
- [ ] Deep linking from notifications
- [ ] Notification preferences

---

### 2.4 Profile & Settings 👤

- [ ] Business profile screen
- [ ] Edit profile screen
- [ ] KYC status
- [ ] Change password
- [ ] Notification settings
- [ ] App settings
- [ ] Help center
- [ ] Support tickets

---

## 📋 Phase 3: Enhancements (Priority 3)

### 3.1 UI/UX Polish

- [ ] Pull-to-refresh on all list screens
- [ ] Shimmer loading effects
- [ ] Empty state illustrations
- [ ] Error state handling
- [ ] Offline indicators
- [ ] Smooth page transitions
- [ ] Bottom sheet animations
- [ ] Snackbar improvements

---

### 3.2 Performance Optimization

- [ ] Image caching strategy
- [ ] Pagination for all lists
- [ ] Lazy loading
- [ ] Debounce search
- [ ] Optimistic UI updates
- [ ] Background data refresh

---

### 3.3 Security Enhancements

- [ ] Biometric authentication
- [ ] PIN lock
- [ ] Session timeout
- [ ] Certificate pinning
- [ ] Secure storage audit

---

## 📋 Phase 4: Future Features (Priority 4)

### 4.1 Offline Support

- [ ] Local database (Hive/SQLite)
- [ ] Offline queue
- [ ] Sync mechanism
- [ ] Conflict resolution

---

### 4.2 Advanced Features

- [ ] Campaign templates
- [ ] Bulk campaign creation
- [ ] Scheduled campaigns
- [ ] Campaign groups
- [ ] Advanced filters
- [ ] Saved searches
- [ ] Custom reports
- [ ] Export data

---

### 4.3 Monitoring & Analytics

- [ ] Crashlytics integration
- [ ] Analytics tracking (Firebase/Mixpanel)
- [ ] Performance monitoring
- [ ] User behavior tracking
- [ ] A/B testing framework

---

## 🔧 Backend Requirements

### API Endpoints Needed (Priority Order)

**Phase 1 (Critical):**
1. ✅ Wallet Balance API
   - GET `/buyer/wallet/balance`
   - GET `/buyer/wallet/transactions`
   - POST `/buyer/wallet/add-balance`
   - POST `/buyer/wallet/verify-payment`

2. ✅ Campaign Detail API
   - GET `/buyer/orders/:id` (comprehensive)
   - GET `/buyer/orders/:id/tasks`
   - GET `/buyer/orders/:id/reviews`
   - GET `/buyer/orders/:id/activity`
   - GET `/buyer/orders/:id/analytics`
   - PATCH `/buyer/orders/:id/pause`
   - PATCH `/buyer/orders/:id/resume`
   - DELETE `/buyer/orders/:id/cancel`

3. ✅ Review & Rating API
   - POST `/buyer/submissions/:id/approve`
   - POST `/buyer/submissions/:id/reject`
   - POST `/buyer/submissions/:id/request-changes`
   - POST `/buyer/submissions/:id/rate`

4. ✅ Campaign Creation API
   - GET `/buyer/services` (with pricing)
   - POST `/buyer/orders` (create with balance reservation)

**Phase 2:**
- Analytics APIs
- Payment APIs
- Invoice APIs
- Notification APIs

---

## 📊 Database Schema Changes Needed

### Buyer Wallet Table
```sql
CREATE TABLE buyer_wallets (
  id UUID PRIMARY KEY,
  buyer_id UUID REFERENCES users(id),
  available_balance DECIMAL(10,2) DEFAULT 0,
  reserved_balance DECIMAL(10,2) DEFAULT 0,
  total_balance DECIMAL(10,2) GENERATED ALWAYS AS (available_balance + reserved_balance),
  currency VARCHAR(3) DEFAULT 'INR',
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### Transaction Ledger Table
```sql
CREATE TABLE wallet_transactions (
  id UUID PRIMARY KEY,
  wallet_id UUID REFERENCES buyer_wallets(id),
  type VARCHAR(20), -- 'credit', 'debit', 'reserved', 'captured', 'released', 'refund'
  amount DECIMAL(10,2),
  balance_before DECIMAL(10,2),
  balance_after DECIMAL(10,2),
  status VARCHAR(20), -- 'pending', 'processing', 'successful', 'failed'
  description TEXT,
  reference_id UUID, -- campaign_id, payment_id, etc.
  reference_type VARCHAR(50),
  metadata JSONB,
  created_at TIMESTAMP
);
```

### Order (Campaign) Updates
```sql
-- Add payment_status column
ALTER TABLE orders ADD COLUMN payment_status VARCHAR(20) DEFAULT 'pending';
-- Values: 'pending', 'reserved', 'captured', 'released', 'refunded'

-- Add wallet_transaction_id for tracking
ALTER TABLE orders ADD COLUMN wallet_transaction_id UUID REFERENCES wallet_transactions(id);
```

---

## 🎯 Success Metrics

### Phase 1 Completion Criteria
- [ ] Buyer can add balance to wallet
- [ ] Buyer can view Available/Reserved balance split
- [ ] Buyer can create campaign using wallet balance
- [ ] Balance automatically reserves on campaign creation
- [ ] Campaign detail screen shows comprehensive info
- [ ] Buyer can navigate through campaign tabs
- [ ] Buyer can review and rate worker submissions
- [ ] Home dashboard shows real-time balance and stats

### Phase 2 Completion Criteria
- [ ] Analytics charts display correctly
- [ ] Payment history accessible
- [ ] Invoices downloadable as PDF
- [ ] Push notifications working
- [ ] Profile management complete

### Phase 3 Completion Criteria
- [ ] All screens have loading/empty/error states
- [ ] App performs smoothly on low-end devices
- [ ] Security features implemented
- [ ] Biometric auth working

---

## 📝 Development Guidelines

### Code Structure
```
lib/
├── features/
│   ├── wallet/              # NEW - Phase 1
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── home/                # ENHANCE - Phase 1
│   ├── campaigns/           # ENHANCE - Phase 1 (add detail screen)
│   ├── reviews/             # ENHANCE - Phase 1 (add rating)
│   └── ...
```

### Testing Strategy
- Unit tests for use cases and BLoCs
- Widget tests for key screens
- Integration tests for critical flows
- Backend API integration tests

### Documentation
- Update README.md after each phase
- Document API contracts
- Add code comments for complex logic
- Maintain CHANGELOG.md

---

## 🚀 Quick Start for Development

### Phase 1 - Week 1: Wallet Module
1. Implement wallet repository and use cases
2. Create wallet BLoC
3. Build wallet screens and widgets
4. Integrate wallet APIs
5. Test balance flow

### Phase 1 - Week 2: Campaign Detail
1. Implement campaign detail repository methods
2. Create campaign detail BLoC
3. Build campaign detail screen with tabs
4. Integrate campaign detail APIs
5. Test navigation and data display

### Phase 1 - Week 3: Campaign Creation Wizard
1. Design wizard state machine
2. Implement 6-step wizard screens
3. Create wizard BLoC
4. Add form validation
5. Integrate with wallet for balance check
6. Test complete flow

### Phase 1 - Week 4: Review & Rating
1. Update review repository
2. Enhance review BLoC with rating
3. Build review detail and rating screens
4. Integrate review APIs
5. Test approval/rejection flow

---

## 📞 Support & Questions

- Architecture questions → See `ARCHITECTURE.md`
- Setup issues → See `SETUP.md`
- API contracts → See `lib/core/network/api_endpoints.dart`
- UI components → See `BUYER_APP_RESTRUCTURE.md`

---

**Status**: Foundation Complete ✅ | Ready for Phase 1 Implementation 🚀

**Priority**: Wallet Module → Enhanced Home → Campaign Detail → Campaign Wizard → Reviews

**Timeline**: Phase 1 (4 weeks) | Phase 2 (3 weeks) | Phase 3 (2 weeks) | Phase 4 (Future)

