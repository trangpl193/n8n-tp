@echo off
title AI Agent Stuck Fix - Emergency Protocol
color 0A

echo.
echo ===============================================
echo   AI AGENT STUCK ISSUE - EMERGENCY FIX
echo ===============================================
echo.

echo [1] Killing stuck Node.js processes...
taskkill /f /im node.exe >nul 2>&1
taskkill /f /im npm.cmd >nul 2>&1
echo     Done.

echo.
echo [2] Checking PM2 availability...
pm2 --version >nul 2>&1
if %errorlevel% == 0 (
    echo     PM2 is available
    echo [3] Stopping any existing PM2 processes...
    pm2 stop all >nul 2>&1
    pm2 delete all >nul 2>&1
    echo     Done.
) else (
    echo     PM2 not available - will use direct method
)

echo.
echo [4] Waiting for cleanup...
timeout /t 3 /nobreak >nul

echo.
echo [5] Starting n8n in background...
start "n8n-background" /min powershell -Command "cd '%~dp0'; npm run start"

echo.
echo [6] Waiting for startup...
timeout /t 10 /nobreak >nul

echo.
echo [7] Checking if n8n is running...
netstat -an | findstr ":5678" >nul
if %errorlevel% == 0 (
    echo     SUCCESS: n8n is running on port 5678
    echo     Access: http://localhost:5678
) else (
    echo     WARNING: n8n may still be starting up
    echo     Wait 30 seconds and check http://localhost:5678
)

echo.
echo ===============================================
echo   FIX COMPLETED
echo ===============================================
echo.
echo AI Agent should now work without stuck commands.
echo Close this window and continue with AI Agent.
echo.
pause
