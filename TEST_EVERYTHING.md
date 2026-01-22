# ✅ Test Everything - Complete Verification Guide

## 🎯 Quick Test Checklist

Test in this order to verify everything works:

---

## 1️⃣ Test Railway Server is Running

### Check Server Status
1. Go to: https://railway.app
2. Find your project
3. Check **"Deployments"** tab
4. ✅ Latest deployment should show **"Active"** or **"Success"**

### Test Health Endpoint
Open in browser or use curl:
```
https://accurate-solace-app22.up.railway.app/api/health
```

**Expected:** Should return `{"status": "ok"}` or similar

**OR use PowerShell:**
```powershell
Invoke-WebRequest -Uri "https://accurate-solace-app22.up.railway.app/api/health"
```

---

## 2️⃣ Test API Endpoints

### Test 1: Register a New User
```powershell
$body = @{
    email = "test@example.com"
    password = "test123"
    name = "Test User"
    role = "customer"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://accurate-solace-app22.up.railway.app/api/auth/register" `
    -Method POST `
    -ContentType "application/json" `
    -Body $body
```

**Expected:** Returns user object with `id`, `email`, `name` (no password)

### Test 2: Login
```powershell
$body = @{
    email = "test@example.com"
    password = "test123"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://accurate-solace-app22.up.railway.app/api/auth/login" `
    -Method POST `
    -ContentType "application/json" `
    -Body $body

# Save token for next tests
$token = $response.token
Write-Host "Token: $token"
```

**Expected:** Returns `{ token: "...", user: {...} }`

### Test 3: Get Services (Public)
```powershell
Invoke-RestMethod -Uri "https://accurate-solace-app22.up.railway.app/api/services"
```

**Expected:** Returns array of services (may be empty if no services)

### Test 4: Get Services with Auth
```powershell
$headers = @{
    Authorization = "Bearer $token"
}

Invoke-RestMethod -Uri "https://accurate-solace-app22.up.railway.app/api/services" `
    -Headers $headers
```

**Expected:** Returns services array

---

## 3️⃣ Test Flutter App Connection

### Update Flutter App API URL
1. Open: `appointment_booking_app/lib/services/api_service.dart`
2. Verify it points to: `https://accurate-solace-app22.up.railway.app/api`
3. If not, update it

### Test in Flutter App
1. Run your Flutter app
2. Try to:
   - ✅ Register a new account
   - ✅ Login
   - ✅ View services
   - ✅ Create an appointment (if you're a provider)
   - ✅ Book an appointment (if you're a customer)

---

## 4️⃣ Test Key Features

### Feature Tests:

| Feature | How to Test | Expected Result |
|---------|-------------|-----------------|
| **Authentication** | Register → Login | Get JWT token |
| **Services** | View services list | See services (or empty array) |
| **Search** | Search for services | Filtered results |
| **Appointments** | Create/View appointments | Appointment created/listed |
| **Validation** | Try invalid email/password | Error message returned |
| **Rate Limiting** | Make 100+ requests quickly | Rate limit error after threshold |

---

## 5️⃣ Test Environment Variables

### Check Railway Logs
1. Go to Railway dashboard
2. Click your service
3. Go to **"Deployments"** tab
4. Click latest deployment
5. Check **"Logs"** tab
6. ✅ Should NOT see errors about missing `JWT_SECRET`

### Test JWT Works
If login returns a token, JWT_SECRET is working! ✅

---

## 6️⃣ Test Auto-Deploy (GitHub Integration)

### Make a Small Change
1. Edit any file (e.g., add a comment to `server/index.ts`)
2. Commit and push:
   ```bash
   git add .
   git commit -m "Test auto-deploy"
   git push
   ```
3. Go to Railway dashboard
4. Watch **"Deployments"** tab
5. ✅ Should see new deployment starting automatically

---

## 🚨 Common Issues & Fixes

### Issue: 404 Not Found
**Fix:** Check Railway URL is correct in Flutter app

### Issue: 401 Unauthorized
**Fix:** Check JWT_SECRET is set in Railway variables

### Issue: 500 Internal Server Error
**Fix:** 
1. Check Railway logs
2. Verify NODE_ENV=production
3. Check database file exists

### Issue: Connection Timeout
**Fix:**
1. Check Railway service is running
2. Verify deployment succeeded
3. Check if service is sleeping (free tier may sleep)

---

## 📋 Quick Test Script

I've created `TEST_API.ps1` - run it to test all endpoints automatically!

---

## ✅ Success Criteria

Everything works if:
- ✅ Health endpoint returns OK
- ✅ Can register and login
- ✅ Can get services
- ✅ Flutter app connects successfully
- ✅ No errors in Railway logs
- ✅ Auto-deploy works

---

**Run the test script or follow the manual tests above!** 🚀
