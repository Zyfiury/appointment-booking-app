# Get Your Railway Public URL

## Step 1: Generate Public Domain

1. **Go to your Railway service**: Click on "accurate-solace" (or your service name)
2. **Go to the "Settings" tab**
3. **Scroll down to "Networking"** section
4. **Click "Generate Domain"** button
5. Railway will create a public URL like: `https://accurate-solace-production.up.railway.app`

## Step 2: Copy Your API URL

Your API base URL will be:
```
https://your-service-name-production.up.railway.app/api
```

**Important**: Add `/api` at the end because your backend routes are under `/api`

## Step 3: Test Your API

Open in browser or use curl:
```
https://your-service-name-production.up.railway.app/api/health
```

You should see:
```json
{"status":"ok","message":"Server is running"}
```

## Step 4: Update Flutter App

After you get your URL, I'll help you update the app configuration!

---

## Alternative: Custom Domain (Optional)

If you have a custom domain:
1. Go to Settings → Networking
2. Add your custom domain
3. Railway will provide DNS records to add
