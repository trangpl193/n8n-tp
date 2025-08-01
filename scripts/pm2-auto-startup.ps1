<#
.SYNOPSIS
    StrangematicHub PM2 Auto-Startup Script
    
.DESCRIPTION
    Automatically starts PM2 daemon and n8n application on Windows boot.
    Includes dependency checking, retry mechanisms, and comprehensive logging.
    
.NOTES
    Author: StrangematicHub
    Version: 1.0.0
    Requires: PowerShell 5.1+, PM2, Node.js
    
.EXAMPLE
    .\pm2-auto-startup.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\ProgramData\StrangematicHub\Logs",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxRetries = 3,
    
    [Parameter(Mandatory=$false)]
    [int]$RetryDelaySeconds = 60,
    
    [Parameter(Mandatory=$false)]
    [int]$PostgreSQLTimeoutSeconds = 60,
    
    [Parameter(Mandatory=$false)]
    [int]$NetworkTimeoutSeconds = 30
)

# Import required modules
Import-Module "$PSScriptRoot\StrangematicPM2Management.psm1" -Force

# Initialize logging
$LogFile = Join-Path $LogPath "pm2-auto-startup-$(Get-Date -Format 'yyyyMMdd').log"
$EventLogSource = "StrangematicHub"

# Ensure log directory exists
if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

