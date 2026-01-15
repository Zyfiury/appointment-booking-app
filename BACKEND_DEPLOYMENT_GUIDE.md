# Backend Deployment Guide

## Quick Deployment Options

### Option 1: Railway.app (Recommended - Easiest)

1. **Sign up**: Go to https://railway.app
2. **Create new project**: Click "New Project"
3. **Deploy from GitHub**:
   - Connect your GitHub account
   - Select your repository
   - Choose the `server` folder
4. **Add PostgreSQL**:
   - Click "New" → "Database" → "PostgreSQL"
   - Railway automatically provides connection string
5. **Set environment variables**:
   - PORT (usually auto-set)
   - DATABASE_URL (from PostgreSQL service)
   - JWT_SECRET (generate a random string)
6. **Deploy**: Railway auto-deploys on git push
7. **Get URL**: Copy your app URL (e.g., `https://bookly-api.railway.app`)

**Update your Flutter app:**
```dart
// In lib/services/api_service.dart
static String get baseUrl {
  if (isProduction) {
    return 'https://bookly-api.railway.app/api'; // Your Railway URL
  }
  // ... rest of code
}
```

---

### Option 2: Render.com (Free Tier Available)

1. **Sign up**: Go to https://render.com
2. **Create new Web Service**:
   - Connect GitHub repo
   - Select `server` folder
   - Build command: `npm install`
   - Start command: `npm start`
3. **Add PostgreSQL**:
   - Create new PostgreSQL database
   - Copy connection string
4. **Set environment variables**:
   - PORT
   - DATABASE_URL
   - JWT_SECRET
5. **Deploy**: Render auto-deploys

---

### Option 3: Heroku (Classic Option)

1. **Install Heroku CLI**: https://devcenter.heroku.com/articles/heroku-cli
2. **Login**: `heroku login`
3. **Create app**: `heroku create bookly-api`
4. **Add PostgreSQL**: `heroku addons:create heroku-postgresql:hobby-dev`
5. **Set config**: `heroku config:set JWT_SECRET=your-secret`
6. **Deploy**: `git push heroku main`

---

## Database Migration

### From JSON to PostgreSQL

You'll need to update your `server/data/database.ts` to use PostgreSQL instead of JSON file.

**Install PostgreSQL driver:**
```bash
cd server
npm install pg
npm install --save-dev @types/pg
```

**Example database connection:**
```typescript
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Create tables
async function initializeDatabase() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      email VARCHAR(255) UNIQUE NOT NULL,
      password VARCHAR(255) NOT NULL,
      name VARCHAR(255) NOT NULL,
      role VARCHAR(50) NOT NULL,
      phone VARCHAR(50),
      latitude DECIMAL(10, 8),
      longitude DECIMAL(11, 8),
      address TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
  
  // Add more tables for appointments, services, etc.
}
```

---

## Environment Variables

Create a `.env` file for local development:
```
PORT=5000
DATABASE_URL=postgresql://user:password@localhost:5432/bookly
JWT_SECRET=your-super-secret-key-change-this
NODE_ENV=development
```

For production, set these in your hosting platform's dashboard.

---

## Testing Production API

After deployment:
1. Test API endpoint: `https://your-api-url.com/api/users/providers`
2. Update Flutter app with production URL
3. Test app connection
4. Monitor logs for errors

---

## SSL/HTTPS

Most hosting platforms (Railway, Render, Heroku) provide HTTPS automatically. No additional setup needed!

---

## Monitoring

- **Railway**: Built-in logs and metrics
- **Render**: Dashboard with logs
- **Heroku**: `heroku logs --tail`

---

## Cost Comparison

| Platform | Free Tier | Paid Starts At |
|----------|-----------|----------------|
| Railway | $5 credit/month | $5/month |
| Render | Free tier available | $7/month |
| Heroku | No free tier | $7/month |

**Recommendation**: Start with Railway or Render free tier, upgrade when needed.
