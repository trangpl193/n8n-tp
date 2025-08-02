# ============================================
# 🚀 STRANGEMATIC AUTOMATION HUB - ALL-IN-ONE STARTUP
# ============================================
# Single script for complete automation hub startup
# Supports: Windows Startup Apps, Windows Service, Manual execution
# Auto-recovery, health monitoring, and zero-touch operation

param(
    [string]$Mode = "startup",  # startup, service, manual, install, uninstall
    [switch]$Silent,
    [switch]$AutoRecover = $true,
    [int]$MaxRetries = 3
)

# Global configuration
$Global:Config = @{
    ServiceName = "StrangematicHub"
    LogPath = "C:\automation\logs\strangematic-hub.log"
    PidFile = "C:\automation\strangematic-hub.pid"
    ConfigCheck = @{
        PostgreSQL = @{ Service = "postgresql-x64-17"; Port = 5432 }
        Cloudflared = @{ Path = "C:\cloudflared\cloudflared.exe"; Config = "C:\cloudflared\config.yml" }
        N8N = @{ EcosystemConfig = "ecosystem-stable.config.js"; EnvFile = ".env" }
    }
    URLs = @{
        Local = "http://localhost:5678"
        Domain = "https://app.strangematic.com"
        API = "https://api.strangematic.com"
    }
    Timeouts = @{
        ServiceStart = 30
        HealthCheck = 60
        Recovery = 120
    }
}

# ============================================
# LOGGING SYSTEM
# ============================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [switch]$Console = $true
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Ensure log directory exists
    $logDir = Split-Path $Global:Config.LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    # Write to log file
    try {
        Add-Content -Path $Global:Config.LogPath -Value $logEntry -ErrorAction SilentlyContinue
    } catch {
        # Log file issue, continue without logging
    }
    
    # Console output based on mode
    if ($Console -and -not $Silent) {
        $color = switch ($Level) {
            "SUCCESS" { "Green" }
            "ERROR"   { "Red" }
            "WARNING" { "Yellow" }
            "INFO"    { "Cyan" }
            default   { "White" }
        }
        
        $icon = switch ($Level) {
            "SUCCESS" { "[OK]" }
            "ERROR"   { "[ERR]" }
            "WARNING" { "[WARN]" }
            "INFO"    { "[INFO]" }
            default   { "[*]" }
        }
        
        Write-Host "$icon $Message" -ForegroundColor $color
    }
}

# ============================================
# PRIVILEGE MANAGEMENT
# ============================================

function Test-AdminPrivileges {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if (-not $isAdmin -and $Mode -ne "install") {
        Write-Log "Restarting with Administrator privileges..." "WARNING"
        
        $scriptPath = $MyInvocation.MyCommand.Path
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptPath`"", "-Mode", $Mode)
        if ($Silent) { $arguments += "-Silent" }
        if (-not $AutoRecover) { $arguments += "-AutoRecover:`$false" }
        
        try {
            Start-Process PowerShell -ArgumentList $arguments -Verb RunAs
            exit 0
        } catch {
            Write-Log "Failed to restart with admin privileges: $($_.Exception.Message)" "ERROR"
            exit 1
        }
    }
    
    if ($isAdmin) {
        Write-Log "Running with Administrator privileges" "SUCCESS"
        
        # Prevent background task suspension
        try {
            Write-Log "Preventing background task suspension..." "INFO"
            powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_BACKGROUND_APPS_POLICY BackgroundAppPolicy 0 2>$null | Out-Null
            powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_BACKGROUND_APPS_POLICY BackgroundAppPolicy 0 2>$null | Out-Null  
            powercfg /SETACTIVE SCHEME_CURRENT 2>$null | Out-Null
            Write-Log "Background app suspension prevention configured" "SUCCESS"
        } catch {
            Write-Log "Could not modify power policy: $($_.Exception.Message)" "WARNING"
        }
    }
    return $isAdmin
}

# ============================================
# PREREQUISITES CHECK
# ============================================

