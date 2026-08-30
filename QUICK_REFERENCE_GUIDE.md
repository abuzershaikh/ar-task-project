# AR Task Project - Quick Reference Guide

## 🚀 تیزی سے شروع کریں | तेजी से शुरू करें

یہ guide آپ کو project کو quickly setup اور run کرنے میں مدد کرے گی۔

---

## 📋 Prerequisites (پہلے سے ضروری چیزیں)

### Mobile Apps کے لیے:
- ✅ Flutter SDK (latest stable version)
- ✅ Android Studio / VS Code
- ✅ Android SDK & Emulator
- ✅ Dart SDK (comes with Flutter)

### Backend (Task Engine) کے لیے:
- ✅ Node.js (v16 or higher)
- ✅ npm or yarn
- ✅ MySQL Server (v8.0 or higher)
- ✅ PM2 (for production deployment)

---

## 🏗️ Installation Steps (انسٹالیشن کے قدم)

### 1️⃣ Backend Setup (Task Engine)

```bash
# Navigate to Task Engine folder
cd "Task engine"

# Install dependencies
npm install

# Create .env file from example
copy .env.example .env

# Configure .env file with your MySQL credentials
# Edit these values:
# DB_HOST=localhost
# DB_PORT=3306
# DB_USERNAME=root
# DB_PASSWORD=your_password
# DB_DATABASE=ar_task_db

# Run database migrations
npm run migration:run

# Start development server
npm run start:dev

# API will be available at: http://localhost:3000
```

**Important Endpoints:**
- API Base: `http://localhost:3000/api/v1`
- Admin APIs: `/api/v1/admin/*`
- Buyer APIs: `/api/v1/buyer/*`
- Worker APIs: `/api/v1/worker/*`

---

### 2️⃣ Admin App Setup

```bash
# Navigate to Admin app folder
cd "Admin app"

# Install Flutter dependencies
flutter pub get

# Create .env file
copy .env.example .env

# Configure API endpoint in .env:
# API_BASE_URL=http://localhost:3000/api/v1
# Or use your VPS IP for testing on real device:
# API_BASE_URL=http://YOUR_VPS_IP:3000/api/v1

# Run the app (emulator or device)
flutter run

# For release build:
flutter build apk --release
# APK will be in: build/app/outputs/flutter-apk/app-release.apk
```

---

### 3️⃣ Buyer App Setup

```bash
# Navigate to Buyer app folder
cd "Buyer app"

# Install Flutter dependencies
flutter pub get

# Create .env file
copy .env.example .env

# Configure API endpoint in .env:
# API_BASE_URL=http://localhost:3000/api/v1

# Run the app
flutter run

# For release build:
flutter build apk --release
```

---

### 4️⃣ Worker App Setup

```bash
# Navigate to Worker app folder
cd "Worker app"

# Install Flutter dependencies
flutter pub get

# Configure API endpoint in lib/config/api_config.dart
# baseUrl: 'http://localhost:3000/api/v1'

# Run the app
flutter run

# For release build:
flutter build apk --release
```

---

## 🔧 Common Commands (عام Commands)

### Backend (Task Engine)

```bash
# Development mode with auto-reload
npm run start:dev

# Production mode
npm run build
npm run start:prod

# Run with PM2 (production)
pm2 start ecosystem.config.json

# Check PM2 status
pm2 status

# View logs
pm2 logs

# Database migrations
npm run migration:generate -- -n MigrationName
npm run migration:run
npm run migration:revert

# Create admin user (after backend is running)
node create_admin.js

# Check database connection
node check_mysql.js
```

---

### Flutter Apps

```bash
# Get dependencies
flutter pub get

# Clean build cache
flutter clean

# Run app in debug mode
flutter run

# Run with specific device
flutter run -d DEVICE_ID

# List available devices
flutter devices

# Build release APK
flutter build apk --release

# Build release APK with splits (smaller size)
flutter build apk --split-per-abi --release

# Analyze code
flutter analyze

# Run tests
flutter test

# Check Flutter doctor
flutter doctor
```

---

## 🗂️ Project Structure Quick Reference

