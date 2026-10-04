# Buyer App - Build & APK Generation Guide

## Prerequisites Check

Before building, ensure you have:
- ✅ Flutter SDK installed (3.0.0+)
- ✅ Android SDK installed
- ✅ Java JDK 11+
- ✅ Android Studio or VS Code

Check Flutter doctor:
```bash
flutter doctor -v
```

---

## Step 1: Generate Required Code

Some models need code generation for JSON serialization:

```bash
cd "Buyer app"

# Generate .g.dart files
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `wallet_balance_model.g.dart`
- `transaction_model.g.dart`
- `campaign_detail_model.g.dart`

**Note:** If models don't have `@JsonSerializable()` annotation, skip this step.

---

## Step 2: Clean & Get Dependencies

```bash
# Clean previous builds
flutter clean

# Get all dependencies
flutter pub get
```

---

## Step 3: Check for Errors

```bash
# Analyze code
flutter analyze

# Fix formatting (optional)
flutter format lib/
```

---

## Step 4: Build APK

### Debug APK (for testing)
```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK (for distribution)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Split APKs by CPU architecture (smaller size)
```bash
flutter build apk --split-per-abi --release
```
Generates:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit Intel)

---

## Step 5: Build App Bundle (for Play Store)

```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

---

## Troubleshooting

### Issue: "No pubspec.yaml file found"
**Solution:** Make sure you're in the "Buyer app" directory
```bash
cd "Buyer app"
```

### Issue: "SDK location not found"
**Solution:** Set ANDROID_HOME environment variable
```bash
# Windows
set ANDROID_HOME=C:\Users\YourName\AppData\Local\Android\Sdk

# Linux/Mac
export ANDROID_HOME=$HOME/Android/Sdk
```

### Issue: "Gradle build failed"
**Solution:** Clean and rebuild
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### Issue: "package:xyz not found"
**Solution:** Ensure all dependencies are in pubspec.yaml
```bash
flutter pub get
flutter pub upgrade
```

### Issue: "Code generation errors"
**Solution:** Some files may not be ready for code generation. Comment out @JsonSerializable() temporarily:
```dart
// @JsonSerializable()
class WalletBalanceModel extends WalletBalance {
  // ...
}
```

---

## Quick Commands Reference

```bash
# Navigate to project
cd "Buyer app"

# Clean
flutter clean

# Get dependencies
flutter pub get

# Analyze
flutter analyze

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build app bundle
flutter build appbundle --release

# Install on connected device
flutter install

# Run app
flutter run
```

---

## APK Locations

After successful build:

**Debug APK:**
```
Buyer app/build/app/outputs/flutter-apk/app-debug.apk
```

**Release APK:**
```
Buyer app/build/app/outputs/flutter-apk/app-release.apk
```

**Split APKs:**
```
Buyer app/build/app/outputs/flutter-apk/
├── app-armeabi-v7a-release.apk
├── app-arm64-v8a-release.apk
└── app-x86_64-release.apk
```

**App Bundle:**
```
Buyer app/build/app/outputs/bundle/release/app-release.aab
```

---

## Testing APK

### Install on Physical Device
```bash
# Connect device via USB
# Enable USB debugging on device

# Install debug APK
flutter install

# Or manually
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Install on Emulator
```bash
# Start emulator
flutter emulators --launch <emulator_id>

# Install
flutter install
```

---

## Release Signing (for Production)

### 1. Generate Keystore
```bash
keytool -genkey -v -keystore ~/marketing-pro-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias marketing-pro
```

### 2. Create key.properties
Create `android/key.properties`:
```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=marketing-pro
storeFile=<path-to-keystore>/marketing-pro-keystore.jks
```

### 3. Update build.gradle
Add to `android/app/build.gradle`:
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

---

## Common Build Errors & Fixes

### Error: "Execution failed for task ':app:mergeReleaseResources'"
**Fix:** Clean and rebuild
```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter build apk
```

### Error: "Minimum supported Gradle version is X.X"
**Fix:** Update `android/gradle/wrapper/gradle-wrapper.properties`
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
```

### Error: "SDK location not found"
**Fix:** Create `android/local.properties`:
```properties
sdk.dir=C:\\Users\\YourName\\AppData\\Local\\Android\\Sdk
```

---

## Performance Tips

1. Use `--release` mode for production
2. Use `--split-per-abi` for smaller APKs
3. Enable ProGuard/R8 (already enabled by default)
4. Use App Bundle for Play Store (better optimization)

---

## Next Steps After Build

1. Test APK on real device
2. Check app performance
3. Test all features
4. Fix any runtime issues
5. Sign APK for release
6. Upload to Play Store (if ready)

---

## Support

If build fails:
1. Check `flutter doctor`
2. Update Flutter: `flutter upgrade`
3. Clean project: `flutter clean`
4. Check Gradle logs in `android/build` folder
5. Verify all dependencies in `pubspec.yaml`

