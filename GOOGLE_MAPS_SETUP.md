# Google Maps Setup Guide

## Why the Map is Not Loading

The map shows a black screen because **Google Maps requires an API key** to work. Without it, the map cannot load.

## Quick Setup (5 minutes)

### Step 1: Get Google Maps API Key

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Sign in with your Google account

2. **Create a New Project** (or select existing)
   - Click "Select a project" → "New Project"
   - Name it "Appointment Booking App"
   - Click "Create"

3. **Enable Maps SDK for Android**
   - Go to "APIs & Services" → "Library"
   - Search for "Maps SDK for Android"
   - Click on it → Click "Enable"

4. **Create API Key**
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "API Key"
   - Copy the API key (looks like: `AIzaSy...`)

5. **Restrict API Key (Recommended)**
   - Click on your new API key
   - Under "Application restrictions" → Select "Android apps"
   - Click "Add an item"
   - Enter your package name: `com.example.appointment_booking_app`
   - Get SHA-1 fingerprint:
     ```powershell
     cd appointment_booking_app\android
     .\gradlew signingReport
     ```
     Look for "SHA1:" in the output
   - Paste SHA-1 fingerprint
   - Click "Save"

### Step 2: Add API Key to App

1. **Open AndroidManifest.xml**
   - File: `appointment_booking_app/android/app/src/main/AndroidManifest.xml`

2. **Replace the placeholder**
   - Find: `android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"`
   - Replace with: `android:value="YOUR_ACTUAL_API_KEY"`

3. **Example:**
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"/>
   ```

### Step 3: Rebuild App

```powershell
cd appointment_booking_app
flutter clean
flutter run
```

## Free Tier Limits

- **$200 free credit per month**
- ~28,000 map loads per month
- More than enough for development/testing

## Troubleshooting

### Map Still Not Loading?

1. **Check API Key**
   - Make sure it's correct in AndroidManifest.xml
   - No extra spaces or quotes

2. **Check API is Enabled**
   - Google Cloud Console → APIs & Services → Enabled APIs
   - Make sure "Maps SDK for Android" is enabled

3. **Check Billing**
   - Google Cloud requires a billing account (but you get $200 free credit)
   - Go to "Billing" → Link a payment method

4. **Check Restrictions**
   - If you restricted the API key, make sure:
     - Package name matches
     - SHA-1 fingerprint is correct

5. **Check Logs**
   ```powershell
   flutter run -v
   ```
   Look for "Google Maps API" errors

### Common Errors

**"API key not valid"**
- Check API key is correct
- Make sure Maps SDK is enabled

**"This API project is not authorized"**
- Enable Maps SDK for Android in Google Cloud Console

**"Billing not enabled"**
- Add a payment method (you still get $200 free)

## Testing Without API Key

If you want to test the app without Google Maps:

1. **Comment out the map screen** temporarily
2. **Or use a placeholder** showing "Map coming soon"
3. **The rest of the app will work fine**

## Production Setup

For production:
1. Use a restricted API key (Android app restriction)
2. Monitor usage in Google Cloud Console
3. Set up billing alerts
4. Consider using different keys for dev/prod

## Need Help?

- Google Maps Documentation: https://developers.google.com/maps/documentation/android-sdk/start
- Flutter Google Maps: https://pub.dev/packages/google_maps_flutter
