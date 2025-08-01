# ============================================
# 🚀 STRANGEMATIC AUTOMATION HUB - MASTER STARTUP
# ============================================
# Complete orchestrated startup for n8n domain deployment
# Handles: PostgreSQL → Cloudflare Tunnel → n8n PM2 → Health Checks

param(
    [switch]$SkipHealthCheck,
    [switch]$QuickStart,
    [int]$TimeoutSeconds = 180
)

Write-Host "🚀 STRANGEMATIC AUTOMATION HUB - MASTER STARTUP" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "Target Domain: https://app.strangematic.com" -ForegroundColor Cyan
Write-Host "Startup Mode: " -NoNewline
if ($QuickStart) { Write-Host "QUICK START" -ForegroundColor Yellow } else { Write-Host "FULL ORCHESTRATION" -ForegroundColor Green }
Write-Host "=" * 60 -ForegroundColor Green

# Global variables
$script:errors = @()
$script:warnings = @()
$script:startTime = Get-Date

# ============================================
# HELPER FUNCTIONS
# ============================================

function Write-Status {
    param([string]$Message, [string]$Status = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    switch ($Status) {
        "SUCCESS" { Write-Host "✅ [$timestamp] $Message" -ForegroundColor Green }
        "ERROR"   { Write-Host "❌ [$timestamp] $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "⚠️ [$timestamp] $Message" -ForegroundColor Yellow }
        "INFO"    { Write-Host "ℹ️ [$timestamp] $Message" -ForegroundColor Cyan }
        "STEP"    { Write-Host "🔄 [$timestamp] $Message" -ForegroundColor Magenta }
    }
}

function Test-AdminPrivileges {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Status "Restarting with Administrator privileges..." "WARNING"
        $scriptPath = $MyInvocation.MyCommand.Path
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptPath`"")
        if ($SkipHealthCheck) { $arguments += "-SkipHealthCheck" }
        if ($QuickStart) { $arguments += "-QuickStart" }
        Start-Process PowerShell -ArgumentList $arguments -Verb RunAs
        exit
    }
    Write-Status "Running with Administrator privileges" "SUCCESS"
}

function Test-Prerequisites {
    Write-Status "Checking system prerequisites..." "STEP"
    
    # Check PostgreSQL
    $pgService = Get-Service -Name "PostgreSQL*" -ErrorAction SilentlyContinue
    if ($pgService -and $pgService.Status -eq "Running") {
        Write-Status "PostgreSQL service is running" "SUCCESS"
    } else {
        Write-Status "PostgreSQL service not found or not running" "ERROR"
        $script:errors += "PostgreSQL not ready"
        return $false
    }
    
    # Check cloudflared
    if (Test-Path "C:\cloudflared\cloudflared.exe") {
        Write-Status "Cloudflared executable found" "SUCCESS"
    } else {
        Write-Status "Cloudflared not found at C:\cloudflared\cloudflared.exe" "ERROR"
        $script:errors += "Cloudflared not installed"
        return $false
    }
    
    # Check cloudflared config
    if (Test-Path "C:\cloudflared\config.yml") {
        Write-Status "Cloudflared configuration found" "SUCCESS"
    } else {
        Write-Status "Cloudflared config not found at C:\cloudflared\config.yml" "ERROR"
        $script:errors += "Cloudflared not configured"
        return $false
    }
    
    # Check ecosystem configs
    if (Test-Path "ecosystem-stable.config.js") {
        Write-Status "n8n ecosystem configuration found" "SUCCESS"
    } else {
        Write-Status "ecosystem-stable.config.js not found" "ERROR"
        $script:errors += "n8n ecosystem config missing"
        return $false
    }
    
    # Check .env.production
    if (Test-Path ".env.production") {
        Write-Status "Environment configuration found" "SUCCESS"
    } else {
        Write-Status ".env.production not found" "ERROR"
        $script:errors += "Environment config missing"
        return $false
    }
    
    return $true
}

function Stop-AllServices {
    Write-Status "Stopping existing services..." "STEP"
    
    # Stop PM2
    try {
        pm2 kill | Out-Null
        Start-Sleep -Seconds 2
        Write-Status "PM2 daemon stopped" "SUCCESS"
    } catch {
        Write-Status "PM2 was not running" "INFO"
    }
    
    # Stop cloudflared processes
    try {
        Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue | Stop-Process -Force
        Write-Status "Cloudflared processes stopped" "SUCCESS"
    } catch {
        Write-Status "No cloudflared processes running" "INFO"
    }
    
    # Stop n8n processes
    try {
        Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {$_.CommandLine -like "*n8n*"} | Stop-Process -Force
        Write-Status "n8n processes stopped" "SUCCESS"
    } catch {
        Write-Status "No n8n processes running" "INFO"
    }
    
    Start-Sleep -Seconds 3
}

function Start-CloudflareTunnel {
    Write-Status "Starting Cloudflare tunnel..." "STEP"
    
    try {
        # Start tunnel using PM2
        if (Test-Path "ecosystem-tunnel.config.js") {
            pm2 start ecosystem-tunnel.config.js | Out-Null
            Start-Sleep -Seconds 5
            
            # Check if tunnel started
            $tunnelProcess = pm2 list | Select-String "cloudflared-tunnel"
            if ($tunnelProcess -and $tunnelProcess -like "*online*") {
                Write-Status "Cloudflare tunnel started with PM2" "SUCCESS"
                return $true
            }
        }
        
        # Fallback: Start tunnel directly
        Write-Status "Fallback: Starting tunnel directly..." "WARNING"
        Start-Process -FilePath "C:\cloudflared\cloudflared.exe" -ArgumentList "tunnel", "--config", "C:\cloudflared\config.yml", "run" -WindowStyle Hidden
        Start-Sleep -Seconds 10
        
        $tunnelProcess = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
        if ($tunnelProcess) {
            Write-Status "Cloudflare tunnel started directly" "SUCCESS"
            return $true
        } else {
            Write-Status "Failed to start Cloudflare tunnel" "ERROR"
            $script:errors += "Tunnel startup failed"
            return $false
        }
    } catch {
        Write-Status "Error starting tunnel: $($_.Exception.Message)" "ERROR"
        $script:errors += "Tunnel error: $($_.Exception.Message)"
        return $false
    }
}

function Start-N8nProduction {
    Write-Status "Starting n8n production..." "STEP"
    
    try {
        # Load environment variables
        Write-Status "Loading production environment..." "INFO"
        Get-Content ".env.production" | ForEach-Object {
            if ($_ -match "^([^#][^=]+)=(.*)$") {
                $name = $matches[1].Trim()
                $value = $matches[2].Trim()
                [Environment]::SetEnvironmentVariable($name, $value, "Process")
            }
        }
        
        # Start n8n with PM2
        pm2 start ecosystem-stable.config.js --env production | Out-Null
        Start-Sleep -Seconds 15
        
        # Check PM2 status
        $n8nProcess = pm2 list | Select-String "strangematic-hub"
        if ($n8nProcess -and $n8nProcess -like "*online*") {
            Write-Status "n8n started successfully with PM2" "SUCCESS"
            return $true
        } else {
            Write-Status "n8n failed to start with PM2" "ERROR"
            $script:errors += "n8n PM2 startup failed"
            return $false
        }
    } catch {
        Write-Status "Error starting n8n: $($_.Exception.Message)" "ERROR"
        $script:errors += "n8n error: $($_.Exception.Message)"
        return $false
    }
}

function Test-DatabaseConnection {
    Write-Status "Testing database connection..." "STEP"
    
    try {
        $dbHost = "localhost"
        $dbPort = 5432
        
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($dbHost, $dbPort)
        $tcpClient.Close()
        
        Write-Status "Database connection successful" "SUCCESS"
        return $true
    } catch {
        Write-Status "Database connection failed: $($_.Exception.Message)" "ERROR"
        $script:errors += "Database connection failed"
        return $false
    }
}

function Test-LocalhostAccess {
    Write-Status "Testing localhost access..." "STEP"
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5678" -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Status "Localhost access successful (Status: $($response.StatusCode))" "SUCCESS"
            return $true
        }
    } catch {
        Write-Status "Localhost access failed: $($_.Exception.Message)" "ERROR"
        $script:errors += "Localhost access failed"
        return $false
    }
}

function Test-DomainAccess {
    Write-Status "Testing domain access..." "STEP"
    
    try {
        # Wait a bit more for tunnel to fully establish
        Start-Sleep -Seconds 15
        
        $response = Invoke-WebRequest -Uri "https://app.strangematic.com" -TimeoutSec 20 -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Status "Domain access successful (Status: $($response.StatusCode))" "SUCCESS"
            return $true
        }
    } catch {
        Write-Status "Domain access failed: $($_.Exception.Message)" "WARNING"
        $script:warnings += "Domain may still be initializing"
        return $false
    }
}

function Show-SystemStatus {
    Write-Status "Generating system status report..." "STEP"
    
    Write-Host "`n" + "=" * 60 -ForegroundColor Green
    Write-Host "📊 SYSTEM STATUS REPORT" -ForegroundColor Green
    Write-Host "=" * 60 -ForegroundColor Green
    
    # PM2 Status
    Write-Host "`n🔧 PM2 Status:" -ForegroundColor Yellow
    try { 
        pm2 status 
    } catch { 
        Write-Host "PM2 not available" -ForegroundColor Red 
    }
    
    # Running Processes
    Write-Host "`n🔍 Running Processes:" -ForegroundColor Yellow
    $processes = @()
    $processes += Get-Process -Name "node" -ErrorAction SilentlyContinue
    $processes += Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
    
    if ($processes) {
        $processes | Format-Table Name, Id, CPU, WorkingSet -AutoSize
    } else {
        Write-Host "No relevant processes found" -ForegroundColor Red
    }
    
    # URLs
    Write-Host "`n🌐 Access URLs:" -ForegroundColor Green
    Write-Host "  Local:  http://localhost:5678" -ForegroundColor Cyan
    Write-Host "  Domain: https://app.strangematic.com" -ForegroundColor Cyan
    Write-Host "  API:    https://api.strangematic.com" -ForegroundColor Cyan
    
    # Runtime
    $runtime = (Get-Date) - $script:startTime
    Write-Host "`n⏱️ Total Runtime: $($runtime.TotalSeconds.ToString('F1')) seconds" -ForegroundColor Gray
    
    # Errors and Warnings Summary
    if ($script:errors) {
        Write-Host "`n❌ Errors ($($script:errors.Count)):" -ForegroundColor Red
        $script:errors | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
    }
    
    if ($script:warnings) {
        Write-Host "`n⚠️ Warnings ($($script:warnings.Count)):" -ForegroundColor Yellow
        $script:warnings | ForEach-Object { Write-Host "  • $_" -ForegroundColor Yellow }
    }
    
    Write-Host "`n" + "=" * 60 -ForegroundColor Green
}

# ============================================
# MAIN EXECUTION FLOW
# ============================================

try {
    # Step 1: Admin Check
    Test-AdminPrivileges
    
    # Step 2: Prerequisites Check
    if (-not (Test-Prerequisites)) {
        Write-Status "Prerequisites check failed. Cannot continue." "ERROR"
        Show-SystemStatus
        exit 1
    }
    
    # Step 3: Stop Existing Services
    if (-not $QuickStart) {
        Stop-AllServices
    }
    
    # Step 4: Start Services in Order
    Write-Status "Starting services in optimal order..." "STEP"
    
    # Database is already running, test connection
    if (-not (Test-DatabaseConnection)) {
        Write-Status "Database connection failed. Cannot continue." "ERROR"
        Show-SystemStatus
        exit 1
    }
    
    # Start Cloudflare Tunnel
    if (-not (Start-CloudflareTunnel)) {
        Write-Status "Tunnel startup failed. Cannot continue." "ERROR"
        Show-SystemStatus
        exit 1
    }
    
    # Start n8n
    if (-not (Start-N8nProduction)) {
        Write-Status "n8n startup failed. Cannot continue." "ERROR"
        Show-SystemStatus
        exit 1
    }
    
    # Step 5: Health Checks
    if (-not $SkipHealthCheck) {
        Write-Status "Running health checks..." "STEP"
        
        Test-LocalhostAccess
        Test-DomainAccess
    }
    
    # Step 6: Success Report
    Write-Status "🎉 STARTUP COMPLETED SUCCESSFULLY!" "SUCCESS"
    Show-SystemStatus
    
    Write-Host "`n🚀 READY TO USE:" -ForegroundColor Green
    Write-Host "  • n8n Interface: https://app.strangematic.com" -ForegroundColor Cyan
    Write-Host "  • Webhook API: https://api.strangematic.com" -ForegroundColor Cyan
    Write-Host "  • Local Dev: http://localhost:5678" -ForegroundColor Cyan
    
} catch {
    Write-Status "CRITICAL ERROR: $($_.Exception.Message)" "ERROR"
    $script:errors += "Critical: $($_.Exception.Message)"
    Show-SystemStatus
    exit 1
}
