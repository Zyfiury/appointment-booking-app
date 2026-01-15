# Fixing Emulator Storage Issues

## Problem
`INSTALL_FAILED_INSUFFICIENT_STORAGE` - The Android emulator doesn't have enough space to install the app.

## Solutions

### Solution 1: Uninstall Old App (Quick Fix)
```powershell
# Find Android SDK path (usually in AppData)
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
& "$env:ANDROID_HOME\platform-tools\adb.exe" uninstall com.bookly.app
& "$env:ANDROID_HOME\platform-tools\adb.exe" uninstall com.example.appointment_booking_app
```

### Solution 2: Increase Emulator Storage
1. Open Android Studio
2. Go to **Tools** → **Device Manager**
3. Click the **pencil icon** (Edit) on your emulator
4. Click **Show Advanced Settings**
5. Increase **Internal Storage** (e.g., from 2GB to 4GB)
6. Click **Finish** and restart emulator

### Solution 3: Wipe Emulator Data
1. Open Android Studio
2. Go to **Tools** → **Device Manager**
3. Click the **dropdown arrow** on your emulator
4. Click **Wipe Data**
5. Restart emulator

### Solution 4: Use Physical Device
Connect a physical Android device via USB:
1. Enable **Developer Options** on your phone
2. Enable **USB Debugging**
3. Connect via USB
4. Run: `flutter devices` to verify
5. Run: `flutter run -d <device-id>`

### Solution 5: Use Web/Windows Instead
Test on web or Windows desktop instead:
```powershell
# Web (Chrome)
flutter run -d chrome --dart-define=API_URL=https://accurate-solace-app22.up.railway.app/api

# Windows Desktop
flutter run -d windows --dart-define=API_URL=https://accurate-solace-app22.up.railway.app/api
```

## Quick Commands

### Check Installed Packages
```powershell
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
& "$env:ANDROID_HOME\platform-tools\adb.exe" shell pm list packages | Select-String "bookly"
```

### Clear App Data
```powershell
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
& "$env:ANDROID_HOME\platform-tools\adb.exe" shell pm clear com.bookly.app
```

### Check Available Storage
```powershell
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
& "$env:ANDROID_HOME\platform-tools\adb.exe" shell df -h
```

## Prevention
- Regularly clean up old apps from emulator
- Increase emulator storage when creating new emulators
- Use physical devices for testing when possible