```
ar-task-project/
│
├── 📱 Admin app/
│   └── lib/
│       ├── main.dart              # Entry point
│       ├── config/                # Configuration
│       ├── models/                # Data models
│       ├── providers/             # Riverpod state management
│       ├── services/              # API services
│       ├── screens/               # UI screens
│       └── widgets/               # Reusable widgets
│
├── 📱 Buyer app/
│   └── lib/
│       ├── main.dart
│       ├── core/                  # Core utilities
│       ├── features/              # Feature modules
│       │   ├── auth/
│       │   ├── dashboard/
│       │   ├── orders/
│       │   └── reviews/
│       └── shared/                # Shared components
│
├── 📱 Worker app/
│   └── lib/
│       ├── main.dart
│       ├── models/
│       ├── providers/
│       ├── screens/
│       └── services/
│
└── 🔧 Task engine/
    ├── apps/                      # Main API application
    │   ├── api/
    │   │   ├── src/
    │   │   │   ├── admin/         # Admin controllers
    │   │   │   ├── buyer/         # Buyer controllers
    │   │   │   ├── worker/        # Worker controllers
    │   │   │   └── shared/        # Shared modules
    │   │   └── main.ts
    │   └── migrations/            # Database migrations
    │
    ├── allocation-engine/         # Task allocation logic
    ├── matching-engine/           # Worker-task matching
    ├── scoring-engine/            # Trust score calculation
    ├── earning-engine/            # Earnings management
    ├── payout-engine/             # Withdrawal processing
    └── review-engine/             # Review workflow
```

---

## 🔑 Important Configuration Files

### Backend (.env)
```env
# Database
DB_HOST=localhost
DB_PORT=3306
DB_USERNAME=root
DB_PASSWORD=your_password
DB_DATABASE=ar_task_db

# JWT
JWT_SECRET=your_secret_key_here
JWT_EXPIRATION=7d

# Server
PORT=3000
NODE_ENV=development

# Razorpay (Payment Gateway)
RAZORPAY_KEY_ID=your_razorpay_key
RAZORPAY_KEY_SECRET=your_razorpay_secret

# Cloudflare (Media Upload)
CLOUDFLARE_ACCOUNT_ID=your_account_id
CLOUDFLARE_API_TOKEN=your_api_token
```

### Flutter Apps (.env)
```env
API_BASE_URL=http://localhost:3000/api/v1
# For real device testing:
# API_BASE_URL=http://192.168.1.100:3000/api/v1
```

---

## 📡 API Endpoint Quick Reference

### Admin Endpoints
```
POST   /api/v1/admin/auth/login
GET    /api/v1/admin/services
POST   /api/v1/admin/services
PUT    /api/v1/admin/services/:id
GET    /api/v1/admin/orders
GET    /api/v1/admin/reviews
PUT    /api/v1/admin/reviews/:id
GET    /api/v1/admin/payouts
PUT    /api/v1/admin/payouts/:id
GET    /api/v1/admin/analytics
```

### Buyer Endpoints
```
POST   /api/v1/buyer/auth/register
POST   /api/v1/buyer/auth/login
GET    /api/v1/buyer/services
POST   /api/v1/buyer/orders/price-estimate
POST   /api/v1/buyer/orders
POST   /api/v1/buyer/orders/:id/payment
GET    /api/v1/buyer/orders/:id
GET    /api/v1/buyer/reviews
PUT    /api/v1/buyer/reviews/:id
```

### Worker Endpoints
```
POST   /api/v1/worker/auth/register
POST   /api/v1/worker/auth/login
GET    /api/v1/worker/tasks
POST   /api/v1/worker/tasks/:id/accept
POST   /api/v1/worker/tasks/:id/start
POST   /api/v1/worker/tasks/:id/submit
POST   /api/v1/worker/tasks/:id/resubmit
GET    /api/v1/worker/earnings/wallet
POST   /api/v1/worker/earnings/withdraw
GET    /api/v1/worker/profile/score
```

---

## 🐛 Troubleshooting (مسائل کا حل)

### Backend Issues

**Problem: Cannot connect to database**
```bash
# Check MySQL is running
mysql --version
mysql -u root -p

# Verify connection details in .env
node check_mysql.js
```

**Problem: Port 3000 already in use**
```bash
# Find and kill process on port 3000 (Windows)
netstat -ano | findstr :3000
taskkill /PID <PID_NUMBER> /F

# Or change port in .env
PORT=3001
```

**Problem: Migration errors**
```bash
# Drop and recreate database
mysql -u root -p
DROP DATABASE ar_task_db;
CREATE DATABASE ar_task_db;

# Run migrations again
npm run migration:run
```

---

### Flutter App Issues

**Problem: Dependencies not installing**
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

**Problem: Build errors**
```bash
# Clear build cache
flutter clean

# Rebuild
flutter pub get
flutter run

# If still failing, check:
flutter doctor
```

