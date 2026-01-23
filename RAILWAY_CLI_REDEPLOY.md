# Redeploy Using Railway CLI

Since you're having trouble finding the redeploy button in the UI, use Railway CLI instead.

## Step 1: Install Railway CLI

```powershell
npm i -g @railway/cli
```

## Step 2: Login

```powershell
railway login
```

This will open your browser to authenticate.

## Step 3: Navigate to Server Directory

```powershell
cd C:\Users\omarz\cursor\server
```

## Step 4: Link to Your Project

```powershell
railway link
```

If you have multiple projects, select the one with `accurate-solace-app22`.

## Step 5: Deploy

```powershell
railway up
```

This will:
- Build your TypeScript code
- Deploy to Railway
- Show deployment progress

## Step 6: Wait and Test

Wait 1-2 minutes for deployment to complete, then test:

```powershell
curl https://accurate-solace-app22.up.railway.app/api/stats/public
```

---

## Alternative: Force Redeploy via Settings

If CLI doesn't work, try this in Railway UI:

1. Click on "accurate-solace" service
2. Go to **Settings** tab
3. Look for **"Redeploy"** or **"Trigger Deploy"** button
4. Or change any setting (like environment variable) and save - this triggers a redeploy

---

## Why This Is Needed

Your code is correct locally, but Railway is running an old deployment that doesn't have `server/routes/stats.ts`. Redeploying will include the new file.
