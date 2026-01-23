# Fix Connection Timeout Issue

## Problem
The Flutter app is experiencing connection timeouts when trying to load appointments. The error shows:
- `DioException [connection timeout]`
- Request took longer than 1 minute and was aborted

## Root Cause
The app was defaulting to `localhost` URLs in debug mode, which won't work when the server is deployed on Railway.

## Solution Applied

### 1. Updated API URL Configuration
- Changed default behavior to **always use production Railway URL**
- Added `USE_LOCAL` environment variable for local development
- Production URL: `https://accurate-solace-app22.up.railway.app/api`

### 2. Optimized Timeout Settings
- **connectTimeout**: 30 seconds (connection establishment)
- **receiveTimeout**: 30 seconds (response waiting)
- **sendTimeout**: 30 seconds (request sending)
- Reduced from 60 seconds to prevent long waits

### 3. Enhanced Error Logging
- Added URL logging in error handler
- Better timeout error messages
- Shows current API URL being used

## How to Use

### Use Production API (Default)
```bash
flutter run
```
The app will automatically use: `https://accurate-solace-app22.up.railway.app/api`

### Use Local Development Server
```bash
flutter run --dart-define=USE_LOCAL=true
```
This will use localhost URLs for local development.

### Use Custom API URL
```bash
flutter run --dart-define=API_URL=https://your-custom-url.com/api
```

## Testing

1. **Run the app**: `flutter run`
2. **Check logs**: Look for `🌐 API Request:` logs to see which URL is being used
3. **Test appointments**: Try loading appointments - should work now!

## If Still Having Issues

1. **Check Network**: Ensure device has internet connection
2. **Verify Server**: Test API directly: `https://accurate-solace-app22.up.railway.app/api/health`
3. **Check Logs**: Look for the API URL in error messages
4. **Firewall**: Ensure no firewall blocking HTTPS connections

## Additional Notes

- The app now defaults to production API for reliability
- Timeouts are optimized for better user experience
- Error messages are more informative for debugging
