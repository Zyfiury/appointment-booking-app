@echo off
color 0B
echo.
echo ========================================
echo    PUSH TO GITHUB & RAILWAY SETUP
echo ========================================
echo.

cd /d "%~dp0"

echo [Step 1] Checking Git status...
git status --short
echo.

echo [Step 2] Do you have a GitHub repository?
echo.
echo If YES: Enter your GitHub repository URL
echo Example: https://github.com/yourusername/appointment-booking-app.git
echo.
echo If NO: 
echo 1. Go to https://github.com/new
echo 2. Create a new repository
echo 3. Don't initialize with README
echo 4. Copy the repository URL
echo.
set /p GITHUB_URL="Enter GitHub repository URL (or press Enter to skip): "

if "%GITHUB_URL%"=="" (
    echo.
    echo Skipping GitHub setup.
    echo You can set it up later with:
    echo   git remote add origin YOUR_GITHUB_URL
    echo   git push -u origin main
    goto :railway_setup
)

echo.
echo [Step 3] Adding GitHub remote...
git remote remove origin 2>nul
git remote add origin %GITHUB_URL%
if %errorlevel% neq 0 (
    echo ERROR: Failed to add remote. Check your URL.
    pause
    exit /b 1
)

echo.
echo [Step 4] Renaming branch to main...
git branch -M main

echo.
echo [Step 5] Pushing to GitHub...
echo This may ask for your GitHub credentials.
git push -u origin main

if %errorlevel% neq 0 (
    echo.
    echo Push failed. You may need to:
    echo 1. Authenticate with GitHub (use Personal Access Token)
    echo 2. Or use GitHub Desktop
    echo.
    echo See GITHUB_PUSH_GUIDE.md for help
    pause
    exit /b 1
)

echo.
echo ========================================
echo    SUCCESS! Code pushed to GitHub!
echo ========================================
echo.

:railway_setup
echo.
echo ========================================
echo    RAILWAY SETUP
echo ========================================
echo.
echo Next steps:
echo.
echo 1. Go to: https://railway.app
echo 2. Sign in and find your project
echo 3. Click your project
echo 4. Go to "Settings" tab
echo 5. Under "Source", click "Connect GitHub"
echo 6. Select your repository
echo 7. Railway will auto-deploy!
echo.
echo 8. Go to "Variables" tab and verify:
echo    - JWT_SECRET = 98b57e9ce1dd01c9e016060b9e30b6e0aa38d8341225504d634db6465288a7c6
echo    - NODE_ENV = production
echo.
echo ========================================
pause