**Problem: Cannot connect to API**
- ✅ Check backend is running on correct port
- ✅ Verify API_BASE_URL in .env
- ✅ For real device, use computer's IP address, not localhost
- ✅ Ensure firewall allows connection

```bash
# Find your computer's IP (Windows)
ipconfig

# Update .env with your IP
API_BASE_URL=http://192.168.1.100:3000/api/v1
```

**Problem: Gradle build errors**
```bash
# Clean Gradle cache
cd android
./gradlew clean

# Or use the provided script
cd ..
powershell -ExecutionPolicy Bypass -File clear_gradle_cache.ps1
```

---

## 📱 Testing Flow

### 1. Create Admin Account
```bash
cd "Task engine"
node create_admin.js
# Enter: email, password, name
```

### 2. Login to Admin App
- Open Admin App
- Login with admin credentials
- Create a service (e.g., "Instagram Follow")
- Set pricing: Buyer Price = ₹10, Margin = ₹4, Worker Reward = ₹6

### 3. Register Buyer
- Open Buyer App
- Register new buyer account
- Login

### 4. Create Campaign
- Browse services
- Select "Instagram Follow"
- Enter quantity: 10
- View price estimate: ₹100
- Create order
- Complete payment (mock gateway in dev mode)

### 5. Register Worker
- Open Worker App
- Register new worker account
- Complete profile/KYC

### 6. Complete Task
- Worker sees task in feed
- Accept task
- Start task
- Upload proof (screenshot)
- Submit

### 7. Review Submission
- Buyer App → Reviews
- View worker's submission
- Approve/Reject/Request Changes

### 8. Check Earnings
- Worker App → Wallet
- See approved earnings
- Request withdrawal

### 9. Process Payout
- Admin App → Payouts
- See withdrawal request
- Approve and mark as paid

---

## 🎯 Quick Testing Commands

```bash
# Start all services (run in separate terminals)

# Terminal 1: Backend
cd "Task engine"
npm run start:dev

# Terminal 2: Admin App
cd "Admin app"
flutter run

# Terminal 3: Buyer App
cd "Buyer app"
flutter run

# Terminal 4: Worker App
cd "Worker app"
flutter run
```

---

## 📊 Database Quick Commands

```bash
# Connect to MySQL
mysql -u root -p

# Use database
USE ar_task_db;

# View all tables
SHOW TABLES;

# Check users
SELECT * FROM users;

# Check services
SELECT * FROM services;

# Check orders
SELECT * FROM orders;

# Check tasks
SELECT * FROM tasks;

# Check earnings
SELECT * FROM earnings;

# Check withdrawals
SELECT * FROM withdrawals;
```

---

## 🔐 Default Test Credentials

### Admin
```
Email: admin@artask.com
Password: admin123
```

### Buyer (Create via app)
```
Email: buyer@test.com
Password: buyer123
Company: Test Company
```

### Worker (Create via app)
```
Email: worker@test.com
Password: worker123
Phone: +919876543210
```

---

## 📚 Documentation Files Reference

| File | Purpose |
|------|---------|
| `PROJECT_STORY_AND_ARCHITECTURE.md` | Complete system architecture |
| `VISUAL_SYSTEM_FLOW.md` | Visual flow diagrams |
| `PROJECT_STRUCTURE_URDU_GUIDE.md` | Urdu/Hindi structure guide |
| `Task engine/API_CONTRACT_ADMIN_V1.md` | Complete API documentation |
| `Admin app/ARCHITECTURE.md` | Admin app architecture |
| `Buyer app/BUILD_GUIDE.md` | Buyer app build guide |

---

## 🆘 Getting Help

1. **Check Documentation**
   - Read relevant .md files in each folder
   - Review API contracts
   - Check architecture diagrams

2. **Debug Mode**
   ```bash
   # Backend debug logs
   npm run start:dev
   
   # Flutter debug mode
   flutter run --verbose
   ```

3. **Check Logs**
   ```bash
   # Backend logs
   tail -f logs/app.log
   
   # PM2 logs
   pm2 logs
   
   # Flutter logs
   flutter logs
   ```

---

**یہ quick reference guide آپ کو project کو تیزی سے setup اور test کرنے میں مدد کرے گی!**

**यह क्विक रेफरेंस गाइड आपको प्रोजेक्ट को तेजी से सेटअप और टेस्ट करने में मदद करेगी!**
