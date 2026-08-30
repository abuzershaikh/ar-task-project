# AR Task Project - Complete Folder Structure Guide (اردو/हिंदी)

## 📚 پراجیکٹ کا مکمل خلاصہ | प्रोजेक्ट का पूर्ण सारांश

یہ **AR Task Project** ایک مکمل **Micro-Task Marketplace System** ہے جو تین Flutter Mobile Apps اور ایک مرکزی NestJS Backend API پر مشتمل ہے۔

यह **AR Task Project** एक पूर्ण **Micro-Task Marketplace System** है जो तीन Flutter Mobile Apps और एक केंद्रीय NestJS Backend API से मिलकर बना है।

---

## 🎯 سسٹم کا مقصد | सिस्टम का उद्देश्य

**مسئلہ (Problem):**
Digital campaigns، marketing promotions، app testing اور social media tasks کے لیے ہزاروں workers کو manually hire کرنا، tasks assign کرنا، progress track کرنا اور micro-payouts handle کرنا بہت مشکل اور غیر موثر ہے۔

**حل (Solution):**
یہ system تین dedicated apps استعمال کرتا ہے:
1. **Admin App** - Service catalog manage کرتا ہے
2. **Buyer App** - Campaigns create اور orders place کرتا ہے  
3. **Worker App** - Tasks accept اور complete کرتا ہے

---

## 📁 مکمل Folder Structure | पूर्ण फोल्डर संरचना

```
ar-task-project/
│
├── 📱 Admin app/              (Flutter - Admin Mobile App)
│   ├── lib/                   (Main source code)
│   ├── android/               (Android configuration)
│   ├── pubspec.yaml           (Flutter dependencies)
│   └── Documentation files    (ARCHITECTURE.md, README.md, etc.)
│
├── 📱 Buyer app/              (Flutter - Buyer/Campaign Creator Mobile App)
│   ├── lib/                   (Main source code)
│   ├── android/               (Android configuration)
│   ├── pubspec.yaml           (Flutter dependencies)
│   └── Documentation files    (BUILD_GUIDE.md, SETUP.md, etc.)
│
├── 📱 Worker app/             (Flutter - Worker/Task Executor Mobile App)
│   ├── lib/                   (Main source code)
│   ├── android/               (Android configuration)
│   ├── pubspec.yaml           (Flutter dependencies)
│   └── README.md
│
├── 🔧 Task engine/            (NestJS Backend API - Port 3000)
│   ├── apps/                  (Main API modules)
│   ├── allocation-engine/     (Task assignment engine)
│   ├── matching-engine/       (Worker-task matching logic)
│   ├── scoring-engine/        (Worker trust score calculation)
│   ├── earning-engine/        (Earning calculation & wallet)
│   ├── payout-engine/         (Withdrawal & payout management)
│   ├── review-engine/         (Task review & approval system)
│   ├── reward-engine/         (Reward distribution logic)
│   ├── progress-engine/       (Order & task progress tracking)
│   ├── execution-engine/      (Task execution management)
│   ├── fraud-engine/          (Fraud detection)
│   ├── notification-engine/   (Push notifications)
│   ├── eligibility-engine/    (Worker eligibility checks)
│   ├── ranking-engine/        (Worker ranking system)
│   ├── shared/                (Common utilities & modules)
│   ├── package.json           (Node.js dependencies)
│   ├── main.ts                (API entry point)
│   └── Documentation files    (API_CONTRACT_ADMIN_V1.md, SYSTEM_ARCHITECTURE.md)
│
├── ☁️ cloudflare-media-worker/ (Cloudflare Worker for media handling)
│
├── 🚀 deploy-tools/            (Deployment scripts & tools)
│
├── 📦 release_kit/             (Release & APK building tools)
│
├── PROJECT_STORY_AND_ARCHITECTURE.md  (Complete system architecture)
├── GRADLE_CLEANUP_GUIDE.md            (Gradle cache cleanup guide)
├── package.json                        (Root package file)
└── vps_ssh.js                         (VPS SSH connection script)
```

---

## 🎨 ہر App کی تفصیل | प्रत्येक App का विवरण

### 1️⃣ Admin App (ایڈمن ایپ)

**مقصد (Purpose):**
- Service catalog create اور manage کرنا
- Pricing aur margins set کرنا
- Worker payouts approve کرنا
- Platform analytics دیکھنا

**Key Files:**
- `lib/` - Main Dart/Flutter source code
- `ARCHITECTURE.md` - App architecture guide
- `BACKEND_INTEGRATION_GUIDE.md` - API integration details
- `pubspec.yaml` - Dependencies (dio, flutter_riverpod, etc.)

