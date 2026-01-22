# Quick 24/7 Deployment - 5 Minutes

## 🚀 Fastest Option: Railway (Recommended)

Your app already has Railway configured! Just deploy:

### Step 1: Install Railway CLI
```bash
npm install -g @railway/cli
```

### Step 2: Login
```bash
railway login
```

### Step 3: Deploy
```bash
cd server
railway init
railway up
```

### Step 4: Set Environment Variables
In Railway dashboard → Variables:
- `JWT_SECRET` = (generate a random string)
- `NODE_ENV` = `production`

### Step 5: Get Your URL
Railway will give you a URL like: `https://your-app.up.railway.app`

### Step 6: Update Flutter App (Optional)
If you want to use a different URL, update `appointment_booking_app/lib/services/api_service.dart` line 22.

**Done!** Your server is now running 24/7! 🎉

---

## 🆓 Free Alternative: Render

1. Go to [render.com](https://render.com)
2. Sign up (free)
3. Click "New +" → "Web Service"
4. Connect your GitHub repo
5. Settings:
   - **Build Command**: `cd server && npm install && npm run build`
   - **Start Command**: `cd server && npm start`
   - **Environment**: `Node`
6. Add environment variables:
   - `JWT_SECRET`
   - `NODE_ENV=production`
7. Deploy!

**Free tier includes**: Always-on hosting, HTTPS, auto-deploy from GitHub

---

## 💻 Local Server (Your Computer) - Not 24/7

If you want to run it on your computer (but it won't be 24/7 unless your computer is always on):

### Option A: PM2 (Process Manager)
```bash
cd server
npm install -g pm2
npm run build
pm2 start dist/index.js --name appointment-server
pm2 save
pm2 startup  # Auto-start on reboot
```

### Option B: Keep Terminal Open
Just run:
```bash
cd server
npm run dev
```
(But this stops when you close terminal or computer sleeps)

---

## 📊 Comparison

| Method | Cost | Always On | Setup Time |
|--------|------|-----------|------------|
| **Railway** | Free/$5 | ✅ | 5 min |
| **Render** | Free | ✅ | 10 min |
| **PM2 (VPS)** | $5-10/mo | ✅ | 30 min |
| **Local (PM2)** | Free | ❌ | 5 min |

---

## 🎯 Recommendation

**For quick deployment**: Use **Railway** (you already have the config!)
**For free always-on**: Use **Render**
**For production**: Use **Railway** or **DigitalOcean**

---

## ⚠️ Important Notes

1. **JSON Database**: The current JSON file database won't work well in production. Consider migrating to PostgreSQL (see `server/SETUP_GUIDES.md`)

2. **Environment Variables**: Never commit secrets! Railway/Render handle this securely.

3. **HTTPS**: Both Railway and Render provide free HTTPS automatically.

4. **Monitoring**: Railway and Render provide built-in monitoring and logs.

---

## 🔗 Your Current Setup

I noticed your Flutter app already points to:
```
https://accurate-solace-app22.up.railway.app/api
```

This means you might already have a Railway deployment! Check:
- Railway dashboard: https://railway.app
- Your existing deployments

If you already have it deployed, just make sure it's running and update environment variables if needed.