function Test-Prerequisites {
    Write-Log "Checking system prerequisites..." "INFO"
    $allGood = $true
    
    # PostgreSQL Service
    try {
        $pgService = Get-Service -Name $Global:Config.ConfigCheck.PostgreSQL.Service -ErrorAction Stop
        if ($pgService.Status -eq "Running") {
            Write-Log "PostgreSQL service is running" "SUCCESS"
            
            # Test connection
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.Connect("localhost", $Global:Config.ConfigCheck.PostgreSQL.Port)
            $tcpClient.Close()
            Write-Log "PostgreSQL connection successful" "SUCCESS"
        } else {
            Write-Log "PostgreSQL service not running" "ERROR"
            $allGood = $false
        }
    } catch {
        Write-Log "PostgreSQL check failed: $($_.Exception.Message)" "ERROR"
        $allGood = $false
    }
    
    # Cloudflared
    if (Test-Path $Global:Config.ConfigCheck.Cloudflared.Path) {
        Write-Log "Cloudflared executable found" "SUCCESS"
    } else {
        Write-Log "Cloudflared not found" "ERROR"
        $allGood = $false
    }
    
    if (Test-Path $Global:Config.ConfigCheck.Cloudflared.Config) {
        Write-Log "Cloudflared configuration found" "SUCCESS"
    } else {
        Write-Log "Cloudflared config not found" "ERROR"
        $allGood = $false
    }
    
    # n8n Configuration
    if (Test-Path $Global:Config.ConfigCheck.N8N.EcosystemConfig) {
        Write-Log "n8n ecosystem configuration found" "SUCCESS"
    } else {
        Write-Log "n8n ecosystem config not found" "ERROR"
        $allGood = $false
    }
    
    if (Test-Path $Global:Config.ConfigCheck.N8N.EnvFile) {
        Write-Log "n8n environment file found" "SUCCESS"
    } else {
        Write-Log "n8n environment file not found" "ERROR"
        $allGood = $false
    }
    
    return $allGood
}

# ============================================
# SERVICE MANAGEMENT
# ============================================

function Stop-AllServices {
    Write-Log "Stopping existing services..." "INFO"
    
    # Stop PM2
    try {
        pm2 kill | Out-Null
        Start-Sleep -Seconds 3
        Write-Log "PM2 daemon stopped" "SUCCESS"
    } catch {
        Write-Log "PM2 was not running" "INFO"
    }
    
    # Stop processes
    @("cloudflared", "node") | ForEach-Object {
        $processes = Get-Process -Name $_ -ErrorAction SilentlyContinue
        if ($processes) {
            $processes | Stop-Process -Force -ErrorAction SilentlyContinue
            Write-Log "$_ processes stopped ($($processes.Count))" "SUCCESS"
        }
    }
    
    Start-Sleep -Seconds 2
}

