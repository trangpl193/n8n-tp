# AI Agent Stuck Fix Script
# Run this in NEW PowerShell window: powershell -ExecutionPolicy Bypass -File fix-stuck-agent.ps1

Write-Host "🚨 AI Agent Stuck Fix Protocol" -ForegroundColor Red
Write-Host "=================================" -ForegroundColor Yellow

# Step 1: Kill all node processes
Write-Host "Step 1: Killing all Node.js processes..." -ForegroundColor Cyan
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process -Name "npm" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "✅ Node processes killed" -ForegroundColor Green

# Step 2: Check PM2 processes
Write-Host "Step 2: Checking PM2 status..." -ForegroundColor Cyan
try {
    pm2 status
    Write-Host "PM2 is available" -ForegroundColor Green
} catch {
    Write-Host "⚠️ PM2 not available or not running" -ForegroundColor Yellow
}

# Step 3: Check port 5678
Write-Host "Step 3: Checking port 5678..." -ForegroundColor Cyan
$port5678 = netstat -an | Select-String ":5678"
if ($port5678) {
    Write-Host "⚠️ Port 5678 is still in use:" -ForegroundColor Yellow
    Write-Host $port5678
} else {
    Write-Host "✅ Port 5678 is free" -ForegroundColor Green
}

# Step 4: Start n8n safely
Write-Host "Step 4: Starting n8n with PM2 (background)..." -ForegroundColor Cyan
try {
    pm2 start ecosystem.config.js --silent
    Start-Sleep 5
    $status = pm2 status
    Write-Host "✅ n8n started with PM2" -ForegroundColor Green
    Write-Host $status
} catch {
    Write-Host "⚠️ PM2 start failed, using direct method..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-Command", "cd C:\Github\n8n-tp; npm run start" -WindowStyle Minimized
    Write-Host "✅ n8n started in background window" -ForegroundColor Green
}

# Step 5: Verify service
Write-Host "Step 5: Verifying n8n service..." -ForegroundColor Cyan
Start-Sleep 10
$port5678_after = netstat -an | Select-String ":5678"
if ($port5678_after) {
    Write-Host "✅ n8n is running on port 5678" -ForegroundColor Green
    Write-Host "🌐 Access: http://localhost:5678" -ForegroundColor Cyan
} else {
    Write-Host "❌ n8n not responding on port 5678" -ForegroundColor Red
}

Write-Host "=================================" -ForegroundColor Yellow
Write-Host "🎯 Fix completed!" -ForegroundColor Green
Write-Host "AI Agent should now work without stuck commands" -ForegroundColor Cyan
