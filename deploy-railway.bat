@echo off
echo ========================================
echo Railway Deployment Script
echo ========================================
echo.

cd server

echo Step 1: Logging in to Railway...
echo (This will open your browser)
railway login
if %errorlevel% neq 0 (
    echo Login failed. Please try again.
    pause
    exit /b 1
)

echo.
echo Step 2: Initializing Railway project...
railway init
if %errorlevel% neq 0 (
    echo Init failed. Please check the output above.
    pause
    exit /b 1
)

echo.
echo Step 3: Deploying to Railway...
echo (This may take 2-5 minutes)
railway up
if %errorlevel% neq 0 (
    echo Deployment failed. Check the logs above.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Deployment Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Go to https://railway.app
echo 2. Open your project
echo 3. Go to Variables tab
echo 4. Add JWT_SECRET: 98b57e9ce1dd01c9e016060b9e30b6e0aa38d8341225504d634db6465288a7c6
echo 5. Add NODE_ENV: production
echo.
echo Your server URL will be shown in Railway dashboard.
echo.
pause
