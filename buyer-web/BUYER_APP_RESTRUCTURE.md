# Buyer App - Enterprise UX Restructure

## 🎯 Core Navigation Structure

### Bottom Navigation (5 Tabs)
```
┌────────┬───────────┬─────────┬───────────┬────────┐
│  Home  │ Campaigns │ Reviews │ Analytics │  More  │
│   🏠   │    📋     │   ✓     │    📊     │   ⋯    │
└────────┴───────────┴─────────┴───────────┴────────┘
```

### Floating Action Button
```
[+ Create Campaign]
```
- Visible on Home, Campaigns screens
- Opens step-by-step campaign creation wizard

---

## 🏠 1. HOME DASHBOARD (Enhanced)

### Header Section
```dart
┌─────────────────────────────────────┐
│ Good Morning 👋                      │
│ ABC Digital                     🔔  │
└─────────────────────────────────────┘
```

### Wallet Balance Card (NEW - TOP PRIORITY)
```dart
┌─────────────────────────────────────┐
│ Available Balance                   │
│                                     │
│ ₹24,500.00                          │
│                                     │
│ [ + Add Balance ]                   │
│                                     │
│ Reserved        Available           │
│ ₹5,000          ₹19,500             │
└─────────────────────────────────────┘
```

**Balance Logic:**
- **Total Balance** = Available + Reserved
- **Available** = Can be used for new campaigns
- **Reserved** = Locked for active campaigns
- **On campaign create** → Move from Available to Reserved
- **On campaign complete** → Capture from Reserved
- **On campaign cancel** → Release back to Available

### Campaign Overview Card
```dart
┌─────────────────────────────────────┐
│ Campaign Overview                   │
│                                     │
│ 12 Active          38 Completed     │
│                                     │
│ Total Tasks        Completed        │
│ 5,000              4,280            │
│                                     │
│         85.6% Complete              │
│      ████████████████░░             │
└─────────────────────────────────────┘
```

### Spending Card
```dart
┌─────────────────────────────────────┐
│ Total Spent                         │
│ ₹1,24,500                           │
│                                     │
│ This Month                          │
│ ₹28,500         ↑ 12%              │
│                                     │
│ [ View Payments ]                   │
└─────────────────────────────────────┘
```

### Action Required Card (Dynamic)
```dart
// If pending reviews exist:
┌─────────────────────────────────────┐
│ ⚠ Action Required                   │
│                                     │
│ 23 worker submissions waiting       │
│ for your review                     │
│                                     │
│ [ Review Now ]                      │
└─────────────────────────────────────┘

// If all caught up:
┌─────────────────────────────────────┐
│ ✓ All Caught Up                     │
│                                     │
│ No reviews waiting                  │
└─────────────────────────────────────┘
```

### Active Campaigns (Top 3)
```dart
Active Campaigns                [ View All ]

┌─────────────────────────────────────┐
│ Product Testing                     │
│ CAMP-001 • ₹12,500                  │
│                                     │
│ 320 / 500                           │
│ ████████████░░░ 64%                 │
│                                     │
│ Ends in 1d 8h                       │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Review Campaign                     │
│ CAMP-002 • ₹5,000                   │
│                                     │
│ 180 / 200                           │
│ ████████████████░ 90%               │
│                                     │
│ Ends in 4h 30m                      │
└─────────────────────────────────────┘
```

### Quick Actions
```dart
┌─────────────────────────────────────┐
│ Quick Actions                       │
│                                     │
│ + Create      📋 Services           │
│ Campaign                            │
│                                     │
│ ✓ Reviews     💰 Payments           │
│                                     │
│ 📊 Analytics  🧾 Invoices           │
└─────────────────────────────────────┘
```

---

## 📋 2. CAMPAIGNS SCREEN

### Top Section
```dart
← Campaigns                      🔍 Filter ▾

┌──────────────────────────────────────┐
│ All | Active | Paused | Completed    │
└──────────────────────────────────────┘
```

