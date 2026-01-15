# 🗺️ Google Maps Troubleshooting Guide

## Issue: Blank Map (No Tiles Showing)

If your map shows but is blank (beige/empty), here are the fixes:

### Fix 1: Check Google Maps API Key Restrictions

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** > **Credentials**
3. Click on your API key
4. Under **Application restrictions**, make sure:
   - **Android apps** is selected
   - Your app's package name is added: `com.bookly.app`
   - Your SHA-1 fingerprint is added

**To get SHA-1 fingerprint:**
```powershell
cd appointment_booking_app\android
.\gradlew signingReport
```
Look for `SHA1:` in the output and add it to Google Cloud Console.

### Fix 2: Enable Required APIs

Make sure these APIs are enabled in Google Cloud Console:
- ✅ **Maps SDK for Android**
- ✅ **Maps SDK for iOS** (if building for iOS)
- ✅ **Geocoding API**
- ✅ **Places API** (optional, for better search)

### Fix 3: Check API Key in AndroidManifest

Verify the API key is correct in:
`android/app/src/main/AndroidManifest.xml`

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

### Fix 4: Check Billing

Google Maps requires a billing account (but has free tier):
1. Go to Google Cloud Console
2. Check if billing is enabled
3. Even with free tier, billing must be enabled

### Fix 5: Test API Key

Test your API key works:
```bash
# Replace YOUR_API_KEY with your actual key
curl "https://maps.googleapis.com/maps/api/geocode/json?address=London&key=YOUR_API_KEY"
```

If you get an error, the API key has issues.

---

## Issue: Map Shows But No Markers

### Fix 1: Check Location Permissions

The app needs location permissions:
1. Go to Android Settings > Apps > Bookly
2. Check **Permissions**
3. Enable **Location** permission

### Fix 2: Check Provider Data

Make sure providers have location data:
- Providers need `latitude` and `longitude` set
- Check the backend database for provider locations

### Fix 3: Use Location Button

Tap the **target icon** (📍) in the top right to:
- Get your current location
- Load nearby providers
- Center the map

---

## Issue: Map Not Loading At All

### Fix 1: Check Internet Connection

Maps require internet to load tiles.

### Fix 2: Check API Key Format

Make sure the API key in `AndroidManifest.xml` is:
- Not wrapped in quotes incorrectly
- Not missing any characters
- The correct key from Google Cloud Console

### Fix 3: Rebuild the App

Sometimes changes to `AndroidManifest.xml` require a full rebuild:

```powershell
cd appointment_booking_app
flutter clean
flutter pub get
flutter run
```

---

## Debug Steps

1. **Check Console Logs:**
   Look for these messages:
   - `🗺️ Map created successfully` - Map initialized
   - `📍 Current location: ...` - Location found
   - `✅ Loaded X providers` - Providers loaded
   - `📷 Moving camera to: ...` - Camera positioned

2. **Test Location:**
   - Tap the location button (📍)
   - Check if it asks for permission
   - Check if map centers on your location

3. **Test Providers:**
   - Check if providers have location data
   - Check backend API response
   - Verify providers are being loaded

---

## Common Errors

### Error: "Map Not Available"
- **Fix:** Check API key in AndroidManifest.xml
- **Fix:** Verify API key restrictions allow your app

### Error: "Location Permission Denied"
- **Fix:** Enable location permission in app settings
- **Fix:** Grant permission when prompted

### Error: "No providers found"
- **Fix:** Check if providers have location data
- **Fix:** Increase search radius
- **Fix:** Check backend API is working

---

## Quick Test

1. **Restart the app** (hot restart: `R` in terminal)
2. **Open Map screen**
3. **Tap location button** (📍)
4. **Check console logs** for debug messages
5. **Verify map tiles load** (should see roads/buildings)

---

## Still Not Working?

1. Check Google Cloud Console for API key errors
2. Verify billing is enabled
3. Check AndroidManifest.xml syntax
4. Rebuild the app completely
5. Check console logs for specific errors
