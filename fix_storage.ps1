# Script to fix insufficient storage on Android emulator
# This will uninstall the existing app to free up space

Write-Host "Attempting to uninstall app from emulator..." -ForegroundColor Yellow

# Try to find adb in common locations
$adbPaths = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe",
    "$env:ANDROID_HOME\platform-tools\adb.exe",
    "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe"
)

$adb = $null
foreach ($path in $adbPaths) {
    if (Test-Path $path) {
        $adb = $path
        Write-Host "Found ADB at: $adb" -ForegroundColor Green
        break
    }
}

if (-not $adb) {
    Write-Host "ADB not found in common locations." -ForegroundColor Red
    Write-Host "Please manually uninstall the app from the emulator:" -ForegroundColor Yellow
    Write-Host "1. Open the emulator" -ForegroundColor Cyan
    Write-Host "2. Go to Settings > Apps" -ForegroundColor Cyan
    Write-Host "3. Find 'appointment_booking_app'" -ForegroundColor Cyan
    Write-Host "4. Tap it and select 'Uninstall'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or find your Android SDK location and run:" -ForegroundColor Yellow
    Write-Host "  <SDK_PATH>\platform-tools\adb.exe uninstall com.example.appointment_booking_app" -ForegroundColor Cyan
    exit 1
}

# Check if emulator is connected
$devices = & $adb devices
if ($devices -notmatch "emulator") {
    Write-Host "No emulator detected. Please start your emulator first." -ForegroundColor Red
    exit 1
}

# Uninstall the app
Write-Host "Uninstalling com.example.appointment_booking_app..." -ForegroundColor Yellow
& $adb uninstall com.example.appointment_booking_app

if ($LASTEXITCODE -eq 0) {
    Write-Host "App uninstalled successfully!" -ForegroundColor Green
    Write-Host "You can now run 'flutter run' again." -ForegroundColor Green
} else {
    Write-Host "Uninstall completed (app may not have been installed)." -ForegroundColor Yellow
    Write-Host "You can now try running 'flutter run' again." -ForegroundColor Green
}