function Start-CloudflareTunnel {
    Write-Log "Starting Cloudflare tunnel..." "INFO"
    
    try {
        # Try PM2 first
        if (Test-Path "ecosystem-tunnel.config.js") {
            pm2 start ecosystem-tunnel.config.js | Out-Null
            Start-Sleep -Seconds 8
            
            $tunnelStatus = pm2 list | Select-String "cloudflared-tunnel.*online"
            if ($tunnelStatus) {
                Write-Log "Cloudflare tunnel started with PM2" "SUCCESS"
                return $true
            }
        }
        
        # Fallback to direct start
        Write-Log "Starting tunnel directly..." "INFO"
        $process = Start-Process -FilePath $Global:Config.ConfigCheck.Cloudflared.Path -ArgumentList "tunnel", "--config", $Global:Config.ConfigCheck.Cloudflared.Config, "run" -WindowStyle Hidden -PassThru
        Start-Sleep -Seconds 10
        
        if ($process -and -not $process.HasExited) {
            Write-Log "Cloudflare tunnel started directly (PID: $($process.Id))" "SUCCESS"
            return $true
        }
        
        Write-Log "Failed to start Cloudflare tunnel" "ERROR"
        return $false
        
    } catch {
        Write-Log "Tunnel start error: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Start-N8nProduction {
    Write-Log "Starting n8n production..." "INFO"
    
    try {
        # Load environment
        Get-Content $Global:Config.ConfigCheck.N8N.EnvFile | ForEach-Object {
            if ($_ -match "^([^#].*)=(.*)$") {
                $name = $matches[1].Trim()
                $value = $matches[2].Trim()
                [Environment]::SetEnvironmentVariable($name, $value, "Process")
            }
        }
        
        # Stop existing n8n if running
        try {
            pm2 stop strangematic-hub 2>$null
            pm2 delete strangematic-hub 2>$null
            Start-Sleep -Seconds 3
        } catch {
            # No existing process
        }
        
        # Start with PM2 (Windows-friendly hidden start)
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = "cmd.exe"
        $startInfo.Arguments = "/c pm2 start $($Global:Config.ConfigCheck.N8N.EcosystemConfig) --env production"
        $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $startInfo.CreateNoWindow = $true
        $startInfo.UseShellExecute = $false
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        $process.Start() | Out-Null
        $process.WaitForExit()
        
        Start-Sleep -Seconds 20  # Wait longer for full startup
        
        # Check if process is online
        $n8nStatus = pm2 list | Select-String "strangematic-hub.*online"
        if ($n8nStatus) {
            Write-Log "n8n started successfully" "SUCCESS"
            
            # Hide any node.exe windows that might have appeared
            try {
                Add-Type -TypeDefinition @"
                    using System;
                    using System.Runtime.InteropServices;
                    public class Win32 {
                        [DllImport("user32.dll")]
                        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
                        [DllImport("user32.dll")]
                        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
                    }
"@
                # Find and hide node.exe console windows
                $nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
                foreach ($proc in $nodeProcesses) {
                    if ($proc.MainWindowHandle -ne [IntPtr]::Zero) {
                        [Win32]::ShowWindow($proc.MainWindowHandle, 0) # 0 = SW_HIDE
                    }
                }
                Write-Log "Hidden node.exe console windows" "INFO"
            } catch {
                Write-Log "Could not hide node.exe windows: $($_.Exception.Message)" "WARNING"
            }
            
            # Additional health check - wait for web interface
            $webReady = $false
            $webRetries = 0
            while (-not $webReady -and $webRetries -lt 10) {
                try {
                    $response = Invoke-WebRequest -Uri $Global:Config.URLs.Local -TimeoutSec 5 -UseBasicParsing
                    if ($response.StatusCode -eq 200) {
                        $webReady = $true
                        Write-Log "n8n web interface ready" "SUCCESS"
                    }
                } catch {
                    $webRetries++
                    Write-Log "Waiting for n8n web interface... ($webRetries/10)" "INFO"
                    Start-Sleep -Seconds 5
                }
            }
            
            if (-not $webReady) {
                Write-Log "n8n web interface not responding, but process is running" "WARNING"
            }
            
            return $true
        } else {
            Write-Log "n8n failed to start" "ERROR"
            
            # Show PM2 logs for debugging
            Write-Log "Checking PM2 logs for errors..." "INFO"
            $logs = pm2 logs strangematic-hub --lines 5 --nostream 2>$null
            if ($logs) {
                Write-Log "Recent PM2 logs: $logs" "WARNING"
            }
            
            return $false
        }
        
    } catch {
        Write-Log "n8n start error: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ============================================
# HEALTH MONITORING
# ============================================

function Test-SystemHealth {
    Write-Log "Running health checks..." "INFO"
    $healthScore = 0
    $totalChecks = 4
    
    # Database connectivity
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect("localhost", 5432)
        $tcpClient.Close()
        $healthScore++
        Write-Log "Database health: OK" "SUCCESS"
    } catch {
        Write-Log "Database health: FAILED" "ERROR"
    }
    
    # Localhost n8n
    try {
        $response = Invoke-WebRequest -Uri $Global:Config.URLs.Local -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            $healthScore++
            Write-Log "n8n localhost health: OK" "SUCCESS"
        }
    } catch {
        Write-Log "n8n localhost health: FAILED" "ERROR"
    }
    
    # Domain access
    try {
        $response = Invoke-WebRequest -Uri $Global:Config.URLs.Domain -TimeoutSec 15 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            $healthScore++
            Write-Log "Domain health: OK" "SUCCESS"
        }
    } catch {
        Write-Log "Domain health: FAILED (may still be initializing)" "WARNING"
    }
    
    # Process check
    $cloudflaredRunning = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
    $nodeRunning = Get-Process -Name "node" -ErrorAction SilentlyContinue
    if ($cloudflaredRunning -and $nodeRunning) {
        $healthScore++
        Write-Log "Process health: OK" "SUCCESS"
    } else {
        Write-Log "Process health: FAILED" "ERROR"
    }
    
    $healthPercent = [math]::Round(($healthScore / $totalChecks) * 100)
    $healthLevel = if ($healthPercent -ge 75) { "SUCCESS" } elseif ($healthPercent -ge 50) { "WARNING" } else { "ERROR" }
    Write-Log "Overall health: $healthScore/$totalChecks ($healthPercent%)" $healthLevel
    
    return @{
        Score = $healthScore
        Total = $totalChecks
        Percentage = $healthPercent
        Healthy = $healthPercent -ge 75
    }
}

