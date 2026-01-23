# Railway Deployment Steps

## ✅ Step 1: Login to Railway
Run this command (it will open your browser):
```bash
cd server
railway login
```

## ✅ Step 2: Initialize Project
```bash
railway init
```
- Choose "Create a new project" or "Link to existing project"
- Give it a name (e.g., "appointment-booking-server")

## ✅ Step 3: Deploy
```bash
railway up
```

## ✅ Step 4: Set Environment Variables
In Railway dashboard (https://railway.app):
1. Go to your project
2. Click on the service
3. Go to "Variables" tab
4. Add these:
   - `JWT_SECRET` = (generate a random string, e.g., use: `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`)
   - `NODE_ENV` = `production`
   - `PORT` = (Railway sets this automatically, but you can set it to 5000)

## ✅ Step 5: Get Your URL
After deployment, Railway will give you a URL like:
`https://your-app-name.up.railway.app`

## ✅ Step 6: Update Flutter App (if needed)
If your URL is different from the existing one, update:
`appointment_booking_app/lib/services/api_service.dart` line 22

## ✅ Step 7: Test
Visit: `https://your-url.up.railway.app/api/health`
Should return: `{"status":"ok","message":"Server is running"}`

---

## 🎯 Quick Commands Summary
```bash
cd server
railway login          # Opens browser for login
railway init          # Initialize project
railway up            # Deploy
railway logs          # View logs
railway status        # Check deployment status
```

---

## 🔧 Troubleshooting

**Build fails:**
- Check Railway logs: `railway logs`
- Make sure `package.json` has correct scripts
- Verify TypeScript compiles: `npm run build`

**Server crashes:**
- Check environment variables are set
- Verify `JWT_SECRET` is set
- Check logs: `railway logs`

**Can't connect:**
- Wait 1-2 minutes after deployment
- Check Railway dashboard for status
- Verify the URL is correct
