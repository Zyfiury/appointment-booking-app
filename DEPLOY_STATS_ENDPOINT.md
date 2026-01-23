# Deploy Stats Endpoint to Railway

## Issue
The `/api/stats/public` endpoint returns "Cannot GET" on Railway, even though the code is correct locally.

## Solution: Redeploy to Railway

The stats route was added to the code, but Railway needs to be redeployed to pick up the changes.

### Option 1: Git Push (Recommended)

If your Railway project is connected to Git:

```bash
# Commit the changes
git add server/routes/stats.ts server/index.ts
git commit -m "Add public stats endpoint"

# Push to trigger Railway auto-deploy
git push origin main
```

Railway will automatically detect the push and redeploy.

### Option 2: Manual Redeploy on Railway

1. Go to https://railway.app
2. Select your project
3. Go to the deployment/service
4. Click "Redeploy" or "Deploy Latest"

### Option 3: Force Redeploy via Railway CLI

```bash
# Install Railway CLI if needed
npm i -g @railway/cli

# Login
railway login

# Link to project (if not already linked)
railway link

# Deploy
railway up
```

## Verify Deployment

After redeploy, test the endpoint:

```bash
curl https://accurate-solace-app22.up.railway.app/api/stats/public
```

You should get JSON response like:
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
  "geographicCoverage": {
    "cities": 0
  },
  "lastUpdated": "2026-01-21T..."
}
```

## Check Railway Logs

If it still doesn't work:

1. Go to Railway dashboard
2. Click on your service
3. Check "Deployments" tab for build errors
4. Check "Logs" tab for runtime errors

## Common Issues

### Build Errors
- Check that `server/routes/stats.ts` exists
- Check that `server/index.ts` imports it correctly
- Verify TypeScript compiles: `npm run build` in `server/` directory

### Runtime Errors
- Check Railway logs for import errors
- Verify database connection (if using Postgres)
- Check environment variables

## Quick Test Locally First

Before deploying, test locally:

```bash
cd server
npm run build
npm start
```

Then in another terminal:
```bash
curl http://localhost:5000/api/stats/public
```

If this works locally but not on Railway, it's a deployment issue.
