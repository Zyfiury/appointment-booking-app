# Fix Railway Deployment - Step by Step

## The Problem
Railway is trying to build from the root of your repository instead of the `server` folder where your Node.js backend is located.

## Solution: Configure Railway Service Root Directory

### Step 1: Update Railway Service Settings

1. **Go to your Railway project**: https://railway.app
2. **Click on your service** (the purple box "appointment-booking-app")
3. **Go to the "Settings" tab** (top navigation)
4. **Scroll down to "Root Directory"**
5. **Set Root Directory to**: `server`
6. **Click "Save"**

### Step 2: Change Builder (if needed)

1. Still in **Settings** tab
2. Find **"Builder"** section
3. Change from **"Railpack"** to **"Nixpacks"**
4. **Click "Save"**

### Step 3: Verify Build Settings

In the **Settings** tab, verify:
- **Root Directory**: `server`
- **Build Command**: `npm install && npm run build` (or leave empty for auto-detect)
- **Start Command**: `npm start`

### Step 4: Redeploy

1. Go back to **"Architecture"** or **"Deploy Logs"** tab
2. Click **"Redeploy"** or wait for automatic redeploy after git push
3. The build should now work!

---

## Alternative: Delete and Recreate Service

If the above doesn't work:

1. **Delete the current service** (click the service → Settings → Delete)
2. **Create a new service**:
   - Click "New" → "GitHub Repo"
   - Select your repository: `Zyfiury/appointment-booking-app`
   - **IMPORTANT**: In the service settings, set **Root Directory** to `server`
   - Railway will auto-detect Node.js and deploy

---

## What I've Added to Your Code

I've created these files to help Railway:
- `railway.json` - Railway configuration (root level)
- `server/nixpacks.toml` - Nixpacks build configuration
- `server/railway.json` - Service-specific Railway config
- Updated `server/package.json` - Added postinstall script

---

## After Successful Deployment

1. **Get your Railway URL** (e.g., `https://appointment-booking-app-production.up.railway.app`)
2. **Update your Flutter app**:
   - Open `lib/config/app_config.dart`
   - Replace the placeholder URL with your Railway URL:
     ```dart
     return 'https://your-railway-url.railway.app/api';
     ```

---

## Still Having Issues?

Check the **Build Logs** tab in Railway to see the exact error message. Common issues:
- Missing environment variables
- TypeScript compilation errors
- Missing dependencies

Let me know what error you see and I'll help fix it!
