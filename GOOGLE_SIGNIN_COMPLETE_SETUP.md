# 🔐 Google Sign-In Complete Setup Guide

## ✅ Your App Information

**Package Name:** `com.bookly.app`  
**SHA-1 Fingerprint:** `C9:7E:62:45:3A:8E:5E:31:6B:03:23:5B:C4:40:16:94:7B:70:28:A8`

---

## 📋 Step-by-Step Setup

### Step 1: Go to Google Cloud Console

1. Visit: https://console.cloud.google.com
2. Sign in with your Google account
3. Click the project dropdown at the top
4. Click **"NEW PROJECT"**

### Step 2: Create Project

1. **Project Name:** `Bookly App` (or any name)
2. Click **"CREATE"**
3. Wait for project to be created
4. Select the new project from the dropdown

### Step 3: Enable Google Sign-In API

1. In the left menu, go to **"APIs & Services"** → **"Library"**
2. Search for: `Google Sign-In API`
3. Click on **"Google Sign-In API"**
4. Click **"ENABLE"** button
5. Wait for it to enable

### Step 4: Configure OAuth Consent Screen

1. Go to **"APIs & Services"** → **"OAuth consent screen"**
2. **User Type:** Select **"External"** → Click **"CREATE"**

3. **App Information:**
   - App name: `Bookly`
   - User support email: (select your email)
   - App logo: (optional, skip for now)
   - App domain: (leave empty for now)
   - Developer contact information: (your email)
   - Click **"SAVE AND CONTINUE"**

4. **Scopes:**
   - Click **"SAVE AND CONTINUE"** (default scopes are fine)

5. **Test users:**
   - Click **"SAVE AND CONTINUE"** (skip for now)

6. **Summary:**
   - Review and click **"BACK TO DASHBOARD"**

### Step 5: Create OAuth Client ID

1. Go to **"APIs & Services"** → **"Credentials"**
2. Click **"+ CREATE CREDENTIALS"** at the top
3. Select **"OAuth client ID"**

4. **Application type:** Select **"Android"**

5. **Name:** `Bookly Android`

6. **Package name:** 
   ```
   com.bookly.app
   ```
   (Must match exactly!)

7. **SHA-1 certificate fingerprint:**
   ```
   C9:7E:62:45:3A:8E:5E:31:6B:03:23:5B:C4:40:16:94:7B:70:28:A8
   ```
   (Copy this exactly, with colons)

8. Click **"CREATE"**

9. **IMPORTANT:** A popup will show your **Client ID**
   - It looks like: `123456789-abcdefghijklmnop.apps.googleusercontent.com`
   - **COPY THIS CLIENT ID!** You'll need it in the next step

### Step 6: Add Client ID to Your App

1. Open: `appointment_booking_app/android/app/src/main/res/values/strings.xml`

2. Replace this line:
   ```xml
   <string name="default_web_client_id">YOUR_GOOGLE_OAUTH_CLIENT_ID_HERE</string>
   ```

3. With your actual Client ID:
   ```xml
   <string name="default_web_client_id">YOUR_CLIENT_ID_FROM_STEP_5</string>
   ```
   (Replace `YOUR_CLIENT_ID_FROM_STEP_5` with the Client ID you copied)

4. **Save the file**

### Step 7: Rebuild Your App

```bash
cd appointment_booking_app
flutter clean
flutter pub get
flutter run
```

---

## ✅ Verification

After setup:

1. **Run your app**
2. **Click "Continue with Google"**
3. **Should open Google sign-in screen**
4. **Select your Google account**
5. **Should sign in successfully!**

---

## 🚨 Troubleshooting

### Still getting error 10?

**Check:**
- ✅ Package name matches exactly: `com.bookly.app`
- ✅ SHA-1 is correct: `C9:7E:62:45:3A:8E:5E:31:6B:03:23:5B:C4:40:16:94:7B:70:28:A8`
- ✅ Client ID is in `strings.xml`
- ✅ OAuth consent screen is configured
- ✅ Google Sign-In API is enabled
- ✅ App is rebuilt after changes

### "Package name mismatch"

**Solution:** Make sure package name in Google Cloud Console is exactly `com.bookly.app` (no spaces, correct case)

### "SHA-1 not found"

**Solution:** Double-check you pasted the SHA-1 correctly with colons:
```
C9:7E:62:45:3A:8E:5E:31:6B:03:23:5B:C4:40:16:94:7B:70:28:A8
```

### Client ID not working

**Solution:**
- Make sure you copied the full Client ID
- Check it's in `strings.xml` correctly
- Rebuild the app: `flutter clean && flutter run`

---

## 📝 Quick Reference

**Your Values:**
- Package Name: `com.bookly.app`
- SHA-1: `C9:7E:62:45:3A:8E:5E:31:6B:03:23:5B:C4:40:16:94:7B:70:28:A8`
- Client ID: (Get from Google Cloud Console - Step 5)

**Files to Edit:**
- `android/app/src/main/res/values/strings.xml` - Add Client ID here

---

## 🎯 Summary

1. ✅ Create Google Cloud project
2. ✅ Enable Google Sign-In API
3. ✅ Configure OAuth consent screen
4. ✅ Create Android OAuth client with your SHA-1
5. ✅ Copy Client ID to `strings.xml`
6. ✅ Rebuild app
7. ✅ Test Google Sign-In

**Follow the steps above and Google Sign-In will work!** 🚀
