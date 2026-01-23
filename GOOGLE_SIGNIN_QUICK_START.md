# ⚡ Google Sign-In Quick Start

## Your App Details (Copy These)

```
Package Name: com.bookly.app
SHA-1: C9:7E:62:45:3A:8E:5E:31:6B:03:23:5B:C4:40:16:94:7B:70:28:A8
```

---

## 🚀 5-Minute Setup

### 1. Google Cloud Console (2 minutes)

1. Go to: https://console.cloud.google.com
2. Create project → Name: `Bookly`
3. Enable "Google Sign-In API"
4. OAuth consent screen → External → Fill basic info → Save
5. Credentials → Create OAuth client ID → Android
   - Package: `com.bookly.app`
   - SHA-1: `C9:7E:62:45:3A:8E:5E:31:6B:03:23:5B:C4:40:16:94:7B:70:28:A8`
6. **Copy the Client ID** (looks like: `123-xxx.apps.googleusercontent.com`)

### 2. Add to App (1 minute)

Edit: `android/app/src/main/res/values/strings.xml`

Replace:
```xml
<string name="default_web_client_id">YOUR_GOOGLE_OAUTH_CLIENT_ID_HERE</string>
```

With:
```xml
<string name="default_web_client_id">PASTE_YOUR_CLIENT_ID_HERE</string>
```

### 3. Rebuild (2 minutes)

```bash
cd appointment_booking_app
flutter clean
flutter run
```

---

## ✅ Done!

Test Google Sign-In - it should work now! 🎉

For detailed instructions, see `GOOGLE_SIGNIN_COMPLETE_SETUP.md`
