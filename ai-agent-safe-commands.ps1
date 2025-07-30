# AI Agent Safe Commands
# Quick status checks that don't hang terminal sessions

function Check-N8nStatus {
    Write-Host "🔍 n8n Status Check" -ForegroundColor Cyan

    # Check port 5678
    $port = netstat -an | Select-String ":5678" | Select-Object -First 1
    if ($port) {
        Write-Host "✅ Port 5678: ACTIVE" -ForegroundColor Green
        Write-Host "   $port"
    } else {
        Write-Host "❌ Port 5678: NOT ACTIVE" -ForegroundColor Red
    }

    # Check PM2 status (quick)
    try {
        $pm2Status = pm2 jlist 2>$null | ConvertFrom-Json
        if ($pm2Status.Length -gt 0) {
            $n8nApp = $pm2Status | Where-Object { $_.name -eq "strangematic-hub" }
            if ($n8nApp) {
                Write-Host "✅ PM2: $($n8nApp.pm2_env.status)" -ForegroundColor Green
                Write-Host "   Restarts: $($n8nApp.pm2_env.restart_time)"
            } else {
                Write-Host "⚠️ PM2: No strangematic-hub process" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "⚠️ PM2: Not available" -ForegroundColor Yellow
    }

    # Check node processes
    $nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
    if ($nodeProcesses) {
        Write-Host "✅ Node processes: $($nodeProcesses.Count)" -ForegroundColor Green
    } else {
        Write-Host "❌ Node processes: None" -ForegroundColor Red
    }
}

function Start-N8nSafe {
    Write-Host "🚀 Starting n8n (Safe Mode)" -ForegroundColor Cyan

    # Kill existing processes first
    Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep 2

    # Start with PM2 if available
    try {
        pm2 start ecosystem.config.js --silent
        Start-Sleep 5
        Write-Host "✅ Started with PM2" -ForegroundColor Green
    } catch {
        # Fallback to background process
        Start-Process powershell -ArgumentList "-Command", "cd C:\Github\n8n-tp; npm run start" -WindowStyle Minimized
        Start-Sleep 10
        Write-Host "✅ Started in background" -ForegroundColor Green
    }

    Check-N8nStatus
}

function Stop-N8nSafe {
    Write-Host "🛑 Stopping n8n (Safe Mode)" -ForegroundColor Cyan

    # Stop PM2 first
    try {
        pm2 stop strangematic-hub --silent 2>$null
        pm2 delete strangematic-hub --silent 2>$null
        Write-Host "✅ PM2 processes stopped" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ PM2 not available" -ForegroundColor Yellow
    }

    # Kill node processes
    Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "npm" -ErrorAction SilentlyContinue | Stop-Process -Force

    Start-Sleep 2
    Write-Host "✅ All processes killed" -ForegroundColor Green
    Check-N8nStatus
}

# Quick aliases
function status { Check-N8nStatus }
function start { Start-N8nSafe }
function stop { Stop-N8nSafe }

Write-Host "🎯 AI Agent Safe Commands Loaded" -ForegroundColor Green
Write-Host "Available commands:" -ForegroundColor Cyan
Write-Host "  status  - Quick status check"
Write-Host "  start   - Safe n8n startup"
Write-Host "  stop    - Safe n8n shutdown"
Write-Host "  Check-N8nStatus, Start-N8nSafe, Stop-N8nSafe"