**Features:**
✅ Service creation & pricing management
✅ Worker payout approval system
✅ Platform-wide analytics
✅ Review dispute resolution
✅ System configuration management

---

### 2️⃣ Buyer App (بائر ایپ - Campaign Creator)

**مقصد (Purpose):**
- Service catalog browse کرنا
- Campaign orders create کرنا
- Payment gateway integration (Razorpay)
- Task progress track کرنا
- Worker submissions review کرنا

**Key Files:**
- `lib/` - Main Flutter source code
- `BUILD_GUIDE.md` - Complete build instructions
- `SETUP.md` - Setup & configuration guide
- `BUYER_APP_RESTRUCTURE.md` - App structure details

**Features:**
✅ Browse available services
✅ Price estimation calculator
✅ Online payment gateway
✅ Campaign progress tracking
✅ Worker proof review system
✅ Order analytics dashboard

---

### 3️⃣ Worker App (ورکر ایپ - Task Executor)

**مقصد (Purpose):**
- Available tasks دیکھنا
- Tasks accept اور complete کرنا
- Proof of work submit کرنا
- Earnings track کرنا
- Withdrawal request کرنا

**Key Files:**
- `lib/` - Main Flutter source code
- `pubspec.yaml` - Flutter dependencies
- `README.md` - App overview

**Features:**
✅ Task feed & availability
✅ Accept/Start/Submit workflow
✅ Timer-based task management
✅ Proof upload (screenshots/URLs)
✅ Wallet & earnings tracking
✅ Withdrawal requests
✅ Trust score & level system

---

### 4️⃣ Task Engine (ٹاسک انجن - Backend API)

**مقصد (Purpose):**
تمام apps کے لیے مرکزی API server جو port 3000 پر `/api/v1` endpoints provide کرتا ہے۔

**Technology Stack:**
- **Framework:** NestJS (Node.js/TypeScript)
- **Database:** MySQL (via TypeORM)
- **Architecture:** Microservice-based engines

**Main Engines:**

#### 🎯 **Allocation Engine** (allocation-engine/)
- Tasks کو eligible workers کو assign کرتا ہے
- Batch processing support
- Auto-allocation rules

#### 🔍 **Matching Engine** (matching-engine/)
- Workers کو tasks سے match کرتا ہے
- Candidate selection algorithm
- Availability-based filtering

#### ⭐ **Scoring Engine** (scoring-engine/)
- Worker trust scores calculate کرتا ہے
- Performance metrics tracking
- Penalty system

#### 💰 **Earning Engine** (earning-engine/)
- Worker earnings calculate کرتا ہے
- Wallet balance management
- Transaction history

#### 🏦 **Payout Engine** (payout-engine/)
- Withdrawal requests handle کرتا ہے
- Minimum threshold validation
- Admin approval workflow

#### ✅ **Review Engine** (review-engine/)
- Task submissions review کرتا ہے
- Buyer/Admin/Auto review modes
- Approve/Reject/Request Changes logic

#### 🎁 **Reward Engine** (reward-engine/)
- Pricing snapshots maintain کرتا ہے
- Worker reward distribution
- Platform margin calculation

#### 📊 **Progress Engine** (progress-engine/)
- Order completion tracking
- Task timelines
- Analytics data generation

**Key Configuration Files:**
- `package.json` - Backend dependencies (NestJS, TypeORM, MySQL2)
- `main.ts` - API server entry point
- `ecosystem.config.json` - PM2 deployment config
- `API_CONTRACT_ADMIN_V1.md` - Complete API documentation
- `SYSTEM_ARCHITECTURE.md` - System design details

---

## 🔄 System Flow (سسٹم کا کام کا طریقہ)

### Step 1: Admin Setup
```
Admin → Creates Service in Catalog → Sets Pricing & Margins
```

### Step 2: Buyer Creates Campaign
```
Buyer → Selects Service → Gets Price Estimate → Creates Order (PAYMENT_PENDING)
      → Completes Payment → Order Status: ACTIVE → Tasks Generated
```

### Step 3: Task Allocation
```
Task Engine → Matching Engine (Finds eligible workers)
           → Scoring Engine (Ranks by trust score)
           → Allocation Engine (Assigns to top workers)
```

### Step 4: Worker Execution
```
Worker → Sees Available Task → Accepts Task (Timer starts)
       → Starts Work → Submits Proof (Screenshot/URL)
       → Task moves to UNDER_REVIEW
```