### Campaign Card
```dart
┌─────────────────────────────────────┐
│ Product Testing              🟢 ACTIVE│
│ CAMP-001                            │
│                                     │
│ 320 / 500 completed                 │
│ █████████████░░░ 64%                │
│                                     │
│ ✓ 320 Completed                     │
│ ◉  80 In Progress                   │
│ ◌ 100 Pending                       │
│                                     │
│ ₹12,500 • Ends in 1d 8h             │
└─────────────────────────────────────┘
```

### Status Badges
- 🟢 **ACTIVE** - Campaign running
- 🟡 **PAUSED** - Temporarily paused by buyer
- 🔵 **UNDER REVIEW** - Pending admin review
- ✓ **COMPLETED** - All tasks done
- 🔴 **CANCELLED** - Cancelled by buyer/admin

---

## 📝 3. CAMPAIGN DETAIL SCREEN (Dedicated)

### Top Bar
```dart
← Product Testing                    ⋮
  CAMP-001   🟢 ACTIVE
```

### Tabs
```dart
┌──────────────────────────────────────┐
│ Overview | Tasks | Reviews           │
│ Activity | Analytics                 │
└──────────────────────────────────────┘
```

### Overview Tab
```dart
┌─────────────────────────────────────┐
│ Progress                            │
│                                     │
│ 410 / 500 Tasks                     │
│ ████████████████░░ 82%              │
│                                     │
│ ✓ 410 Completed                     │
│ ◉  50 In Progress                   │
│ ◌  30 Pending                       │
│ ✗  10 Rejected                      │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Campaign Details                    │
│                                     │
│ Status          Active              │
│ Created         11 Aug              │
│ Deadline        13 Aug, 10:00 PM    │
│                                     │
│ Campaign Amount                     │
│ Total           ₹12,500             │
│ Payment         ✓ Reserved          │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Deadline Status                     │
│                                     │
│ Original        30 Aug, 10:00 PM    │
│ Current         31 Aug, 08:00 AM    │
│                                     │
│ ℹ Extended automatically by 10 hours│
└─────────────────────────────────────┘
```

### Tasks Tab
```dart
All | Pending | Working | Submitted | Approved | Rejected

┌─────────────────────────────────────┐
│ Task #T-1024                        │
│ Worker: W-204                       │
│                                     │
│ Status: Under Review                │
│ Submitted: 8 min ago                │
│                                     │
│ [ View Submission ]                 │
└─────────────────────────────────────┘
```

### Reviews Tab
```dart
23 Pending Reviews

┌─────────────────────────────────────┐
│ Task #T-1024                        │
│ 📷 2 Proofs                         │
│ Submitted 8 min ago                 │
│                                     │
│ [ Review ]                          │
└─────────────────────────────────────┘
```

### Activity Tab
```dart
Timeline

11 Aug, 2:30 PM
Campaign Created

11 Aug, 2:35 PM
Payment Confirmed

11 Aug, 2:40 PM
500 Tasks Generated

11 Aug, 3:00 PM
Workers Assigned

11 Aug, 4:15 PM
First Submission

12 Aug, 10:00 AM
100 Tasks Completed

13 Aug, 10:05 PM
Campaign Extended +10h
```

### Analytics Tab
```dart
Campaign Performance

Completion Rate     82%
Approval Rate       95%
Rejection Rate       5%
Average Review Time  12 min
Tasks/Hour          8.2

┌─────────────────────────────────────┐
│ Completion Trend                    │
│                                     │
│ [Line Chart]                        │
└─────────────────────────────────────┘
```

### More Menu (⋮)
```
Pause Campaign
Resume Campaign
Extend Campaign
Cancel Campaign
View Invoice
Report Issue
```

---

## ➕ 4. CREATE CAMPAIGN (Step-by-Step Wizard)

