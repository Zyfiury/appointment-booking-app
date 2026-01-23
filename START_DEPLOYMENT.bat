@echo off
color 0A
echo.
echo ========================================
echo    RAILWAY 24/7 DEPLOYMENT
echo ========================================
echo.
echo This will deploy your server to Railway
echo so it runs 24/7!
echo.
pause

cd /d "%~dp0server"

echo.
echo [1/3] Checking Railway CLI...
railway --version
if %errorlevel% neq 0 (
    echo ERROR: Railway CLI not found!
    echo Please run: npm install -g @railway/cli
    pause
    exit /b 1
)

echo.
echo [2/3] Logging in to Railway...
echo.
echo IMPORTANT: A browser window will open.
echo Please sign in with your Railway account.
echo (GitHub, Google, or Email)
echo.
pause

railway login
if %errorlevel% neq 0 (
    echo.
    echo Login failed or cancelled.
    echo Please try again.
    pause
    exit /b 1
)

echo.
echo [3/3] Initializing Railway project...
echo.
railway init
if %errorlevel% neq 0 (
    echo.
    echo Init failed. You may already have a project linked.
    echo Continuing with deployment...
)

echo.
echo ========================================
echo    DEPLOYING TO RAILWAY...
echo ========================================
echo.
echo This will take 2-5 minutes...
echo.
railway up

if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo    DEPLOYMENT FAILED
    echo ========================================
    echo.
    echo Check the error messages above.
    echo You can also check: railway logs
    pause
    exit /b 1
)

echo.
echo ========================================
echo    DEPLOYMENT SUCCESSFUL!
echo ========================================
echo.
echo Next steps:
echo.
echo 1. Go to: https://railway.app
echo 2. Open your project
echo 3. Click on the service
echo 4. Go to "Variables" tab
echo 5. Add these variables:
echo.
echo    JWT_SECRET = 98b57e9ce1dd01c9e016060b9e30b6e0aa38d8341225504d634db6465288a7c6
echo    NODE_ENV = production
echo.
echo 6. Your server URL will be shown in the dashboard
echo 7. Test it: https://your-url.up.railway.app/api/health
echo.
echo ========================================
pause
