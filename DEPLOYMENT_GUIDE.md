# 24/7 Server Deployment Guide

## 🚀 Quick Solutions (Recommended)

### Option 1: Railway (Easiest - Free Tier Available)
**Best for**: Quick deployment, automatic deployments, free tier

1. **Sign up**: Go to [railway.app](https://railway.app)
2. **Create New Project**:
   ```bash
   # Install Railway CLI
   npm i -g @railway/cli
   
   # Login
   railway login
   
   # Initialize project
   cd server
   railway init
   
   # Deploy
   railway up
   ```
3. **Set Environment Variables** in Railway dashboard:
   - `JWT_SECRET`
   - `STRIPE_SECRET_KEY` (if using)
   - `STRIPE_WEBHOOK_SECRET` (if using)
   - `NODE_ENV=production`
   - `PORT` (Railway sets this automatically)

4. **Update Flutter App**: The production URL is already in your code:
   ```dart
   // In api_service.dart - already configured!
   if (kReleaseMode) {
     return 'https://accurate-solace-app22.up.railway.app/api';
   }
   ```

**Pros**: 
- ✅ Free tier (500 hours/month)
- ✅ Automatic HTTPS
- ✅ Auto-deploy from GitHub
- ✅ Easy environment variables
- ✅ Built-in monitoring

**Cons**:
- ⚠️ Free tier sleeps after inactivity (can upgrade to always-on)

---

### Option 2: Render (Free Tier - Always On)
**Best for**: Free always-on hosting

1. **Sign up**: Go to [render.com](https://render.com)
2. **Create New Web Service**:
   - Connect your GitHub repo
   - Build Command: `cd server && npm install && npm run build`
   - Start Command: `cd server && npm start`
   - Environment: Node
3. **Set Environment Variables**:
   - `JWT_SECRET`
   - `NODE_ENV=production`
   - `PORT` (Render sets automatically)
4. **Update Flutter App** with Render URL

**Pros**:
- ✅ Free tier with always-on option
- ✅ Automatic HTTPS
- ✅ Auto-deploy from GitHub
- ✅ Free PostgreSQL available

**Cons**:
- ⚠️ Free tier has limitations (512MB RAM)

---

### Option 3: DigitalOcean App Platform
**Best for**: Production-ready, scalable

1. **Sign up**: Go to [digitalocean.com](https://digitalocean.com)
2. **Create App** from GitHub
3. **Configure**:
   - Build: `cd server && npm install && npm run build`
   - Run: `cd server && npm start`
4. **Add Database**: Use managed PostgreSQL

**Pros**:
- ✅ Production-ready
- ✅ Auto-scaling
- ✅ Managed databases
- ✅ $5/month minimum

---

### Option 4: VPS with PM2 (Most Control)
**Best for**: Full control, custom setup

#### Setup on Ubuntu VPS:

1. **Get a VPS** (DigitalOcean, Linode, Vultr - $5-10/month)

2. **Install Node.js**:
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

3. **Install PM2** (Process Manager):
   ```bash
   sudo npm install -g pm2
   ```

4. **Clone and Setup**:
   ```bash
   git clone <your-repo>
   cd server
   npm install
   npm run build
   ```

5. **Start with PM2**:
   ```bash
   pm2 start dist/index.js --name appointment-server
   pm2 save
   pm2 startup  # Auto-start on reboot
   ```

6. **Setup Nginx** (Reverse Proxy):
   ```bash
   sudo apt install nginx
   sudo nano /etc/nginx/sites-available/appointment-server
   ```
   
   Add:
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;
       
       location / {
           proxy_pass http://localhost:5000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```
   
   ```bash
   sudo ln -s /etc/nginx/sites-available/appointment-server /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   ```

7. **Setup SSL** (Let's Encrypt):
   ```bash
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d your-domain.com
   ```

**Pros**:
- ✅ Full control
- ✅ Always on
- ✅ Can host multiple apps
- ✅ Custom configuration

**Cons**:
- ⚠️ Requires server management
- ⚠️ Need to handle updates manually

---

## 📋 PM2 Configuration (For VPS)

Create `ecosystem.config.js` in server directory:

```javascript
module.exports = {
  apps: [{
    name: 'appointment-server',
    script: './dist/index.js',
    instances: 1,
    exec_mode: 'fork',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    autorestart: true,
    max_memory_restart: '1G',
    watch: false
  }]
};
```

Then run:
```bash
pm2 start ecosystem.config.js
pm2 save
```

---

## 🔧 Environment Variables Setup

Create `.env` file in `server/` directory:

```env
# Server
PORT=5000
NODE_ENV=production

# JWT
JWT_SECRET=your-super-secret-key-change-this-in-production

# Database (when you migrate to PostgreSQL)
DATABASE_URL=postgresql://user:password@localhost:5432/appointment_booking

# Stripe (optional)
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Redis (optional, for caching)
REDIS_URL=redis://localhost:6379
```

**Important**: Never commit `.env` to Git! Add to `.gitignore`:

```gitignore
# .env
server/.env
*.env
```

---

## 🐳 Docker Deployment (Alternative)

Create `Dockerfile` in `server/`:

```dockerfile
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy source and build
COPY . .
RUN npm run build

# Expose port
EXPOSE 5000

# Start server
CMD ["node", "dist/index.js"]
```

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  server:
    build: ./server
    ports:
      - "5000:5000"
    environment:
      - NODE_ENV=production
      - JWT_SECRET=${JWT_SECRET}
    restart: unless-stopped
    volumes:
      - ./server/data:/app/data
```

Run:
```bash
docker-compose up -d
```

---

## 📊 Monitoring & Maintenance

### PM2 Monitoring:
```bash
pm2 monit          # Real-time monitoring
pm2 logs           # View logs
pm2 restart all    # Restart all apps
pm2 status         # Check status
```

### Health Check Endpoint:
Already implemented at `/api/health` ✅

### Logging:
- PM2 handles logs automatically
- Or use services like LogRocket, Sentry

---

## 🔄 Auto-Deploy Setup (GitHub Actions)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Railway
        run: |
          npm install -g @railway/cli
          railway login --token ${{ secrets.RAILWAY_TOKEN }}
          railway up
```

---

## 💰 Cost Comparison

| Service | Free Tier | Paid Tier | Always On |
|---------|-----------|-----------|-----------|
| **Railway** | 500 hrs/month | $5/month | ✅ (paid) |
| **Render** | Free | $7/month | ✅ (free) |
| **DigitalOcean** | None | $5/month | ✅ |
| **VPS (DO/Linode)** | None | $5-10/month | ✅ |
| **Heroku** | None | $7/month | ✅ |

---

## 🎯 Recommended Setup

**For Development/Testing:**
- Use **Render** (free, always-on)

**For Production:**
- Use **Railway** or **DigitalOcean App Platform**
- Or **VPS with PM2** if you need full control

**Quick Start (Railway):**
```bash
cd server
npm i -g @railway/cli
railway login
railway init
railway up
```

---

## 📝 Next Steps

1. **Choose a hosting provider** (Railway recommended for ease)
2. **Deploy your server**
3. **Update Flutter app** with production URL
4. **Set environment variables**
5. **Test the deployment**
6. **Set up monitoring** (optional but recommended)

---

## ⚠️ Important Notes

- **Database**: JSON file won't work well in production. Migrate to PostgreSQL (see `server/SETUP_GUIDES.md`)
- **Backups**: Set up automated backups for your database
- **Monitoring**: Use PM2 or hosting platform's monitoring
- **SSL**: Always use HTTPS in production (most platforms provide this automatically)
- **Rate Limiting**: Already implemented ✅
- **Error Logging**: Set up Sentry or similar (see `server/SETUP_GUIDES.md`)

---

## 🆘 Troubleshooting

**Server crashes:**
- Check PM2 logs: `pm2 logs`
- Check hosting platform logs
- Verify environment variables

**Database issues:**
- JSON file may have permission issues
- Migrate to PostgreSQL for production

**Port issues:**
- Use environment variable `PORT` (hosting platforms set this automatically)