### Step 1: Choose Service
```dart
← Create Campaign                 Step 1/6

Choose a Service

┌─────────────────────────────────────┐
│ Product Testing                     │
│ ₹25 / task                          │
│                                     │
│ Get product testing and feedback    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Survey                              │
│ ₹15 / task                          │
│                                     │
│ Collect survey responses            │
└─────────────────────────────────────┘

[ Continue ]
```

### Step 2: Campaign Details
```dart
← Create Campaign                 Step 2/6

Campaign Details

Campaign Name
┌─────────────────────────────────────┐
│ Product Testing August              │
└─────────────────────────────────────┘

Quantity
┌─────────────────────────────────────┐
│ 500                                 │
└─────────────────────────────────────┘

Instructions
┌─────────────────────────────────────┐
│                                     │
│                                     │
│                                     │
└─────────────────────────────────────┘

[ Back ]  [ Continue ]
```

### Step 3: Proof Requirements
```dart
← Create Campaign                 Step 3/6

Proof Required

☑ Screenshot (Required)
☑ Image
☐ Video
☑ Text Response
☐ Link

ℹ Some requirements are mandatory
  for this service

[ Back ]  [ Continue ]
```

### Step 4: Timing
```dart
← Create Campaign                 Step 4/6

Task Timing

Accept within
┌─────────────────────────────────────┐
│ 24 hours                            │
└─────────────────────────────────────┘

Complete within
┌─────────────────────────────────────┐
│ 48 hours                            │
└─────────────────────────────────────┘

Campaign Deadline
┌─────────────────────────────────────┐
│ 30 Aug 2026                         │
└─────────────────────────────────────┘

ℹ If campaign incomplete at deadline,
  system may extend based on configured
  extension policy

[ Back ]  [ Continue ]
```

### Step 5: Review Rules
```dart
← Create Campaign                 Step 5/6

Review Mode

● Manual Review
○ Auto-approved (not available for this service)

ℹ This service requires manual review
  of all submissions

[ Back ]  [ Continue ]
```

### Step 6: Summary & Payment
```dart
← Create Campaign                 Step 6/6

Campaign Summary

Service          Product Testing
Quantity         500 tasks
Price/Task       ₹25
Total Amount     ₹12,500

┌─────────────────────────────────────┐
│ Available Balance                   │
│ ₹24,500                             │
│                                     │
│ Campaign Cost                       │
│ ₹12,500                             │
│                                     │
│ Remaining Balance                   │
│ ₹12,000                             │
└─────────────────────────────────────┘

[ Back ]  [ Create Campaign ]
```

### Insufficient Balance
```dart
┌─────────────────────────────────────┐
│ ⚠ Insufficient Balance              │
│                                     │
│ Campaign Cost     ₹12,500           │
│ Available          ₹800             │
│ Required         ₹11,700            │
│                                     │
│ [ Add ₹11,700 ]                     │
└─────────────────────────────────────┘
```

### Success
```dart
┌─────────────────────────────────────┐
│ ✓ Campaign Created                  │
│                                     │
│ CAMP-001                            │
│ Product Testing                     │
│                                     │
│ Your campaign is now active         │
│                                     │
│ [ View Campaign ]                   │
│ [ Create Another ]                  │
└─────────────────────────────────────┘
```

---

## ⭐ 5. REVIEWS SCREEN

### Top Tabs
```dart
← Reviews                           🔍

┌──────────────────────────────────────┐
│ Pending | Approved | Rejected         │
└──────────────────────────────────────┘
```

### Pending Card
```dart
┌─────────────────────────────────────┐
│ Product Testing                     │
│ Task #T-1023                        │
│                                     │
│ Submitted 8 min ago                 │
│                                     │
│ 📷 2 Images   🔗 1 Link             │
│                                     │
│ [ Review ]                          │
└─────────────────────────────────────┘
```

