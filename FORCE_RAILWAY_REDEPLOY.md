# Force Railway Redeploy - Complete Guide

## The Problem
Railway is still running old code without `server/routes/stats.ts`. You need to trigger a fresh deployment.

## Solution: Railway CLI (Most Reliable)

### Step-by-Step Commands

```powershell
# 1. Install Railway CLI
npm i -g @railway/cli

# 2. Login (opens browser)
railway login

# 3. Go to your server directory
cd C:\Users\omarz\cursor\server

# 4. Link to your Railway project
railway link
# Select: "vibrant-clarity" or the project with "accurate-solace-app22"

# 5. Deploy (this forces a fresh build and deploy)
railway up
```

---

## What `railway up` Does

1. **Uploads your code** to Railway
2. **Runs build command**: `npm install && npm run build`
3. **Deploys the new version** with `server/routes/stats.ts`
4. **Shows progress** in terminal

---

## After Deployment

Wait 1-2 minutes, then test:

```powershell
curl https://accurate-solace-app22.up.railway.app/api/stats/public
```

Expected response:
```json
{
  "platform": {
    "totalProviders": 0,
    "totalCustomers": 0,
    "totalServices": 0,
    "totalAppointments": 0,
    "totalReviews": 0,
    "averageRating": 0
  },
  "categories": [],
  "geographicCoverage": {"cities": 0},
  "lastUpdated": "2026-01-21T..."
}
```

---

## Alternative: Trigger via File Change

If Railway CLI doesn't work, try making a small change to force redeploy:

1. Edit `server/index.ts`
2. Add a comment: `// Redeploy trigger`
3. Save and commit
4. Railway should auto-detect (if connected to Git) or use CLI to deploy

---

## Check Railway Logs

If deployment fails, check logs:

```powershell
railway logs
```

Look for:
- Build errors
- Missing files
- Import errors

---

## Verify Files Are Included

Make sure these files exist and are committed:

- ✅ `server/routes/stats.ts` (new file)
- ✅ `server/index.ts` (has `app.use('/api/stats', statsRoutes)`)
- ✅ `server/utils/onboarding.ts` (dependency)

All should be in your local `server/` directory.
