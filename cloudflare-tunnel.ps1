# ============================================
# 🌐 CLOUDFLARE TUNNEL STANDALONE STARTER
# ============================================
# Dedicated script for Cloudflare tunnel management

param(
    [string]$Action = "start",
    [switch]$UseService,
    [switch]$UsePM2
)

Write-Host "🌐 CLOUDFLARE TUNNEL MANAGER" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor Yellow

$tunnelName = "automation-hub-prod"
$configPath = "C:\cloudflared\config.yml"
$executablePath = "C:\cloudflared\cloudflared.exe"

function Test-TunnelPrerequisites {
    if (-not (Test-Path $executablePath)) {
        Write-Host "❌ Cloudflared not found at $executablePath" -ForegroundColor Red
        return $false
    }
    
    if (-not (Test-Path $configPath)) {
        Write-Host "❌ Config not found at $configPath" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✅ Tunnel prerequisites OK" -ForegroundColor Green
    return $true
}

function Start-Tunnel {
    Write-Host "🚀 Starting Cloudflare tunnel..." -ForegroundColor Green
    
    if (-not (Test-TunnelPrerequisites)) {
        return $false
    }
    
    # Stop existing tunnel processes
    Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    
    if ($UsePM2) {
        Write-Host "Starting tunnel with PM2..." -ForegroundColor Yellow
        try {
            pm2 start ecosystem-tunnel.config.js
            Start-Sleep -Seconds 5
            
            $status = pm2 list | Select-String "cloudflared-tunnel"
            if ($status -and $status -like "*online*") {
                Write-Host "✅ Tunnel started with PM2" -ForegroundColor Green
                return $true
            }
        } catch {
            Write-Host "⚠️ PM2 failed, trying direct start..." -ForegroundColor Yellow
        }
    }
    
    # Direct start
    Write-Host "Starting tunnel directly..." -ForegroundColor Yellow
    try {
        Start-Process -FilePath $executablePath -ArgumentList "tunnel", "--config", $configPath, "run" -WindowStyle Hidden
        Start-Sleep -Seconds 8
        
        $process = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
        if ($process) {
            Write-Host "✅ Tunnel started successfully (PID: $($process.Id))" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Failed to start tunnel" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Error starting tunnel: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Stop-Tunnel {
    Write-Host "🛑 Stopping Cloudflare tunnel..." -ForegroundColor Yellow
    
    # Stop PM2 tunnel if running
    try {
        pm2 stop cloudflared-tunnel 2>$null
        pm2 delete cloudflared-tunnel 2>$null
        Write-Host "✅ PM2 tunnel stopped" -ForegroundColor Green
    } catch {
        # PM2 not running tunnel
    }
    
    # Stop direct processes
    $processes = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
    if ($processes) {
        $processes | Stop-Process -Force
        Write-Host "✅ Tunnel processes stopped ($($processes.Count) processes)" -ForegroundColor Green
    } else {
        Write-Host "ℹ️ No tunnel processes running" -ForegroundColor Cyan
    }
}

function Show-TunnelStatus {
    Write-Host "📊 TUNNEL STATUS REPORT" -ForegroundColor Cyan
    Write-Host "=" * 40
    
    # Check PM2 status
    try {
        $pm2Status = pm2 list | Select-String "cloudflared-tunnel"
        if ($pm2Status) {
            Write-Host "PM2 Tunnel: $pm2Status" -ForegroundColor Green
        } else {
            Write-Host "PM2 Tunnel: Not running" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "PM2 Tunnel: PM2 not available" -ForegroundColor Red
    }
    
    # Check direct processes
    $processes = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "Direct Processes:" -ForegroundColor Green
        $processes | Format-Table Name, Id, CPU, WorkingSet -AutoSize
    } else {
        Write-Host "Direct Processes: None" -ForegroundColor Yellow
    }
    
    # Test connectivity
    Write-Host "`n🌐 Connectivity Test:" -ForegroundColor Cyan
    try {
        $response = Invoke-WebRequest -Uri "https://app.strangematic.com" -TimeoutSec 10 -UseBasicParsing
        Write-Host "✅ Domain accessible (Status: $($response.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "❌ Domain not accessible: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "=" * 40
}

function Test-TunnelHealth {
    Write-Host "🏥 Testing tunnel health..." -ForegroundColor Cyan
    
    $healthTests = @{
        "Process Running" = { Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue }
        "Config Exists" = { Test-Path $configPath }
        "Domain Resolves" = { 
            try { 
                [System.Net.Dns]::GetHostAddresses("app.strangematic.com") 
                return $true 
            } catch { 
                return $false 
            }
        }
        "HTTPS Response" = {
            try {
                $response = Invoke-WebRequest -Uri "https://app.strangematic.com" -TimeoutSec 5 -UseBasicParsing
                return $response.StatusCode -eq 200
            } catch {
                return $false
            }
        }
    }
    
    foreach ($test in $healthTests.GetEnumerator()) {
        $result = & $test.Value
        if ($result) {
            Write-Host "✅ $($test.Key)" -ForegroundColor Green
        } else {
            Write-Host "❌ $($test.Key)" -ForegroundColor Red
        }
    }
}

# Main execution
switch ($Action.ToLower()) {
    "start" { 
        $success = Start-Tunnel
        if ($success) {
            Show-TunnelStatus
        }
    }
    "stop" { 
        Stop-Tunnel 
        Show-TunnelStatus
    }
    "status" { 
        Show-TunnelStatus 
    }
    "health" { 
        Test-TunnelHealth 
    }
    "restart" {
        Stop-Tunnel
        Start-Sleep -Seconds 3
        $success = Start-Tunnel
        if ($success) {
            Show-TunnelStatus
        }
    }
    default {
        Write-Host "Usage: cloudflare-tunnel.ps1 -Action [start|stop|status|health|restart]" -ForegroundColor Yellow
        Write-Host "Options: -UsePM2, -UseService" -ForegroundColor Gray
    }
}