### Review Detail Screen
```dart
← Review Submission

Task #T-1023

Service         Product Testing
Campaign        CAMP-001
Worker          W-204

Submission Details
────────────────────────

Screenshot
[Full Image Preview]

Worker Response
"Completed testing and provided
feedback on the product..."

Link
[ Open Link ]

Submitted
10 Aug, 4:32 PM

────────────────────────

[ Reject ]  [ Request Changes ]  [ Approve ]
```

### After Approve
```dart
┌─────────────────────────────────────┐
│ ✓ Task Approved                     │
│                                     │
│ [ Rate Worker ]                     │
└─────────────────────────────────────┘
```

### Rating Screen
```dart
← Rate Worker

Rate this work

Overall Quality
☆ ☆ ☆ ☆ ☆

Work Quality
☆ ☆ ☆ ☆ ☆

Accuracy
☆ ☆ ☆ ☆ ☆

Comment (Optional)
┌─────────────────────────────────────┐
│                                     │
│                                     │
└─────────────────────────────────────┘

[ Skip ]  [ Submit Rating ]
```

---

## 💰 6. WALLET & BALANCE (NEW MODULE)

### Wallet Screen (in More)
```dart
← Wallet & Billing

┌─────────────────────────────────────┐
│ Total Balance                       │
│ ₹8,500                              │
│                                     │
│ Available       Reserved            │
│ ₹3,500          ₹5,000              │
└─────────────────────────────────────┘

[ + Add Balance ]

Transactions
┌──────────────────────────────────────┐
│ All | Credits | Debits | Reserved    │
└──────────────────────────────────────┘

+ ₹10,000  Balance Added
  Today, 2:30 PM
  Payment ID: PAY-1023
  ✓ Successful

− ₹5,000  Campaign CAMP-001
  Today, 3:00 PM
  Reserved

− ₹2,000  Campaign CAMP-002
  Yesterday
  Captured

+ ₹1,000  Campaign CAMP-003
  2 days ago
  Refund Released
```

### Add Balance Flow
```dart
← Add Balance

Quick Amount
┌─────────────────────────────────────┐
│  ₹1,000   ₹5,000   ₹10,000          │
└─────────────────────────────────────┘

Custom Amount
┌─────────────────────────────────────┐
│ ₹                                   │
└─────────────────────────────────────┘

Payment Method
○ UPI
○ Card
○ Net Banking
○ Wallet

[ Continue to Payment ]
```

### Payment Processing
```dart
Processing Payment...

      ⏳

Verifying...

      ↓

✓ Payment Successful

Balance +₹10,000

[ Done ]
```

---

## 📊 7. ANALYTICS SCREEN

### Overall Analytics
```dart
← Analytics                     Filter ▾

┌─────────────────────────────────────┐
│ Total Campaigns         48          │
│ Completed               38          │
│ Success Rate            91%         │
│ Total Tasks         12,500          │
└─────────────────────────────────────┘

Completion Trend
┌─────────────────────────────────────┐
│ [Line Chart]                        │
│                                     │
│ Mon  ███████                        │
│ Tue  █████████                      │
│ Wed  ███████████                    │
│ Thu  █████████                      │
└─────────────────────────────────────┘

Task Performance
┌─────────────────────────────────────┐
│ Completion Rate      85%            │
│ Approval Rate        92%            │
│ Rejection Rate        8%            │
│ Avg Review Time   15 min            │
│ Pending Tasks       280             │
└─────────────────────────────────────┘

Spending Analysis
┌─────────────────────────────────────┐
│ [Bar Chart]                         │
│                                     │
│ This Month    ₹28,500               │
│ Last Month    ₹24,200               │
│ Growth         +18%                 │
└─────────────────────────────────────┘
```

---

## 🧾 8. MORE SCREEN

