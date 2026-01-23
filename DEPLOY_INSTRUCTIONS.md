# 🚀 Deploy to Railway - Interactive Guide

## ⚠️ Important: Railway Login Requires Browser

I can't fully automate the login (it opens your browser), but I've prepared everything. Here's what to do:

---

## 🎯 Quick Start (3 Steps)

### Step 1: Run the Deployment Script
**Double-click:** `START_DEPLOYMENT.bat`

OR manually run:
```bash
cd C:\Users\omarz\cursor\server
railway login      # Browser opens - sign in
railway init       # Create project
railway up         # Deploy!
```

### Step 2: When Browser Opens
1. Sign in to Railway (GitHub/Google/Email)
2. Authorize the application
3. Return to terminal

### Step 3: Set Environment Variables
After deployment succeeds:
1. Go to: https://railway.app
2. Open your project
3. Click the service
4. Go to **"Variables"** tab
5. Add:
   - `JWT_SECRET` = `98b57e9ce1dd01c9e016060b9e30b6e0aa38d8341225504d634db6465288a7c6`
   - `NODE_ENV` = `production`

---

## ✅ What's Already Done:

- ✅ Railway CLI installed
- ✅ Code builds successfully
- ✅ Configuration files ready
- ✅ JWT_SECRET generated
- ✅ Deployment script created

---

## 📋 Manual Commands (If Script Doesn't Work)

```bash
# Navigate to server folder
cd C:\Users\omarz\cursor\server

# Login (opens browser)
railway login

# Initialize project
railway init
# Choose: "Create a new project"
# Name: appointment-booking-server

# Deploy
railway up
```

---

## 🔍 Check Deployment Status

```bash
railway status      # Check if deployed
railway logs        # View logs
railway open        # Open dashboard
```

---

## 🌐 After Deployment

1. **Get your URL** from Railway dashboard
2. **Test it**: `https://your-url.up.railway.app/api/health`
3. **Update Flutter app** if URL changed (line 22 in `api_service.dart`)

---

## 🎉 That's It!

Your server will run 24/7 on Railway! 🚀

---

**Ready? Double-click `START_DEPLOYMENT.bat` or run the commands above!**