# ============================================
# AUTO RECOVERY
# ============================================

function Start-AutoRecovery {
    if (-not $AutoRecover) { return }
    
    Write-Log "Starting auto-recovery monitoring..." "INFO"
    
    $retryCount = 0
    while ($retryCount -lt $MaxRetries) {
        Start-Sleep -Seconds $Global:Config.Timeouts.Recovery
        
        $health = Test-SystemHealth
        if ($health.Healthy) {
            Write-Log "Auto-recovery: System healthy, monitoring continues..." "SUCCESS"
            continue
        }
        
        Write-Log "Auto-recovery: System unhealthy, attempting recovery..." "WARNING"
        $retryCount++
        
        # Recovery attempt
        Stop-AllServices
        Start-Sleep -Seconds 5
        
        if ((Start-CloudflareTunnel) -and (Start-N8nProduction)) {
            Write-Log "Auto-recovery: Recovery successful" "SUCCESS"
            $retryCount = 0  # Reset retry count on success
        } else {
            Write-Log "Auto-recovery: Recovery attempt $retryCount failed" "ERROR"
        }
    }
    
    if ($retryCount -ge $MaxRetries) {
        Write-Log "Auto-recovery: Max retries reached, system needs manual intervention" "ERROR"
    }
}

# ============================================
# WINDOWS STARTUP INTEGRATION
# ============================================

