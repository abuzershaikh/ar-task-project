# Admin App Build and Copy Script
# یہ script Admin app build کرکے E:\pc2\pc2 gradel build میں copy کرے گی

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Admin App Build & Copy Script" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Target directory and Gradle Home
$targetDir = "E:\pc2\pc2 gradel build"
$env:GRADLE_USER_HOME = "E:\pc2\pc2 gradel build\.gradle"
$appName = "AdminApp-EarnPost"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

Write-Host "Step 1: Cleaning previous build..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter clean failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Clean completed" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter pub get failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Dependencies installed" -ForegroundColor Green
Write-Host ""

Write-Host "Step 3: Building APK (Release)..." -ForegroundColor Yellow
Write-Host "This may take several minutes..." -ForegroundColor Cyan
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Build completed successfully" -ForegroundColor Green
Write-Host ""

Write-Host "Step 4: Creating target directory..." -ForegroundColor Yellow
if (!(Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Write-Host "✓ Directory created: $targetDir" -ForegroundColor Green
} else {
    Write-Host "✓ Directory already exists: $targetDir" -ForegroundColor Green
}
Write-Host ""

Write-Host "Step 5: Copying APK to target location..." -ForegroundColor Yellow
$sourceApk = "build\app\outputs\flutter-apk\app-release.apk"
$targetApk = "$targetDir\$appName-$timestamp.apk"
$latestApk = "$targetDir\$appName-LATEST.apk"

if (Test-Path $sourceApk) {
    # Copy with timestamp
    Copy-Item $sourceApk $targetApk -Force
    Write-Host "✓ APK copied with timestamp: $targetApk" -ForegroundColor Green
    
    # Copy as LATEST
    Copy-Item $sourceApk $latestApk -Force
    Write-Host "✓ APK copied as LATEST: $latestApk" -ForegroundColor Green
    
    # Show file info
    $fileInfo = Get-Item $targetApk
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "APK Location: $targetDir" -ForegroundColor White
    Write-Host "File Name: $appName-$timestamp.apk" -ForegroundColor White
    Write-Host "File Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor White
    Write-Host "Latest APK: $appName-LATEST.apk" -ForegroundColor White
    Write-Host "======================================" -ForegroundColor Cyan
    
} else {
    Write-Host "✗ APK file not found at: $sourceApk" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Opening target directory..." -ForegroundColor Yellow
Start-Process explorer.exe $targetDir