```dart
More

┌─────────────────────────────────────┐
│ 💰 Wallet & Billing                 │
│                                     │
│ 💳 Payments                         │
│                                     │
│ 🧾 Invoices                         │
│                                     │
│ 🔔 Notifications                    │
│                                     │
│ 👤 Business Profile                 │
│                                     │
│ ⚙ Settings                          │
│                                     │
│ 🆘 Help & Support                   │
│                                     │
│ ──────────────────────              │
│                                     │
│ About                               │
│ Privacy Policy                      │
│ Terms & Conditions                  │
│                                     │
│ Logout                              │
└─────────────────────────────────────┘
```

---

## 🎨 UI Design Guidelines

### Colors
```dart
Primary: #5B47DB (Blue-Violet)
Success: #10B981 (Green)
Warning: #F59E0B (Amber)
Error: #EF4444 (Red)
Active: #10B981 (Green)
Paused: #F59E0B (Yellow)
Completed: #6B7280 (Gray)
```

### Typography
```dart
Dashboard Title:    24px / Bold
Section Title:      18px / SemiBold
Main Number:        24-28px / Bold
Body:               14-16px / Regular
Caption:            12px / Regular
```

### Card Style
```dart
Border Radius: 16-20px
Shadow: Soft (elevation 2-4)
Padding: 16-20px
```

### Progress Bars
```dart
Height: 8px (thin linear)
Border Radius: 4px
Large Circular: 120px diameter
```

---

## 🔒 Financial Flow

### Campaign Creation
```
Available Balance ₹8,500
        ↓
Campaign Cost ₹5,000
        ↓
Reserve ₹5,000
        ↓
Available ₹3,500
Reserved ₹5,000
```

### Campaign Completion
```
Reserved ₹5,000
        ↓
Capture (backend processes)
        ↓
Reserved ₹0
```

### Campaign Cancellation
```
Reserved ₹5,000
        ↓
Release to Available
        ↓
Available +₹5,000
Reserved ₹0
```

---

## 📱 Complete User Journey

```
LOGIN
  ↓
HOME (Balance, Campaigns, Actions)
  ↓
CREATE CAMPAIGN
  ├─ Choose Service
  ├─ Details
  ├─ Proof
  ├─ Timing
  ├─ Review Mode
  └─ Summary → Reserve Balance
  ↓
CAMPAIGN ACTIVE
  ↓
CAMPAIGN DETAIL
  ├─ Overview (Progress)
  ├─ Tasks (List)
  ├─ Reviews (Pending)
  ├─ Activity (Timeline)
  └─ Analytics (Metrics)
  ↓
REVIEWS
  ├─ View Submission
  ├─ Approve/Reject
  └─ Rate Worker
  ↓
ANALYTICS
  └─ Performance Reports
```

---

## 📂 Implementation Priority

### Phase 1: Core (Must Have)
1. ✅ Wallet/Balance system (Available + Reserved)
2. ✅ Enhanced Home Dashboard
3. ✅ Campaign Detail Screen with tabs
4. ✅ Step-by-step Campaign Creation
5. ✅ Review workflow with rating

### Phase 2: Enhancement
1. ✅ Analytics with charts
2. ✅ Add Balance flow
3. ✅ Transaction history
4. ✅ Campaign activity timeline
5. ✅ Notification system

### Phase 3: Polish
1. Pull-to-refresh
2. Shimmer loading
3. Empty states
4. Error handling
5. Offline indicators

---

## 🎯 Key Differences from Current Structure

1. **Wallet Module Added**: Complete prepaid balance system
2. **5-Tab Navigation**: Removed individual Services/Payments/Invoices from bottom nav
3. **Floating Create Button**: Instead of tab
4. **Campaign Detail Tabs**: Comprehensive per-campaign view
5. **Balance Reservation**: Reserve → Capture → Release flow
6. **Enhanced Home**: Balance + Actions + Pending reviews
7. **Step-by-Step Wizard**: Clear campaign creation flow
8. **Rating System**: Worker feedback after approval