function Install-StartupIntegration {
    Write-Log "Installing Windows startup integration..." "INFO"
    
    try {
        # Create startup script
        $startupScript = @"
# Strangematic Hub Auto-Startup
Set-Location "$PWD"
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "$($MyInvocation.MyCommand.Path)" -Mode startup -Silent
"@
        
        $startupPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup\StrangematicHub.ps1"
        Set-Content -Path $startupPath -Value $startupScript
        
        Write-Log "Startup integration installed" "SUCCESS"
        Write-Log "Location: $startupPath" "INFO"
        
        # Create Windows Service option
        $servicePath = "C:\automation\service\strangematic-hub-service.ps1"
        $serviceDir = Split-Path $servicePath -Parent
        if (-not (Test-Path $serviceDir)) {
            New-Item -Path $serviceDir -ItemType Directory -Force | Out-Null
        }
        
        $serviceScript = @"
# Windows Service wrapper for Strangematic Hub
Set-Location "$PWD"
& "$($MyInvocation.MyCommand.Path)" -Mode service -Silent -AutoRecover
"@
        Set-Content -Path $servicePath -Value $serviceScript
        
        Write-Log "Service wrapper created: $servicePath" "INFO"
        return $true
        
    } catch {
        Write-Log "Startup integration failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Uninstall-StartupIntegration {
    Write-Log "Removing Windows startup integration..." "INFO"
    
    $startupPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup\StrangematicHub.ps1"
    if (Test-Path $startupPath) {
        Remove-Item -Path $startupPath -Force
        Write-Log "Startup integration removed" "SUCCESS"
    } else {
        Write-Log "No startup integration found" "INFO"
    }
}

# ============================================
# MAIN EXECUTION MODES
# ============================================

function Start-ManualMode {
    Write-Log "=== MANUAL STARTUP MODE ===" "INFO"
    
    if (-not (Test-Prerequisites)) {
        Write-Log "Prerequisites check failed" "ERROR"
        exit 1
    }
    
    Stop-AllServices
    
    if (-not (Start-CloudflareTunnel)) {
        Write-Log "Tunnel startup failed" "ERROR"
        exit 1
    }
    
    if (-not (Start-N8nProduction)) {
        Write-Log "n8n startup failed" "ERROR"
        exit 1
    }
    
    $health = Test-SystemHealth
    if ($health.Healthy) {
        Write-Log "=== STARTUP COMPLETED SUCCESSFULLY ===" "SUCCESS"
        Write-Log "Access URLs:" "INFO"
        Write-Log "  • Local: $($Global:Config.URLs.Local)" "INFO"
        Write-Log "  • Domain: $($Global:Config.URLs.Domain)" "INFO"
        Write-Log "  • API: $($Global:Config.URLs.API)" "INFO"
    } else {
        Write-Log "=== STARTUP COMPLETED WITH ISSUES ===" "WARNING"
    }
}

function Start-StartupMode {
    Write-Log "=== WINDOWS STARTUP MODE ===" "INFO"
    
    # Wait for Windows to fully load and services to be ready
    Write-Log "Waiting for Windows startup to complete..." "INFO"
    Start-Sleep -Seconds 30
    
    # Wait for network connectivity
    $networkReady = $false
    $networkRetries = 0
    while (-not $networkReady -and $networkRetries -lt 10) {
        try {
            Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet
            $networkReady = $true
            Write-Log "Network connectivity confirmed" "SUCCESS"
        } catch {
            $networkRetries++
            Write-Log "Waiting for network connectivity... ($networkRetries/10)" "WARNING"
            Start-Sleep -Seconds 10
        }
    }
    
    if (-not $networkReady) {
        Write-Log "Network not ready, proceeding anyway..." "WARNING"
    }
    
    Start-ManualMode
    
    if ($AutoRecover) {
        # Start background monitoring
        Start-Job -ScriptBlock {
            param($scriptPath, $config)
            while ($true) {
                Start-Sleep -Seconds 300  # Check every 5 minutes
                & $scriptPath -Mode health -Silent
            }
        } -ArgumentList $MyInvocation.MyCommand.Path, $Global:Config
    }
}

function Start-ServiceMode {
    Write-Log "=== WINDOWS SERVICE MODE ===" "INFO"
    
    # Create PID file
    $pidDir = Split-Path $Global:Config.PidFile -Parent
    if (-not (Test-Path $pidDir)) {
        New-Item -Path $pidDir -ItemType Directory -Force | Out-Null
    }
    Set-Content -Path $Global:Config.PidFile -Value $PID
    
    try {
        Start-ManualMode
        
        # Service monitoring loop
        while ($true) {
            Start-Sleep -Seconds 60
            $health = Test-SystemHealth
            if (-not $health.Healthy -and $AutoRecover) {
                Write-Log "Service mode: Triggering recovery..." "WARNING"
                Start-AutoRecovery
            }
        }
    } finally {
        # Cleanup
        if (Test-Path $Global:Config.PidFile) {
            Remove-Item -Path $Global:Config.PidFile -Force
        }
    }
}

function Start-HealthMode {
    $health = Test-SystemHealth
    if (-not $Silent) {
        Write-Log "Health check completed: $($health.Percentage)%" $(if ($health.Healthy) { "SUCCESS" } else { "WARNING" })
    }
    exit $(if ($health.Healthy) { 0 } else { 1 })
}

# ============================================
# MAIN ENTRY POINT
# ============================================

# Initialize logging
Write-Log "Strangematic Automation Hub starting..." "INFO"
Write-Log "Mode: $Mode, Silent: $Silent, AutoRecover: $AutoRecover" "INFO"

# Check admin privileges
Test-AdminPrivileges | Out-Null

# Execute based on mode
switch ($Mode.ToLower()) {
    "manual" {
        Start-ManualMode
    }
    "startup" {
        Start-StartupMode
    }
    "service" {
        Start-ServiceMode
    }
    "health" {
        Start-HealthMode
    }
    "install" {
        if (Install-StartupIntegration) {
            Write-Log "Installation completed successfully" "SUCCESS"
            Write-Log "The system will now start automatically with Windows" "INFO"
        } else {
            Write-Log "Installation failed" "ERROR"
            exit 1
        }
    }
    "uninstall" {
        Uninstall-StartupIntegration
        Write-Log "Uninstallation completed" "SUCCESS"
    }
    default {
        Write-Log "Usage: strangematic-hub.ps1 -Mode [manual|startup|service|health|install|uninstall]" "INFO"
        Write-Log "Options: -Silent, -AutoRecover, -MaxRetries number" "INFO"
        exit 1
    }
}