### Step 5: Review & Earning
```
Reviewer (Buyer/Admin/Auto) → Reviews Submission
                            → APPROVED → Earning posted to Worker Wallet
                            → REJECTED → Zero payment, score penalty
                            → CHANGES_REQUESTED → Worker resubmits
```

### Step 6: Payout
```
Worker → Requests Withdrawal (Minimum threshold check)
       → Status: REQUESTED → Admin Processes
       → Status: PAID → Worker receives money
```

---

## 🛠️ Technical Stack Summary

### Mobile Apps (تینوں Apps):
- **Framework:** Flutter
- **Language:** Dart
- **State Management:** Riverpod (Admin/Buyer), Provider (Worker)
- **HTTP Client:** dio
- **Platform:** Android (iOS support possible)

### Backend (Task Engine):
- **Framework:** NestJS
- **Language:** TypeScript
- **Database:** MySQL
- **ORM:** TypeORM
- **Runtime:** Node.js
- **Architecture:** Modular engine-based

### Additional Tools:
- **Media Hosting:** Cloudflare Worker
- **Process Manager:** PM2 (ecosystem.config.json)
- **Deployment:** Custom scripts in deploy-tools/
- **Release:** APK building in release_kit/

---

## 📝 Important Documents

| Document | Purpose |
|----------|---------|
| `PROJECT_STORY_AND_ARCHITECTURE.md` | مکمل system architecture اور business logic |
| `Task engine/API_CONTRACT_ADMIN_V1.md` | Complete API endpoints documentation |
| `Task engine/SYSTEM_ARCHITECTURE.md` | Backend engine architecture details |
| `Admin app/BACKEND_INTEGRATION_GUIDE.md` | API integration for Admin app |
| `Buyer app/BUILD_GUIDE.md` | Buyer app build instructions |
| `GRADLE_CLEANUP_GUIDE.md` | Android build cache cleanup |

---

## 🚀 Setup کیسے کریں | सेटअप कैसे करें

### Backend (Task Engine) Setup:
```bash
cd "Task engine"
npm install
# Configure .env file with MySQL credentials
npm run start:dev
# API runs on http://localhost:3000
```

### Mobile Apps Setup:
```bash
# Admin App
cd "Admin app"
flutter pub get
flutter run

# Buyer App
cd "Buyer app"
flutter pub get
flutter run

# Worker App
cd "Worker app"
flutter pub get
flutter run
```

---

## 🎯 Key Features Summary

### Admin کے Features:
✅ Service catalog management
✅ Pricing & margin configuration
✅ Worker payout approval
✅ Platform analytics
✅ Dispute resolution

### Buyer کے Features:
✅ Service browsing
✅ Campaign creation
✅ Payment gateway integration
✅ Task progress tracking
✅ Worker submission review

### Worker کے Features:
✅ Task discovery & acceptance
✅ Proof submission
✅ Earnings tracking
✅ Withdrawal requests
✅ Trust score monitoring

### Backend Engine Features:
✅ Automated task allocation
✅ Worker-task matching
✅ Trust score calculation
✅ Earning & wallet management
✅ Review & approval workflow
✅ Payout processing
✅ Fraud detection
✅ Push notifications

---

## 🔐 Security & Validation

- **Payment Gateway:** Razorpay integration
- **Idempotency:** Duplicate transaction prevention
- **State Machine:** Strict task status transitions
- **Pricing Snapshots:** Locked at order creation
- **Trust Scores:** Fraud prevention through worker scoring
- **Timers:** Accept & completion deadlines

---

## 📞 کسی بھی مسئلہ کے لیے | किसी भी समस्या के लिए

Repository میں ہر folder میں detailed documentation files موجود ہیں:
- README.md files
- Architecture guides
- Setup instructions
- API contracts
- Implementation checklists

---

## ✨ Project Highlights

یہ ایک **Production-Ready** micro-task marketplace system ہے جس میں:

1. ✅ **Complete Architecture** - Well-documented system design
2. ✅ **Three Role-Based Apps** - Admin, Buyer, Worker
3. ✅ **Powerful Backend** - Multiple specialized engines
4. ✅ **Payment Integration** - Razorpay gateway
5. ✅ **Fraud Prevention** - Trust scoring & validation
6. ✅ **Scalable Design** - Modular engine architecture
7. ✅ **Complete Workflow** - From order creation to payout

---

**یہ folder structure اور documentation آپ کو پوری project کو سمجھنے میں مدد کرے گی!**

**यह फोल्डर स्ट्रक्चर और डॉक्यूमेंटेशन आपको पूरे प्रोजेक्ट को समझने में मदद करेगी!**
