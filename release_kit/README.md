# AR Task Worker App — Release Signing Kit

This directory contains the release signing credentials and configurations for the Worker App. By using this setup, you do not need to repeatedly change the keys inside the codebase.

## Signing Details
- **Keystore File:** `worker-release-key.jks`
- **Keystore Password:** `artaskworkerpass`
- **Key Alias:** `upload`
- **Key Password:** `artaskworkerpass`
- **Configuration File:** `key.properties` (placed in `Worker app/android/key.properties`)

### Keystore Fingerprints
- **SHA-1:** `9E:76:30:47:41:18:F3:AA:0B:E0:A3:B3:88:3B:29:A0:6B:29:23:89`
- **SHA-256:** `53:32:07:AA:0C:2F:C3:54:3A:02:2A:62:C1:C3:51:11:40:0C:75:A0:B1:A4:E6:00:6D:F5:A7:A7:A8:91:0E:AA`

## Files in this Kit
1. **`worker-release-key.jks`**: The actual JKS keystore file used to sign the APK/AAB.
2. **`key.properties`**: A backup of the properties configuration mapping the keystore credentials.

---

## Instructions for Building Release Version

To build a release APK, make sure the files are configured correctly in the project (this is already set up in the codebase):

1. **Keystore Location**: The keystore file `worker-release-key.jks` must be present inside the `Worker app/android/app/` directory.
2. **Config File Location**: The `key.properties` file must be present inside the `Worker app/android/` directory.

### Commands to Build:
Open your terminal in the `Worker app` directory and run:

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build Release APK
flutter build apk --release

# OR Build Release App Bundle (for Play Store)
flutter build appbundle --release
```

The output APK will be generated at:
`Worker app/android/build/app/outputs/flutter-apk/app-release.apk`