# Initialize Event Log source
if (-not [System.Diagnostics.EventLog]::SourceExists($EventLogSource)) {
    try {
        New-EventLog -LogName Application -Source $EventLogSource
    }
    catch {
        Write-Warning "Failed to create Event Log source: $_"
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    
    # Write to console
    switch ($Level) {
        "Info" { Write-Host $LogEntry -ForegroundColor White }
        "Warning" { Write-Host $LogEntry -ForegroundColor Yellow }
        "Error" { Write-Host $LogEntry -ForegroundColor Red }
        "Success" { Write-Host $LogEntry -ForegroundColor Green }
    }
    
    # Write to log file
    try {
        Add-Content -Path $LogFile -Value $LogEntry -Encoding UTF8
    }
    catch {
        Write-Warning "Failed to write to log file: $_"
    }
    
    # Write to Event Log
    try {
        $EventType = switch ($Level) {
            "Error" { "Error" }
            "Warning" { "Warning" }
            default { "Information" }
        }
        Write-EventLog -LogName Application -Source $EventLogSource -EventId 1001 -EntryType $EventType -Message $Message
    }
    catch {
        # Silently continue if Event Log write fails
    }
}

function Test-PostgreSQLConnection {
    param(
        [int]$TimeoutSeconds = 60
    )
    
    Write-Log "Checking PostgreSQL connection..." -Level Info
    
    $StartTime = Get-Date
    $TimeoutTime = $StartTime.AddSeconds($TimeoutSeconds)
    
    while ((Get-Date) -lt $TimeoutTime) {
        try {
            # Check if PostgreSQL service is running
            $PostgreSQLService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Running" }
            
            if ($PostgreSQLService) {
                # Try to connect to PostgreSQL
                $TestConnection = Test-NetConnection -ComputerName "localhost" -Port 5432 -InformationLevel Quiet -WarningAction SilentlyContinue
                
                if ($TestConnection) {
                    Write-Log "PostgreSQL connection successful" -Level Success
                    return $true
                }
            }
            
            Write-Log "PostgreSQL not ready, waiting..." -Level Info
            Start-Sleep -Seconds 5
        }
        catch {
            Write-Log "PostgreSQL connection test failed: $_" -Level Warning
            Start-Sleep -Seconds 5
        }
    }
    
    Write-Log "PostgreSQL connection timeout after $TimeoutSeconds seconds" -Level Error
    return $false
}

function Test-NetworkConnectivity {
    param(
        [int]$TimeoutSeconds = 30
    )
    
    Write-Log "Checking network connectivity..." -Level Info
    
    $StartTime = Get-Date
    $TimeoutTime = $StartTime.AddSeconds($TimeoutSeconds)
    
    $TestHosts = @("8.8.8.8", "1.1.1.1", "google.com")
    
    while ((Get-Date) -lt $TimeoutTime) {
        foreach ($Host in $TestHosts) {
            try {
                $TestResult = Test-NetConnection -ComputerName $Host -InformationLevel Quiet -WarningAction SilentlyContinue
                if ($TestResult) {
                    Write-Log "Network connectivity confirmed (tested: $Host)" -Level Success
                    return $true
                }
            }
            catch {
                Write-Log "Network test failed for $Host`: $_" -Level Warning
            }
        }
        
        Write-Log "Network not ready, waiting..." -Level Info
        Start-Sleep -Seconds 5
    }
    
    Write-Log "Network connectivity timeout after $TimeoutSeconds seconds" -Level Error
    return $false
}

function Start-PM2WithRetry {
    param(
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 60
    )
    
    for ($Attempt = 1; $Attempt -le $MaxRetries; $Attempt++) {
        Write-Log "Starting PM2 daemon (Attempt $Attempt of $MaxRetries)..." -Level Info
        
        try {
            # Check if PM2 is already running
            $PM2Status = Get-PM2Status
            if ($PM2Status.IsRunning) {
                Write-Log "PM2 daemon is already running" -Level Success
                return $true
            }
            
            # Start PM2 daemon
            $StartResult = Start-PM2Daemon
            if ($StartResult.Success) {
                Write-Log "PM2 daemon started successfully" -Level Success
                return $true
            }
            else {
                Write-Log "PM2 daemon start failed: $($StartResult.Error)" -Level Error
            }
        }
        catch {
            Write-Log "PM2 daemon start attempt failed: $_" -Level Error
        }
        
        if ($Attempt -lt $MaxRetries) {
            Write-Log "Waiting $DelaySeconds seconds before retry..." -Level Info
            Start-Sleep -Seconds $DelaySeconds
        }
    }
    
    Write-Log "Failed to start PM2 daemon after $MaxRetries attempts" -Level Error
    return $false
}

function Start-N8NWithRetry {
    param(
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 60
    )
    
    for ($Attempt = 1; $Attempt -le $MaxRetries; $Attempt++) {
        Write-Log "Starting n8n application (Attempt $Attempt of $MaxRetries)..." -Level Info
        
        try {
            # Check if n8n is already running
            $N8NStatus = Get-N8NStatus
            if ($N8NStatus.IsRunning) {
                Write-Log "n8n application is already running" -Level Success
                return $true
            }
            
            # Start n8n application
            $StartResult = Start-N8NApplication
            if ($StartResult.Success) {
                Write-Log "n8n application started successfully" -Level Success
                
                # Wait a moment and verify it's still running
                Start-Sleep -Seconds 10
                $VerifyStatus = Get-N8NStatus
                if ($VerifyStatus.IsRunning) {
                    Write-Log "n8n application startup verified" -Level Success
                    return $true
                }
                else {
                    Write-Log "n8n application failed verification check" -Level Error
                }
            }
            else {
                Write-Log "n8n application start failed: $($StartResult.Error)" -Level Error
            }
        }
        catch {
            Write-Log "n8n application start attempt failed: $_" -Level Error
        }
        
        if ($Attempt -lt $MaxRetries) {
            Write-Log "Waiting $DelaySeconds seconds before retry..." -Level Info
            Start-Sleep -Seconds $DelaySeconds
        }
    }
    
    Write-Log "Failed to start n8n application after $MaxRetries attempts" -Level Error
    return $false
}

function Invoke-ExponentialBackoff {
    param(
        [int]$Attempt,
        [int]$BaseDelaySeconds = 60,
        [int]$MaxDelaySeconds = 300
    )
    
    $DelaySeconds = [Math]::Min($BaseDelaySeconds * [Math]::Pow(2, $Attempt - 1), $MaxDelaySeconds)
    Write-Log "Exponential backoff: waiting $DelaySeconds seconds..." -Level Info
    Start-Sleep -Seconds $DelaySeconds
}

# Main execution
try {
    Write-Log "=== StrangematicHub PM2 Auto-Startup Started ===" -Level Info
    Write-Log "Script version: 1.0.0" -Level Info
    Write-Log "Execution parameters: MaxRetries=$MaxRetries, RetryDelay=$RetryDelaySeconds, PostgreSQLTimeout=$PostgreSQLTimeoutSeconds, NetworkTimeout=$NetworkTimeoutSeconds" -Level Info
    
    # Step 1: Check PostgreSQL dependency
    Write-Log "Step 1: Checking PostgreSQL dependency..." -Level Info
    if (-not (Test-PostgreSQLConnection -TimeoutSeconds $PostgreSQLTimeoutSeconds)) {
        Write-Log "PostgreSQL dependency check failed - continuing with limited functionality" -Level Warning
    }
    
    # Step 2: Check Network connectivity
    Write-Log "Step 2: Checking network connectivity..." -Level Info
    if (-not (Test-NetworkConnectivity -TimeoutSeconds $NetworkTimeoutSeconds)) {
        Write-Log "Network connectivity check failed - continuing with limited functionality" -Level Warning
    }
    
    # Step 3: Start PM2 daemon
    Write-Log "Step 3: Starting PM2 daemon..." -Level Info
    if (-not (Start-PM2WithRetry -MaxRetries $MaxRetries -DelaySeconds $RetryDelaySeconds)) {
        Write-Log "Critical failure: PM2 daemon could not be started" -Level Error
        exit 1
    }
    
    # Step 4: Start n8n application
    Write-Log "Step 4: Starting n8n application..." -Level Info
    if (-not (Start-N8NWithRetry -MaxRetries $MaxRetries -DelaySeconds $RetryDelaySeconds)) {
        Write-Log "Critical failure: n8n application could not be started" -Level Error
        exit 1
    }
    
    # Step 5: Final health check
    Write-Log "Step 5: Performing final health check..." -Level Info
    $HealthCheck = Invoke-HealthCheck
    if ($HealthCheck.Overall -eq "Healthy") {
        Write-Log "=== StrangematicHub PM2 Auto-Startup Completed Successfully ===" -Level Success
        Write-Log "System Status: $($HealthCheck.Overall)" -Level Success
        Write-Log "PM2 Status: $($HealthCheck.PM2Status)" -Level Info
        Write-Log "n8n Status: $($HealthCheck.N8NStatus)" -Level Info
        exit 0
    }
    else {
        Write-Log "=== StrangematicHub PM2 Auto-Startup Completed with Issues ===" -Level Warning
        Write-Log "System Status: $($HealthCheck.Overall)" -Level Warning
        Write-Log "PM2 Status: $($HealthCheck.PM2Status)" -Level Warning
        Write-Log "n8n Status: $($HealthCheck.N8NStatus)" -Level Warning
        exit 2
    }
}
catch {
    Write-Log "Critical error during startup: $_" -Level Error
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}
finally {
    Write-Log "Auto-startup script execution completed at $(Get-Date)" -Level Info
}