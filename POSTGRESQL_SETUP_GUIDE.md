# PostgreSQL Setup Guide

Complete guide for setting up PostgreSQL for your appointment booking app, both locally and in production.

---

## 📋 Table of Contents

1. [Local Development Setup](#local-development-setup)
2. [Railway Setup (Production)](#railway-setup-production)
3. [Render Setup (Production)](#render-setup-production)
4. [Environment Variables](#environment-variables)
5. [Testing the Connection](#testing-the-connection)
6. [Troubleshooting](#troubleshooting)

---

## 🖥️ Local Development Setup

### Option 1: Install PostgreSQL Locally

#### Windows

1. **Download PostgreSQL:**
   - Go to https://www.postgresql.org/download/windows/
   - Download the installer from EnterpriseDB
   - Run the installer

2. **Installation Steps:**
   - Choose installation directory (default is fine)
   - Select components: PostgreSQL Server, pgAdmin 4, Command Line Tools
   - Set data directory (default: `C:\Program Files\PostgreSQL\16\data`)
   - **Set a password for the `postgres` user** (remember this!)
   - Set port (default: 5432)
   - Choose locale (default is fine)

3. **Create Database:**
   - Open **pgAdmin 4** (installed with PostgreSQL)
   - Connect to server (password is what you set during installation)
   - Right-click "Databases" → "Create" → "Database"
   - Name: `bookly` (or any name you prefer)
   - Click "Save"

4. **Get Connection String:**
   ```
   DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/bookly
   ```
   Replace `YOUR_PASSWORD` with the password you set during installation.

#### macOS

1. **Using Homebrew (Recommended):**
   ```bash
   # Install Homebrew if you don't have it
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   
   # Install PostgreSQL
   brew install postgresql@16
   
   # Start PostgreSQL service
   brew services start postgresql@16
   ```

2. **Create Database:**
   ```bash
   # Connect to PostgreSQL
   psql postgres
   
   # Create database
   CREATE DATABASE bookly;
   
   # Create a user (optional, or use default postgres user)
   CREATE USER bookly_user WITH PASSWORD 'your_password';
   GRANT ALL PRIVILEGES ON DATABASE bookly TO bookly_user;
   
   # Exit
   \q
   ```

3. **Get Connection String:**
   ```
   DATABASE_URL=postgresql://postgres@localhost:5432/bookly
   ```
   Or if you created a user:
   ```
   DATABASE_URL=postgresql://bookly_user:your_password@localhost:5432/bookly
   ```

#### Linux (Ubuntu/Debian)

1. **Install PostgreSQL:**
   ```bash
   sudo apt update
   sudo apt install postgresql postgresql-contrib
   ```

2. **Start PostgreSQL:**
   ```bash
   sudo systemctl start postgresql
   sudo systemctl enable postgresql
   ```

3. **Create Database:**
   ```bash
   # Switch to postgres user
   sudo -u postgres psql
   
   # Create database
   CREATE DATABASE bookly;
   
   # Create user (optional)
   CREATE USER bookly_user WITH PASSWORD 'your_password';
   GRANT ALL PRIVILEGES ON DATABASE bookly TO bookly_user;
   
   # Exit
   \q
   ```

4. **Get Connection String:**
   ```
   DATABASE_URL=postgresql://postgres@localhost:5432/bookly
   ```

### Option 2: Use Docker (Easier Alternative)

If you have Docker installed, this is the easiest way:

1. **Run PostgreSQL Container:**
   ```bash
   docker run --name bookly-postgres \
     -e POSTGRES_PASSWORD=your_password \
     -e POSTGRES_DB=bookly \
     -p 5432:5432 \
     -d postgres:16
   ```

2. **Get Connection String:**
   ```
   DATABASE_URL=postgresql://postgres:your_password@localhost:5432/bookly
   ```

3. **Stop/Start Container:**
   ```bash
   # Stop
   docker stop bookly-postgres
   
   # Start
   docker start bookly-postgres
   
   # Remove (if needed)
   docker rm bookly-postgres
   ```

### Set Local Environment Variable

**Windows (PowerShell):**
```powershell
# For current session
$env:DATABASE_URL="postgresql://postgres:your_password@localhost:5432/bookly"

# Or create .env file in server folder
# DATABASE_URL=postgresql://postgres:your_password@localhost:5432/bookly
```

**macOS/Linux:**
```bash
# For current session
export DATABASE_URL="postgresql://postgres:your_password@localhost:5432/bookly"

# Or add to ~/.bashrc or ~/.zshrc for permanent
echo 'export DATABASE_URL="postgresql://postgres:your_password@localhost:5432/bookly"' >> ~/.bashrc
source ~/.bashrc
```

**Or create `.env` file in `server/` folder:**
```env
DATABASE_URL=postgresql://postgres:your_password@localhost:5432/bookly
PORT=5000
JWT_SECRET=your-secret-key
NODE_ENV=development
```

---

## 🚂 Railway Setup (Production)

Railway is the easiest option for production deployment. Here's the step-by-step guide:

### Step 1: Add PostgreSQL Service

1. **Go to your Railway project:**
   - Visit https://railway.app
   - Open your project (or create a new one)

2. **Add PostgreSQL:**
   - Click **"+ New"** button
   - Select **"Database"** → **"Add PostgreSQL"**
   - Railway will automatically provision a PostgreSQL database

3. **Get Connection String:**
   - Click on the PostgreSQL service
   - Go to **"Variables"** tab
   - Find `DATABASE_URL` - Railway automatically sets this!
   - Copy the value (it looks like: `postgresql://postgres:password@hostname:5432/railway`)

### Step 2: Link to Your Backend Service

1. **Connect Backend to Database:**
   - Go to your backend service (the Node.js app)
   - Click **"Variables"** tab
   - Railway should automatically add `DATABASE_URL` from the PostgreSQL service
   - If not, click **"New Variable"** and add:
     - Key: `DATABASE_URL`
     - Value: (copy from PostgreSQL service's `DATABASE_URL`)

2. **Add Other Environment Variables:**
   - `JWT_SECRET`: Generate a random string (e.g., use `openssl rand -base64 32`)
   - `NODE_ENV`: `production`
   - `PORT`: Railway sets this automatically

### Step 3: Deploy

1. **Push to GitHub:**
   ```bash
   git add .
   git commit -m "Ready for Railway deployment"
   git push origin main
   ```

2. **Railway Auto-Deploys:**
   - Railway watches your GitHub repo
   - On push, it automatically:
     - Builds your app
     - Runs `npm install`
     - Runs `npm run build` (from postinstall script)
     - Starts with `npm start`
     - Connects to PostgreSQL using `DATABASE_URL`

3. **Check Logs:**
   - Go to your backend service
   - Click **"Deployments"** tab
   - Click on the latest deployment
   - View logs - you should see:
     ```
     ✅ Database initialized successfully
     Server running on port 5000
     ```

### Step 4: Verify Database Tables

1. **Connect to Railway PostgreSQL:**
   - Go to PostgreSQL service
   - Click **"Data"** tab
   - Click **"Query"** button
   - Run this query:
     ```sql
     SELECT table_name 
     FROM information_schema.tables 
     WHERE table_schema = 'public';
     ```
   - You should see: `users`, `services`, `appointments`, `payments`, `reviews`

---

## 🌐 Render Setup (Production)

Render is another great option with a free tier.

### Step 1: Create PostgreSQL Database

1. **Sign up/Login:**
   - Go to https://render.com
   - Sign up or log in

2. **Create Database:**
   - Click **"New +"** → **"PostgreSQL"**
   - Name: `bookly-db` (or any name)
   - Database: `bookly` (or any name)
   - User: `bookly_user` (or any name)
   - Region: Choose closest to you
   - Plan: Free tier is fine for testing
   - Click **"Create Database"**

3. **Get Connection String:**
   - Click on your database
   - Go to **"Info"** tab
   - Find **"Internal Database URL"** (for Render services)
   - Or **"External Database URL"** (for external connections)
   - Copy the connection string

### Step 2: Create Web Service

1. **Create Web Service:**
   - Click **"New +"** → **"Web Service"**
   - Connect your GitHub repository
   - Select the `server` folder as root directory

2. **Configure Build:**
   - **Name:** `bookly-api` (or any name)
   - **Environment:** `Node`
   - **Build Command:** `npm install && npm run build`
   - **Start Command:** `npm start`
   - **Plan:** Free tier is fine

3. **Add Environment Variables:**
   - Scroll to **"Environment Variables"**
   - Click **"Add Environment Variable"**
   - Add:
     - `DATABASE_URL`: (paste from PostgreSQL service)
     - `JWT_SECRET`: (generate random string)
     - `NODE_ENV`: `production`
   - Click **"Create Web Service"**

### Step 3: Deploy

1. **Render Auto-Deploys:**
   - Render automatically deploys on git push
   - First deployment takes 5-10 minutes
   - Subsequent deployments are faster

2. **Check Logs:**
   - Go to your web service
   - Click **"Logs"** tab
   - You should see:
     ```
     ✅ Database initialized successfully
     Server running on port 10000
     ```

### Step 4: Verify Database

1. **Connect via Render Dashboard:**
   - Go to PostgreSQL service
   - Click **"Info"** tab
   - Use **"psql"** command or **"Connect"** button
   - Run:
     ```sql
     \dt
     ```
   - Should list all tables

---

## 🔐 Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host:5432/db` |
| `JWT_SECRET` | Secret for JWT tokens | `your-super-secret-key` |
| `NODE_ENV` | Environment mode | `development` or `production` |
| `PORT` | Server port | `5000` (auto-set on Railway/Render) |

### Connection String Format

```
postgresql://[user]:[password]@[host]:[port]/[database]
```

**Components:**
- `user`: Database username (usually `postgres`)
- `password`: Database password
- `host`: Database hostname (`localhost` for local, provided by Railway/Render for production)
- `port`: Database port (usually `5432`)
- `database`: Database name (e.g., `bookly`)

### Example Connection Strings

**Local:**
```
postgresql://postgres:mypassword@localhost:5432/bookly
```

**Railway:**
```
postgresql://postgres:abc123@containers-us-west-123.railway.app:5432/railway
```

**Render:**
```
postgresql://bookly_user:xyz789@dpg-abc123-a.oregon-postgres.render.com/bookly
```

---

## ✅ Testing the Connection

### Test Locally

1. **Start Your Server:**
   ```bash
   cd server
   npm install
   npm run dev
   ```

2. **Check Console Output:**
   - You should see:
     ```
     ✅ Database initialized successfully
     Server running on port 5000
     ```
   - If you see errors, check the troubleshooting section below

3. **Test API Endpoint:**
   ```bash
   # Health check
   curl http://localhost:5000/api/health
   
   # Should return:
   # {"status":"ok","message":"Server is running"}
   ```

4. **Test Database:**
   ```bash
   # Connect to PostgreSQL
   psql -U postgres -d bookly
   
   # List tables
   \dt
   
   # Check users table
   SELECT * FROM users;
   
   # Exit
   \q
   ```

### Test on Railway/Render

1. **Check Deployment Logs:**
   - Look for: `✅ Database initialized successfully`
   - No errors about connection

2. **Test API:**
   ```bash
   # Replace with your Railway/Render URL
   curl https://your-app.railway.app/api/health
   ```

3. **Check Database:**
   - Use Railway/Render's database dashboard
   - Query tables to verify they exist

---

## 🔧 Troubleshooting

### Error: "DATABASE_URL not set"

**Solution:**
- Make sure `DATABASE_URL` is set in your environment
- For local: Create `.env` file in `server/` folder
- For Railway/Render: Check environment variables in dashboard

### Error: "Connection refused" or "ECONNREFUSED"

**Possible Causes:**
1. PostgreSQL not running locally
   - **Windows:** Check Services → PostgreSQL
   - **macOS:** `brew services start postgresql@16`
   - **Linux:** `sudo systemctl start postgresql`

2. Wrong host/port
   - Check connection string
   - Default port is 5432

3. Firewall blocking connection
   - Check firewall settings

### Error: "password authentication failed"

**Solution:**
- Verify password in connection string
- Reset password if needed:
  ```bash
  # Windows (pgAdmin) or command line
  ALTER USER postgres WITH PASSWORD 'new_password';
  ```

### Error: "database does not exist"

**Solution:**
- Create the database:
  ```sql
  CREATE DATABASE bookly;
  ```

### Error: "relation does not exist" (tables missing)

**Solution:**
- Tables should be created automatically on first startup
- Check server logs for initialization errors
- Manually run migration if needed (shouldn't be necessary)

### Railway/Render: "Build failed"

**Possible Causes:**
1. Missing dependencies
   - Check `package.json` has all required packages
   - Verify `postinstall` script runs `npm run build`

2. TypeScript compilation errors
   - Check build logs for specific errors
   - Fix TypeScript errors in code

3. Missing environment variables
   - Ensure `DATABASE_URL` is set
   - Check all required variables are present

### Tables Not Created Automatically

**Solution:**
1. Check server logs for initialization errors
2. Verify `DATABASE_URL` is correct
3. Check database permissions
4. Manually verify migration file exists: `server/data/migrations.ts`

---

## 📝 Quick Reference

### Local Development Checklist

- [ ] PostgreSQL installed and running
- [ ] Database `bookly` created
- [ ] `.env` file created in `server/` folder
- [ ] `DATABASE_URL` set correctly
- [ ] Server starts without errors
- [ ] Tables created automatically
- [ ] API endpoints respond correctly

### Production Deployment Checklist

- [ ] PostgreSQL service created (Railway/Render)
- [ ] `DATABASE_URL` environment variable set
- [ ] `JWT_SECRET` environment variable set
- [ ] `NODE_ENV` set to `production`
- [ ] Code pushed to GitHub
- [ ] Deployment successful
- [ ] Database tables created
- [ ] API health check passes

---

## 🆘 Need More Help?

1. **Check Server Logs:**
   - Local: Console output
   - Railway: Deployment logs
   - Render: Service logs

2. **Verify Connection String:**
   - Test with `psql` command line tool
   - Use connection string format above

3. **Check Database Permissions:**
   - Ensure user has CREATE TABLE permissions
   - Check database exists

4. **Common Issues:**
   - SSL connection issues: Check `ssl` option in connection pool
   - Connection timeout: Increase `connectionTimeoutMillis`
   - Pool exhaustion: Increase `max` connections

---

## 🎉 Success Indicators

You'll know everything is working when:

✅ Server starts without errors  
✅ Logs show: `✅ Database initialized successfully`  
✅ Tables exist in database (`users`, `services`, `appointments`, `payments`, `reviews`)  
✅ API health endpoint returns: `{"status":"ok","message":"Server is running"}`  
✅ You can register/login users  
✅ Appointments can be created  

---

**That's it!** Your PostgreSQL database is now set up and ready to use. 🚀
