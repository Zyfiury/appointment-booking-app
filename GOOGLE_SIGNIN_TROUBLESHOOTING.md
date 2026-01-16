# 🔧 Google Sign-In Error 10 - Troubleshooting Guide

## Current Configuration

✅ **Client ID:** `621611382404-3su41a8p8bucc44leffirbva6a3eac8p.apps.googleusercontent.com`  
✅ **Package Name:** `com.bookly.app`  
✅ **SHA-1:** `C9:7E:62:45:3A:8E:5E:31:6B:03:23:5B:C4:40:16:94:7B:70:28:A8`

---

## ⚠️ Error Code 10 (DEVELOPER_ERROR) - Common Causes

### 1. OAuth Consent Screen Not Configured

**Check in Google Cloud Console:**
1. Go to: https://console.cloud.google.com
2. Your Project → APIs & Services → OAuth consent screen
3. **Verify:**
   - User Type is set (External or Internal)
   - App name is filled
   - Support email is set
   - **Status shows "Testing" or "In production"**

**If not configured:**
- Go through the OAuth consent screen setup
- Fill all required fields
- Save each step

---

### 2. Package Name Mismatch

**Verify in Google Cloud Console:**
1. APIs & Services → Credentials
2. Click on your OAuth 2.0 Client ID (Android)
3. **Check Package name:** Must be exactly `com.bookly.app`
   - No spaces
   - Correct case (lowercase)
   - No typos

**If wrong:**
- Edit the OAuth client
- Update package name to: `com.bookly.app`
- Save

---

### 3. SHA-1 Fingerprint Mismatch

**Verify in Google Cloud Console:**
1. APIs & Services → Credentials
2. Click on your OAuth 2.0 Client ID (Android)
3. **Check SHA-1:** Must be exactly:
   ```
   C9:7E:62:45:3A:8E:5E:31:6B:03:23:5B:C4:40:16:94:7B:70:28:A8
   ```

**If wrong or missing:**
- Edit the OAuth client
- Add SHA-1: `C9:7E:62:45:3A:8E:5E:31:6B:03:23:5B:C4:40:16:94:7B:70:28:A8`
- Save

---

### 4. App Not Rebuilt After Changes

**Solution:**
After making any changes to AndroidManifest.xml or strings.xml:

```bash
cd appointment_booking_app
flutter clean
flutter pub get
flutter run
```

**Important:** Use `flutter clean` - hot reload won't pick up manifest changes!

---

### 5. Google Sign-In API Not Enabled

**Check in Google Cloud Console:**
1. APIs & Services → Library
2. Search for "Google Sign-In API"
3. **Verify:** Status shows "Enabled"

**If not enabled:**
- Click on "Google Sign-In API"
- Click "ENABLE"

---

## 🔍 Step-by-Step Verification

### Step 1: Verify OAuth Client Configuration

1. Go to: https://console.cloud.google.com
2. Select your project
3. APIs & Services → Credentials
4. Find your Android OAuth client
5. **Verify:**
   - ✅ Package name: `com.bookly.app`
   - ✅ SHA-1: `C9:7E:62:45:3A:8E:5E:31:6B:03:23:5B:C4:40:16:94:7B:70:28:A8`
   - ✅ Client ID: `621611382404-3su41a8p8bucc44leffirbva6a3eac8p.apps.googleusercontent.com`

### Step 2: Verify OAuth Consent Screen

1. APIs & Services → OAuth consent screen
2. **Verify:**
   - ✅ User Type is set
   - ✅ App name is filled
   - ✅ Support email is set
   - ✅ Status is not "Not configured"

### Step 3: Verify App Configuration

1. Check `android/app/src/main/res/values/strings.xml`:
   ```xml
   <string name="default_web_client_id">621611382404-3su41a8p8bucc44leffirbva6a3eac8p.apps.googleusercontent.com</string>
   ```

2. Check `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.gms.auth.api.signin.GoogleSignInOptions.DEFAULT_SIGN_IN"
       android:value="@string/default_web_client_id" />
   ```

### Step 4: Clean Rebuild

```bash
cd appointment_booking_app
flutter clean
flutter pub get
flutter run
```

---

## 🚨 Quick Fixes

### Fix 1: Reconfigure OAuth Consent Screen

1. Go to Google Cloud Console
2. APIs & Services → OAuth consent screen
3. Complete all steps:
   - App information (name, email)
   - Scopes (default is fine)
   - Test users (optional)
   - Summary
4. Save

### Fix 2: Recreate OAuth Client

If configuration is wrong:

1. Delete the existing Android OAuth client
2. Create a new one:
   - Type: Android
   - Package: `com.bookly.app`
   - SHA-1: `C9:7E:62:45:3A:8E:5E:31:6B:03:23:5B:C4:40:16:94:7B:70:28:A8`
3. Copy the new Client ID
4. Update `strings.xml` with new Client ID
5. Rebuild app

### Fix 3: Explicitly Set Client ID in Code

If meta-data approach doesn't work, set it explicitly:

Edit `lib/services/google_auth_service.dart`:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: '621611382404-3su41a8p8bucc44leffirbva6a3eac8p.apps.googleusercontent.com',
);
```

Then rebuild.

---

## ✅ Verification Checklist

Before testing, verify:

- [ ] OAuth consent screen is configured
- [ ] Google Sign-In API is enabled
- [ ] OAuth client has correct package name: `com.bookly.app`
- [ ] OAuth client has correct SHA-1: `C9:7E:62:45:3A:8E:5E:31:6B:03:23:5B:C4:40:16:94:7B:70:28:A8`
- [ ] Client ID is in `strings.xml`
- [ ] AndroidManifest.xml has Google Sign-In meta-data
- [ ] App was rebuilt with `flutter clean && flutter run`

---

## 🎯 Most Common Issue

**90% of the time, error 10 is caused by:**
- OAuth consent screen not being fully configured
- App not being rebuilt after manifest changes

**Solution:**
1. Complete OAuth consent screen setup in Google Cloud Console
2. Run `flutter clean && flutter run`

---

## 📞 Still Not Working?

If all checks pass but still getting error 10:

1. **Wait 5-10 minutes** - Google Cloud changes can take time to propagate
2. **Check Google Cloud Console logs** - Look for any errors
3. **Try creating a new OAuth client** - Sometimes recreating fixes issues
4. **Verify you're using the correct Google account** - The account used in Google Cloud Console

---

**Follow these steps and Google Sign-In should work!** 🚀
