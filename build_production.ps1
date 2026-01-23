# Build Production APK/AAB Script
# Run this script to build a production-ready Android app

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Bookly - Production Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "Error: pubspec.yaml not found. Please run this script from the appointment_booking_app directory." -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Cleaning previous builds..." -ForegroundColor Yellow
flutter clean

Write-Host ""
Write-Host "Step 2: Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "Step 3: Building production APK..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Gray

flutter build apk --release `
    --dart-define=PRODUCTION=true `
    --dart-define=API_URL=https://accurate-solace-app22.up.railway.app/api

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ APK built successfully!" -ForegroundColor Green
    Write-Host "Location: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Build failed. Check the error messages above." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 4: Building Android App Bundle (AAB)..." -ForegroundColor Yellow
Write-Host "AAB is required for Google Play Store submission." -ForegroundColor Gray

flutter build appbundle --release `
    --dart-define=PRODUCTION=true `
    --dart-define=API_URL=https://accurate-solace-app22.up.railway.app/api

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ AAB built successfully!" -ForegroundColor Green
    Write-Host "Location: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ AAB build failed. Check the error messages above." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test the APK on a device: flutter install --release" -ForegroundColor White
Write-Host "2. Upload the AAB to Google Play Console" -ForegroundColor White
Write-Host "3. Complete your app store listing" -ForegroundColor White
Write-Host ""
Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Cyan
Write-Host "AAB: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Cyan
Write-Host ""
