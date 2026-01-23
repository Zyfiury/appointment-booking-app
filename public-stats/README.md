# Bookly Public Stats Website

A public-facing website showing aggregated, anonymized statistics about the Bookly platform.

## Deployment

### Option A: Vercel (Recommended - Free)

1. **Install Vercel CLI:**
   ```bash
   npm i -g vercel
   ```

2. **Deploy:**
   ```bash
   cd public-stats
   vercel
   ```

3. **Follow prompts:**
   - Link to existing project or create new
   - Deploy to production

4. **Get URL:** `https://bookly-stats.vercel.app` (or your custom domain)

### Option B: Netlify (Free)

1. **Drag & Drop:**
   - Go to https://app.netlify.com
   - Drag the `public-stats` folder to the deploy area
   - Get instant URL

2. **Or use CLI:**
   ```bash
   npm i -g netlify-cli
   cd public-stats
   netlify deploy --prod
   ```

### Option C: GitHub Pages (Free)

1. **Create GitHub repo:**
   - Create new repo: `bookly-public-stats`
   - Push `index.html` to repo

2. **Enable GitHub Pages:**
   - Go to repo Settings → Pages
   - Select branch (usually `main`)
   - Save

3. **Get URL:** `https://yourusername.github.io/bookly-public-stats`

## Customization

### Update API URL

Edit `index.html` and change:
```javascript
const API_URL = 'https://accurate-solace-app22.up.railway.app/api/stats/public';
```

### Update Colors

Edit the CSS gradients in `index.html`:
```css
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
```

### Add Custom Domain

1. **Vercel/Netlify:** Add custom domain in project settings
2. **Update API URL** if needed (CORS)
3. **SSL** is automatically handled

## API Endpoint

The website fetches data from:
- **Endpoint:** `GET /api/stats/public`
- **Rate Limited:** Yes (100 req/15 min via general rate limit)
- **Cached:** 5 minutes server-side cache
- **No Auth Required:** Public endpoint

## Features

- ✅ Real-time statistics
- ✅ Auto-refresh every 5 minutes
- ✅ Responsive design
- ✅ Error handling with retry
- ✅ Category breakdown
- ✅ Geographic coverage
- ✅ Mobile-friendly

## Privacy

- Only aggregated, anonymized data
- No personal information
- No provider-specific metrics
- Safe for public display
