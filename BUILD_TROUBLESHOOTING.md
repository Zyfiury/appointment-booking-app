# Build Troubleshooting Guide

## If Build is Stuck

### Solution 1: Wait (First Time Build)
- First build with new dependencies can take **5-15 minutes**
- Google Maps, Stripe, Geolocator need to download native libraries
- **Just wait** - it's downloading and compiling

### Solution 2: Cancel and Retry
1. Press `Ctrl+C` to cancel
2. Run: `flutter clean`
3. Run: `flutter pub get`
4. Run: `flutter run` again

### Solution 3: Check Internet Connection
- Ensure stable internet (dependencies are downloading)
- If behind proxy, configure Gradle proxy settings

### Solution 4: Increase Gradle Memory
Already configured in `gradle.properties`:
```
org.gradle.jvmargs=-Xmx8G
```

### Solution 5: Build with Verbose Output
```powershell
flutter run -v
```
This shows what's happening during build.

### Solution 6: Build APK Instead (Faster)
```powershell
flutter build apk --debug
```
Then install manually if needed.

## Common Issues

### Android Licenses
If you see license errors:
```powershell
flutter doctor --android-licenses
```
Accept all licenses.

### Gradle Daemon Stuck
Kill Gradle processes:
- Windows: Task Manager → End "java.exe" processes
- Or restart computer

### Network Timeout
If downloads fail:
1. Check firewall/antivirus
2. Try different network
3. Use VPN if needed

## Quick Fix Commands

```powershell
# Stop current build (Ctrl+C first)
cd appointment_booking_app
flutter clean
flutter pub get
flutter run
```

## Expected Build Time
- **First build**: 5-15 minutes (downloading dependencies)
- **Subsequent builds**: 2-5 minutes
- **Hot reload**: Instant

## What's Being Downloaded
- Google Maps SDK (~50MB)
- Stripe SDK (~30MB)
- Geolocator native libs (~20MB)
- Other dependencies (~100MB total)

**Total first download: ~200MB**
