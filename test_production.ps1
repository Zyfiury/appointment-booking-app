# Test App with Production API
# Run this script to test your app connected to the production backend

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Bookly - Production API Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "Error: pubspec.yaml not found. Please run this script from the appointment_booking_app directory." -ForegroundColor Red
    exit 1
}

Write-Host "Production API URL: https://accurate-solace-app22.up.railway.app/api" -ForegroundColor Yellow
Write-Host ""

# Check available devices
Write-Host "Checking available devices..." -ForegroundColor Yellow
flutter devices

Write-Host ""
Write-Host "Select a device:" -ForegroundColor Yellow
Write-Host "1. Android Emulator (if running)" -ForegroundColor White
Write-Host "2. Physical Android Device (if connected)" -ForegroundColor White
Write-Host "3. Chrome (Web)" -ForegroundColor White
Write-Host "4. Windows Desktop" -ForegroundColor White
Write-Host ""

$deviceChoice = Read-Host "Enter device number (or device ID from list above)"

if ($deviceChoice -eq "1" -or $deviceChoice -like "*emulator*") {
    $device = "emulator-5554"
} elseif ($deviceChoice -eq "2") {
    $device = Read-Host "Enter device ID"
} elseif ($deviceChoice -eq "3") {
    $device = "chrome"
} elseif ($deviceChoice -eq "4") {
    $device = "windows"
} else {
    $device = $deviceChoice
}

Write-Host ""
Write-Host "Starting app with production API on device: $device" -ForegroundColor Yellow
Write-Host "This will connect to: https://accurate-solace-app22.up.railway.app/api" -ForegroundColor Gray
Write-Host ""

flutter run -d $device --dart-define=API_URL=https://accurate-solace-app22.up.railway.app/api
