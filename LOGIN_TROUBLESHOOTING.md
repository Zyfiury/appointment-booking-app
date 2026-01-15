# 🔐 Login Troubleshooting Guide

## Quick Fix: Use Production API

If you're having login issues, the app might be trying to connect to a local server that isn't running. **Use the production API instead:**

```powershell
cd appointment_booking_app
flutter run --dart-define=API_URL=https://accurate-solace-app22.up.railway.app/api
```

---

## Common Issues & Solutions

### Issue 1: "Cannot connect to server"
**Problem:** App is trying to connect to `http://10.0.2.2:5000/api` (local server) but server isn't running.

**Solution:** Use production API:
```powershell
flutter run --dart-define=API_URL=https://accurate-solace-app22.up.railway.app/api
```

---

### Issue 2: "Invalid credentials"
**Problem:** Wrong email/password or user doesn't exist.

**Solution:**
1. Make sure you've registered an account first
2. Check the email/password you're using
3. Try registering a new account

---

### Issue 3: "Connection timeout"
**Problem:** Network issue or server is down.

**Solution:**
1. Check your internet connection
2. Verify Railway backend is running: https://accurate-solace-app22.up.railway.app/api
3. Try again

---

## Check Debug Logs

After adding the fixes, you'll see detailed logs in the console:

- `🔐 Attempting login for: email@example.com` - Login attempt
- `🌐 API Base URL: ...` - Which API it's connecting to
- `✅ Login successful` - Success
- `❌ Login error: ...` - Error details

**Look for these in your terminal/console when you try to login!**

---

## Test Steps

1. **Run with production API:**
   ```powershell
   flutter run --dart-define=API_URL=https://accurate-solace-app22.up.railway.app/api
   ```

2. **Try to login** - Check the console for debug messages

3. **If it still fails**, check:
   - Do you have an account? (Try registering first)
   - Are you using the correct email/password?
   - Check the error message in the app (red snackbar)

---

## Register First (If Needed)

If you don't have an account yet:
1. Click "Sign Up" on the login screen
2. Fill in your details
3. Choose "Customer" or "Provider"
4. Register
5. Then try logging in

---

## Still Not Working?

Check the console output for:
- `❌ API Error:` - Shows connection issues
- `❌ Login error:` - Shows authentication errors
- `❌ Login exception:` - Shows unexpected errors

Share the error message and I'll help fix it!
