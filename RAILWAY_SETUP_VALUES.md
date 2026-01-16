# Railway Environment Variables - Quick Reference

Use these values when setting up your Railway deployment.

## 🔐 Environment Variables to Set

Go to your **backend service** in Railway → **Variables** tab → Add these:

| Variable | Value |
|----------|-------|
| `DATABASE_URL` | `postgresql://postgres:hmmAvJmnzyNvpFBHUQlsdpnhBDMsDRVW@postgres.railway.internal:5432/railway` |
| `JWT_SECRET` | `4BmPpE3+HQbt4e7plGsb5AVsAIbUk/4fuurfVd/afSo=` |
| `NODE_ENV` | `production` |
| `PORT` | (Railway sets this automatically - don't add it) |

---

## 📋 Step-by-Step Instructions

### Step 1: Add Environment Variables

1. **Go to Railway Dashboard:**
   - Visit https://railway.app
   - Open your project
   - Click on your **backend service** (Node.js app)

2. **Add Variables:**
   - Click **"Variables"** tab
   - Click **"New Variable"** for each one:

   **Variable 1: DATABASE_URL**
   - Key: `DATABASE_URL`
   - Value: `postgresql://postgres:hmmAvJmnzyNvpFBHUQlsdpnhBDMsDRVW@postgres.railway.internal:5432/railway`
   - Click **"Add"**

   **Variable 2: JWT_SECRET**
   - Key: `JWT_SECRET`
   - Value: `4BmPpE3+HQbt4e7plGsb5AVsAIbUk/4fuurfVd/afSo=`
   - Click **"Add"**

   **Variable 3: NODE_ENV**
   - Key: `NODE_ENV`
   - Value: `production`
   - Click **"Add"**

3. **Verify:**
   - You should see all 3 variables listed
   - Railway may also show `PORT` (that's automatic, don't worry about it)

### Step 2: Deploy

1. **Push to GitHub (if not already):**
   ```bash
   cd appointment_booking_app
   git add .
   git commit -m "Ready for Railway deployment with PostgreSQL"
   git push origin main
   ```

2. **Railway Auto-Deploys:**
   - Railway watches your GitHub repo
   - It will automatically start deploying when you push
   - First deployment takes 3-5 minutes

3. **Check Deployment:**
   - Go to your backend service
   - Click **"Deployments"** tab
   - Click on the latest deployment
   - Watch the logs

### Step 3: Verify Success

**Look for these in the logs:**
```
✅ Database initialized successfully
Server running on port 5000
```

**If you see errors:**
- Check that all environment variables are set correctly
- Verify `DATABASE_URL` is correct
- Check that PostgreSQL service is running

### Step 4: Verify Database Tables

1. **Go to PostgreSQL Service:**
   - Click on your PostgreSQL service in Railway
   - Click **"Data"** tab
   - Click **"Query"** button

2. **Run Query:**
   ```sql
   SELECT table_name 
   FROM information_schema.tables 
   WHERE table_schema = 'public';
   ```

3. **Expected Result:**
   You should see these tables:
   - `users`
   - `services`
   - `appointments`
   - `payments`
   - `reviews`

### Step 5: Test Your API

1. **Get Your API URL:**
   - Go to your backend service
   - Click **"Settings"** tab
   - Find **"Domains"** section
   - Copy your Railway URL (e.g., `https://your-app.railway.app`)

2. **Test Health Endpoint:**
   ```bash
   curl https://your-app.railway.app/api/health
   ```
   
   Should return:
   ```json
   {"status":"ok","message":"Server is running"}
   ```

---

## ✅ Checklist

- [ ] All 3 environment variables added to backend service
- [ ] Code pushed to GitHub
- [ ] Deployment started
- [ ] Logs show "Database initialized successfully"
- [ ] Database tables created (verified in PostgreSQL service)
- [ ] API health endpoint responds correctly
- [ ] Got your Railway API URL

---

## 🆘 Troubleshooting

### Deployment Fails

**Check:**
- All environment variables are set
- `DATABASE_URL` is correct (no typos)
- PostgreSQL service is running
- Check deployment logs for specific errors

### Database Connection Error

**Possible causes:**
- `DATABASE_URL` not set correctly
- PostgreSQL service not running
- Wrong password in connection string

**Solution:**
- Double-check `DATABASE_URL` value
- Verify PostgreSQL service is active
- Re-copy `DATABASE_URL` from PostgreSQL service if needed

### Tables Not Created

**Solution:**
- Check server logs for initialization errors
- Verify `DATABASE_URL` is correct
- Manually check database permissions

---

## 🎉 Success!

Once everything is working:
1. Update your Flutter app's API URL to your Railway URL
2. Test the full app flow
3. Your backend is now production-ready!

---

**Your Railway API URL will be:** `https://your-app-name.railway.app`

Update this in your Flutter app's `lib/config/app_config.dart` or `lib/services/api_service.dart`
