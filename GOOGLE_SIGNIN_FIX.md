# 🔧 Google Sign-In Error Fix Guide

## Error: `ApiException: 10` (DEVELOPER_ERROR)

This error means Google Sign-In is not properly configured. Here's how to fix it:

---

## 🔑 Step 1: Get Your SHA-1 Fingerprint

You need to get your app's SHA-1 fingerprint to register it with Google.

### For Debug Build (Testing)

**Windows (PowerShell):**
```powershell
cd appointment_booking_app\android
.\gradlew signingReport
```

**macOS/Linux:**
```bash
cd appointment_booking_app/android
./gradlew signingReport
```

Look for output like:
```
Variant: debug
Config: debug
Store: C:\Users\...\.android\debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**Copy the SHA1 value** (the long string of hex numbers).

---

## 🌐 Step 2: Set Up Google Cloud Console

1. **Go to Google Cloud Console**
   - Visit https://console.cloud.google.com
   - Create a new project or select existing one

2. **Enable Google Sign-In API**
   - Go to "APIs & Services" → "Library"
   - Search for "Google Sign-In API"
   - Click "Enable"

3. **Create OAuth 2.0 Credentials**
   - Go to "APIs & Services" → "Credentials"
   - Click "+ CREATE CREDENTIALS" → "OAuth client ID"
   - If prompted, configure OAuth consent screen first:
     - User Type: External
     - App name: Bookly
     - Support email: your email
     - Developer contact: your email
     - Save and continue

4. **Create Android OAuth Client**
   - Application type: **Android**
   - Name: Bookly Android
   - Package name: `com.bookly.app` (must match your app's package name)
   - SHA-1 certificate fingerprint: Paste your SHA-1 from Step 1
   - Click "Create"

5. **Copy the Client ID**
   - You'll get a Client ID like: `123456789-abcdefg.apps.googleusercontent.com`
   - **Save this!** You'll need it in the next step

---

## 📱 Step 3: Add Client ID to Your App

### Option A: Add to AndroidManifest.xml (Recommended)

Add the OAuth client ID to your AndroidManifest.xml:

```xml
<meta-data
    android:name="com.google.android.gms.auth.api.signin.GoogleSignInOptions.DEFAULT_SIGN_IN"
    android:value="@string/default_web_client_id" />
```

But first, create the string resource:

1. **Create/Edit** `android/app/src/main/res/values/strings.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="default_web_client_id">YOUR_CLIENT_ID_HERE</string>
</resources>
```

Replace `YOUR_CLIENT_ID_HERE` with your OAuth client ID from Step 2.

### Option B: Configure in Code (Alternative)

Update `google_auth_service.dart` to include the client ID:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: 'YOUR_CLIENT_ID_HERE', // Add this
);
```

---

## 🔄 Step 4: Rebuild Your App

After making changes:

```bash
cd appointment_booking_app
flutter clean
flutter pub get
flutter run
```

---

## ✅ Quick Checklist

- [ ] Got SHA-1 fingerprint from `gradlew signingReport`
- [ ] Created Google Cloud project
- [ ] Enabled Google Sign-In API
- [ ] Created OAuth consent screen
- [ ] Created Android OAuth client with:
  - Package name: `com.bookly.app`
  - SHA-1 fingerprint (from debug keystore)
- [ ] Added Client ID to app (strings.xml or code)
- [ ] Rebuilt app
- [ ] Tested Google Sign-In

---

## 🧪 Testing

1. Run the app
2. Click "Continue with Google"
3. Should open Google sign-in screen
4. Select account
5. Should sign in successfully

---

## 🚨 Common Issues

### Issue: "Package name mismatch"
**Solution:** Make sure package name in Google Cloud Console matches `com.bookly.app`

### Issue: "SHA-1 not found"
**Solution:** 
- Make sure you copied the SHA-1 from the **debug** variant
- For release builds, you'll need the release keystore SHA-1

### Issue: "OAuth consent screen not configured"
**Solution:** Complete the OAuth consent screen setup in Google Cloud Console

### Issue: Still getting error 10
**Solution:**
- Double-check SHA-1 is correct (no spaces, correct format)
- Make sure Client ID is added correctly
- Clean and rebuild: `flutter clean && flutter run`

---

## 📝 For Production

When ready for production:

1. **Get Release SHA-1**
   - Build release APK
   - Get SHA-1 from release keystore
   - Add to Google Cloud Console as additional fingerprint

2. **Use Production Client ID**
   - Create separate OAuth client for production
   - Update app config with production client ID

---

## 🎯 Summary

The error happens because Google doesn't recognize your app. You need to:
1. Register your app's SHA-1 fingerprint
2. Get an OAuth client ID
3. Add the client ID to your app

Once configured, Google Sign-In will work! 🎉
