# 🔑 How to Get Your SHA-1 Fingerprint

You need this to configure Google Sign-In in Google Cloud Console.

---

## Method 1: Using Gradle (Recommended)

### Windows (PowerShell)

```powershell
cd appointment_booking_app\android
.\gradlew signingReport
```

### macOS/Linux

```bash
cd appointment_booking_app/android
./gradlew signingReport
```

### What to Look For

In the output, find the **debug** variant:

```
Variant: debug
Config: debug
Store: C:\Users\...\.android\debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**Copy the SHA1 value** (the long string with colons).

---

## Method 2: Using Keytool (If Gradle Doesn't Work)

### Windows

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### macOS/Linux

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### What to Look For

Find the line:
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**Copy the SHA1 value.**

---

## Method 3: Using Flutter (Easiest)

```bash
cd appointment_booking_app
flutter build apk --debug
```

Then check the build output or use keytool on the generated keystore.

---

## 📋 What to Do With SHA-1

1. **Copy the SHA-1 fingerprint** (the long hex string)
2. **Go to Google Cloud Console** → Your Project → APIs & Services → Credentials
3. **Create OAuth 2.0 Client ID** (Android type)
4. **Paste SHA-1** in the "SHA-1 certificate fingerprint" field
5. **Package name**: `com.bookly.app`
6. **Get the Client ID** and add it to `android/app/src/main/res/values/strings.xml`

---

## ⚠️ Important Notes

- **Debug SHA-1**: Use for testing/development
- **Release SHA-1**: Get from your release keystore for production
- **Format**: Should be like `AA:BB:CC:DD:EE:FF:...` (with colons)
- **Multiple SHA-1s**: You can add multiple fingerprints to one OAuth client

---

## 🎯 Quick Command Reference

**Get SHA-1 (Windows PowerShell):**
```powershell
cd appointment_booking_app\android
.\gradlew signingReport | Select-String "SHA1"
```

**Get SHA-1 (macOS/Linux):**
```bash
cd appointment_booking_app/android
./gradlew signingReport | grep SHA1
```

---

Once you have the SHA-1, follow the steps in `GOOGLE_SIGNIN_FIX.md` to complete the setup! 🚀
