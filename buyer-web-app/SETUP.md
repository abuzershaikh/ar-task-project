# Marketing Pro - Buyer App Setup Guide

## Prerequisites

### Required Software
- **Flutter SDK**: 3.0.0 or higher
- **Dart SDK**: 2.17.0 or higher
- **Android Studio**: Latest version
- **Android SDK**: Minimum SDK 21, Target SDK 34
- **Java JDK**: 11 or higher

### Optional Tools
- **VS Code** with Flutter extension
- **Git** for version control
- **Postman** for API testing

## Installation Steps

### 1. Clone Repository
```bash
git clone <repository-url>
cd "Buyer app"
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Configure Environment

#### Update API Base URL
Edit `lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = 'https://your-api-domain.com/v1';
```

#### Configure Razorpay (Payment Gateway)
```dart
static const String razorpayKey = 'rzp_test_YOUR_KEY_HERE';
```

For production:
```dart
static const String razorpayKey = 'rzp_live_YOUR_KEY_HERE';
```

### 4. Firebase Setup (Optional - for notifications)

#### Download google-services.json
1. Go to Firebase Console
2. Create/Select your project
3. Add Android app with package name: `com.buy.taskpost.marketing`
4. Download `google-services.json`
5. Place in `android/app/`

#### Update build.gradle files

`android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

`android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 5. Android Configuration

#### Update Application ID (if needed)
`android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        applicationId "com.buy.taskpost.marketing"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

#### Update App Name
Already configured in `AndroidManifest.xml`:
```xml
<application
    android:label="Marketing Pro"
    ...>
```

### 6. Generate Code (if using code generation)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Running the App

### Debug Mode
```bash
# List devices
flutter devices

# Run on connected device
flutter run

# Run with specific device
flutter run -d <device-id>

# Hot reload: Press 'r'
# Hot restart: Press 'R'
# Quit: Press 'q'
```

### Release Mode (Testing)
```bash
flutter run --release
```

## Building APK

### Debug APK
```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Split APKs (smaller size)
```bash
flutter build apk --split-per-abi
```
Generates separate APKs for:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit Intel)

### App Bundle (for Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

## Code Signing (Production)

### 1. Generate Keystore
```bash
keytool -genkey -v -keystore ~/marketing-pro-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias marketing-pro
```

### 2. Create key.properties
Create `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=marketing-pro
storeFile=/path/to/marketing-pro-keystore.jks
```

### 3. Update build.gradle
`android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 4. Build Signed APK
```bash
flutter build apk --release
```

## Testing

### Run Unit Tests
```bash
flutter test
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Run Integration Tests
```bash
flutter test integration_test/
```

## Troubleshooting

### Common Issues

#### 1. Build Fails
```bash
flutter clean
flutter pub get
flutter build apk
```

#### 2. Gradle Issues
```bash
cd android
./gradlew clean
cd ..
flutter build apk
```

#### 3. SDK License Not Accepted
```bash
flutter doctor --android-licenses
```

#### 4. Hot Reload Not Working
- Stop app and run again
- Or press 'R' for hot restart

#### 5. Package Version Conflicts
```bash
flutter pub upgrade --major-versions
```

#### 6. Network Issues
- Check `baseUrl` in `app_constants.dart`
- Verify API server is running
- Check device internet connection

#### 7. Authentication Issues
- Clear app data
- Check token storage
- Verify API credentials

## Development Tips

### Enable Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Performance Profiling
```bash
flutter run --profile
```

### Analyze Code
```bash
flutter analyze
```

### Format Code
```bash
flutter format .
```

### Check Dependencies
```bash
flutter pub outdated
```

### Update Dependencies
```bash
flutter pub upgrade
```

## Environment-Specific Configuration

### Development
```dart
// app_constants.dart
static const String baseUrl = 'http://localhost:3000/v1';
```

### Staging
```dart
static const String baseUrl = 'https://staging-api.taskpost.com/v1';
```

### Production
```dart
static const String baseUrl = 'https://api.taskpost.com/v1';
```

Consider using **flutter_dotenv** for environment variables:

1. Add dependency:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

2. Create `.env` files:
```
# .env.development
BASE_URL=http://localhost:3000/v1

# .env.production
BASE_URL=https://api.taskpost.com/v1
```

3. Load in main.dart:
```dart
await dotenv.load(fileName: ".env.production");
```

## CI/CD Setup

### GitHub Actions Example
Create `.github/workflows/flutter.yml`:
```yaml
name: Flutter CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.10.0'
    - run: flutter pub get
    - run: flutter test
    - run: flutter build apk --release
    - uses: actions/upload-artifact@v3
      with:
        name: release-apk
        path: build/app/outputs/flutter-apk/app-release.apk
```

## Play Store Publishing

### 1. Build App Bundle
```bash
flutter build appbundle --release
```

### 2. Create Play Store Listing
- App name: Marketing Pro
- Short description
- Full description
- Screenshots (phone, tablet)
- Feature graphic
- App icon

### 3. Upload AAB
- Go to Google Play Console
- Create new release
- Upload `app-release.aab`
- Fill in release notes
- Submit for review

### 4. Required Assets
- Icon: 512x512 PNG
- Feature Graphic: 1024x500 PNG
- Screenshots: At least 2
- Privacy Policy URL
- Content rating questionnaire

## Monitoring & Analytics

### Crashlytics Setup
```yaml
dependencies:
  firebase_crashlytics: ^3.4.0
```

### Analytics Setup
```yaml
dependencies:
  firebase_analytics: ^10.7.0
```

## Support

For issues:
- Check logs: `flutter logs`
- Enable verbose: `flutter run -v`
- Check issues: GitHub Issues
- Contact: support@taskpost.com

## Next Steps

After setup:
1. Run the app and test login
2. Create a test campaign
3. Test payment flow
4. Review submissions
5. Check analytics

## Useful Commands

```bash
# Check Flutter installation
flutter doctor -v

# List connected devices
flutter devices

# Clean build
flutter clean

# Get packages
flutter pub get

# Run app
flutter run

# Build APK
flutter build apk --release

# Build AAB
flutter build appbundle --release

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format .
```
