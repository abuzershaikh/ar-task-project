# Buyer App Build Guide

Use this file for a repeatable APK build that avoids the disk/cache issues we hit earlier.

## Required Setup

Keep Gradle cache on `D:` so `C:` does not fill up during builds.

Set this before building:

```powershell
$env:GRADLE_USER_HOME = 'D:\AR Task Project\.gradle-home'
```

## Build Steps

From the `Buyer app` folder:

```powershell
flutter pub get
flutter build apk --release
```

If you want a clean rebuild first:

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

## APK Output Location

After a successful build, the newest APK is usually here:

```text
D:\AR Task Project\Buyer app\android\build\app\outputs\flutter-apk\app-release.apk
```

An alternate APK copy may also appear here:

```text
D:\AR Task Project\Buyer app\android\build\app\outputs\apk\release\app-release.apk
```

## Install APK On Device

If a device is connected, install the latest APK with:

```powershell
adb install -r "D:\AR Task Project\Buyer app\android\build\app\outputs\flutter-apk\app-release.apk"
```

## Notes

- Current build stack was updated to the latest compatible Android toolchain for this project.
- If a build fails again, check free space on `C:` and `D:` first.
- The APK timestamp to trust is the newest file in the `flutter-apk` folder.
