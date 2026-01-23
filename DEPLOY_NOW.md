# 🚀 Deploy to Railway - Ready to Go!

## ✅ Everything is Set Up!

I've prepared everything for you. Just follow these steps:

---

## 📋 Quick Steps:

### Option A: Run the Batch Script (Easiest)
1. Double-click: `deploy-railway.bat`
2. Follow the prompts
3. Login in browser when it opens
4. Done!

### Option B: Manual Commands

**1. Open PowerShell/Terminal in the `server` folder:**
```bash
cd C:\Users\omarz\cursor\server
```

**2. Login to Railway:**
```bash
railway login
```
- This opens your browser
- Sign in with GitHub/Google/Email
- Authorize Railway

**3. Initialize Project:**
```bash
railway init
```
- Choose: **"Create a new project"**
- Name: `appointment-booking-server`

**4. Deploy:**
```bash
railway up
```
- Wait 2-5 minutes for build and deploy

---

## 🔑 Set Environment Variables

After deployment, in Railway dashboard:

1. Go to: https://railway.app
2. Click your project → Click the service
3. Go to **"Variables"** tab
4. Click **"New Variable"** and add:

| Variable | Value |
|----------|-------|
| `JWT_SECRET` | `98b57e9ce1dd01c9e016060b9e30b6e0aa38d8341225504d634db6465288a7c6` |
| `NODE_ENV` | `production` |

**Optional (if using Stripe):**
- `STRIPE_SECRET_KEY` = your Stripe key
- `STRIPE_WEBHOOK_SECRET` = your webhook secret

---

## 🌐 Get Your Server URL

After deployment:
1. Railway dashboard shows your URL
2. Example: `https://appointment-booking-server-production.up.railway.app`
3. Copy this URL

**Test it:** Visit `https://your-url.up.railway.app/api/health`
Should return: `{"status":"ok","message":"Server is running"}`

---

## 📱 Update Flutter App (if needed)

If your Railway URL is different from the existing one:

Edit: `appointment_booking_app/lib/services/api_service.dart`
- **Line 22**: Replace with your new Railway URL

---

## ✅ Done! Your Server is Running 24/7!

### Useful Commands:
```bash
railway logs          # View live logs
railway status        # Check status
railway open          # Open dashboard
railway redeploy      # Redeploy
```

---

## 💡 Tips:

- **Free Tier**: 500 hours/month free, then may sleep. Upgrade to $5/month for always-on.
- **Auto-Deploy**: Connect GitHub repo in Railway for automatic deployments
- **Monitoring**: Check Railway dashboard for logs and metrics
- **Database**: Consider PostgreSQL for production (Railway offers free PostgreSQL)

---

## 🆘 Troubleshooting:

**Build fails:**
- Check: `railway logs`
- Verify: `npm run build` works locally

**Server crashes:**
- Check environment variables are set
- Verify JWT_SECRET is correct
- Check logs: `railway logs`

**Can't connect:**
- Wait 1-2 minutes after deployment
- Check Railway dashboard status
- Verify URL is correct

---

**Ready? Run the commands above or double-click `deploy-railway.bat`!** 🚀
