<#
.SYNOPSIS
    StrangematicHub PM2 Health Monitor Script
    
.DESCRIPTION
    Continuously monitors PM2 daemon and n8n application health.
    Runs every 5 minutes, performs auto-recovery, and provides performance monitoring.
    
.NOTES
    Author: StrangematicHub
    Version: 1.0.0
    Requires: PowerShell 5.1+, PM2, Node.js
    
.EXAMPLE
    .\pm2-health-monitor.ps1
    .\pm2-health-monitor.ps1 -LogPath "C:\Custom\Logs" -AlertThreshold 3
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\ProgramData\StrangematicHub\Logs",
    
    [Parameter(Mandatory=$false)]
    [int]$CheckIntervalMinutes = 5,
    
    [Parameter(Mandatory=$false)]
    [int]$AlertThreshold = 3,
    
    [Parameter(Mandatory=$false)]
    [int]$AutoRecoveryMaxAttempts = 2,
    
    [Parameter(Mandatory=$false)]
    [switch]$RunOnce,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnablePerformanceMonitoring = $true
)

# Import required modules
Import-Module "$PSScriptRoot\StrangematicPM2Management.psm1" -Force

# Initialize logging
$LogFile = Join-Path $LogPath "pm2-health-monitor-$(Get-Date -Format 'yyyyMMdd').log"
$EventLogSource = "StrangematicHub"
$AlertCounterFile = Join-Path $LogPath "alert-counter.json"

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

function Write-MonitorLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error", "Success", "Debug")]
        [string]$Level = "Info"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [MONITOR] [$Level] $Message"
    
    # Write to console
    switch ($Level) {
        "Info" { Write-Host $LogEntry -ForegroundColor Cyan }
        "Warning" { Write-Host $LogEntry -ForegroundColor Yellow }
        "Error" { Write-Host $LogEntry -ForegroundColor Red }
        "Success" { Write-Host $LogEntry -ForegroundColor Green }
        "Debug" { Write-Host $LogEntry -ForegroundColor Gray }
    }
    
    # Write to log file
    try {
        Add-Content -Path $LogFile -Value $LogEntry -Encoding UTF8
    }
    catch {
        Write-Warning "Failed to write to log file: $_"
    }
    
    # Write to Event Log for critical events
    if ($Level -in @("Error", "Warning")) {
        try {
            $EventType = if ($Level -eq "Error") { "Error" } else { "Warning" }
            Write-EventLog -LogName Application -Source $EventLogSource -EventId 2001 -EntryType $EventType -Message $Message
        }
        catch {
            # Silently continue if Event Log write fails
        }
    }
}

function Get-AlertCounter {
    try {
        if (Test-Path $AlertCounterFile) {
            $CounterData = Get-Content $AlertCounterFile -Raw | ConvertFrom-Json
            return $CounterData
        }
        else {
            return @{
                PM2FailureCount = 0
                N8NFailureCount = 0
                LastReset = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
    }
    catch {
        Write-MonitorLog "Failed to read alert counter: $_" -Level Warning
        return @{
            PM2FailureCount = 0
            N8NFailureCount = 0
            LastReset = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
    }
}

function Set-AlertCounter {
    param(
        [hashtable]$CounterData
    )
    
    try {
        $CounterData | ConvertTo-Json | Set-Content $AlertCounterFile -Encoding UTF8
    }
    catch {
        Write-MonitorLog "Failed to write alert counter: $_" -Level Warning
    }
}

function Reset-AlertCounter {
    $CounterData = @{
        PM2FailureCount = 0
        N8NFailureCount = 0
        LastReset = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    Set-AlertCounter $CounterData
    Write-MonitorLog "Alert counters reset" -Level Info
}

function Invoke-AutoRecovery {
    param(
        [string]$Component,
        [int]$MaxAttempts = 2
    )
    
    Write-MonitorLog "Starting auto-recovery for $Component (max attempts: $MaxAttempts)" -Level Warning
    
    for ($Attempt = 1; $Attempt -le $MaxAttempts; $Attempt++) {
        Write-MonitorLog "Auto-recovery attempt $Attempt of $MaxAttempts for $Component" -Level Info
        
        try {
            switch ($Component) {
                "PM2" {
                    # Try to restart PM2 daemon
                    $ResetResult = Reset-PM2
                    if ($ResetResult.Success) {
                        Write-MonitorLog "PM2 daemon reset successfully" -Level Success
                        Start-Sleep -Seconds 10
                        
                        # Verify PM2 is running
                        $PM2Status = Get-PM2Status
                        if ($PM2Status.IsRunning) {
                            Write-MonitorLog "PM2 auto-recovery successful" -Level Success
                            return $true
                        }
                    }
                    else {
                        Write-MonitorLog "PM2 reset failed: $($ResetResult.Error)" -Level Error
                    }
                }
                
                "N8N" {
                    # Try to restart n8n application
                    $RestartResult = Restart-N8NApplication
                    if ($RestartResult.Success) {
                        Write-MonitorLog "n8n application restarted successfully" -Level Success
                        Start-Sleep -Seconds 15
                        
                        # Verify n8n is running
                        $N8NStatus = Get-N8NStatus
                        if ($N8NStatus.IsRunning) {
                            Write-MonitorLog "n8n auto-recovery successful" -Level Success
                            return $true
                        }
                    }
                    else {
                        Write-MonitorLog "n8n restart failed: $($RestartResult.Error)" -Level Error
                    }
                }
            }
        }
        catch {
            Write-MonitorLog "Auto-recovery attempt $Attempt failed: $_" -Level Error
        }
        
        if ($Attempt -lt $MaxAttempts) {
            Write-MonitorLog "Waiting 30 seconds before next recovery attempt..." -Level Info
            Start-Sleep -Seconds 30
        }
    }
    
    Write-MonitorLog "Auto-recovery failed for $Component after $MaxAttempts attempts" -Level Error
    return $false
}

function Get-PerformanceMetrics {
    try {
        # Get system performance metrics
        $CPU = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
        
        $Memory = Get-WmiObject -Class Win32_OperatingSystem | ForEach-Object {
            [math]::Round((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / $_.TotalVisibleMemorySize) * 100, 2)
        }
        
        $Disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | Where-Object { $_.DeviceID -eq "C:" } | ForEach-Object {
            [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)
        }
        
        # Get PM2 process metrics if available
        $PM2Metrics = @{
            ProcessCount = 0
            MemoryUsage = 0
            CPUUsage = 0
        }
        
        try {
            $PM2Status = Get-PM2Status
            if ($PM2Status.IsRunning) {
                $PM2Metrics.ProcessCount = $PM2Status.ProcessCount
                
                # Get detailed process info
                $ProcessDetails = Get-PM2ProcessDetails
                if ($ProcessDetails.Success) {
                    # Parse memory and CPU usage from PM2 output
                    # This is a simplified version - actual parsing would depend on PM2 output format
                    $PM2Metrics.MemoryUsage = "Available in detailed logs"
                    $PM2Metrics.CPUUsage = "Available in detailed logs"
                }
            }
        }
        catch {
            Write-MonitorLog "Failed to get PM2 metrics: $_" -Level Debug
        }
        
        return @{
            Timestamp = Get-Date
            System = @{
                CPU = $CPU
                Memory = $Memory
                Disk = $Disk
            }
            PM2 = $PM2Metrics
        }
    }
    catch {
        Write-MonitorLog "Failed to collect performance metrics: $_" -Level Warning
        return $null
    }
}

function Invoke-HealthMonitorCheck {
    Write-MonitorLog "=== Starting Health Monitor Check ===" -Level Info
    
    $CheckResults = @{
        Timestamp = Get-Date
        PM2Status = "Unknown"
        N8NStatus = "Unknown"
        OverallHealth = "Unknown"
        ActionsPerformed = @()
        PerformanceMetrics = $null
    }
    
    # Get alert counters
    $AlertCounter = Get-AlertCounter
    
    try {
        # Perform comprehensive health check
        $HealthCheck = Invoke-HealthCheck
        $CheckResults.OverallHealth = $HealthCheck.Overall
        $CheckResults.PM2Status = $HealthCheck.PM2Status
        $CheckResults.N8NStatus = $HealthCheck.N8NStatus
        
        Write-MonitorLog "Health Check Results:" -Level Info
        Write-MonitorLog "  Overall: $($HealthCheck.Overall)" -Level Info
        Write-MonitorLog "  PM2: $($HealthCheck.PM2Status)" -Level Info
        Write-MonitorLog "  n8n: $($HealthCheck.N8NStatus)" -Level Info
        
        # Check PM2 status and perform recovery if needed
        $PM2Status = Get-PM2Status
        if (-not $PM2Status.IsRunning) {
            Write-MonitorLog "PM2 daemon is not running - initiating auto-recovery" -Level Warning
            $AlertCounter.PM2FailureCount++
            
            if ($AlertCounter.PM2FailureCount -le $AlertThreshold) {
                $RecoveryResult = Invoke-AutoRecovery -Component "PM2" -MaxAttempts $AutoRecoveryMaxAttempts
                if ($RecoveryResult) {
                    $CheckResults.ActionsPerformed += "PM2 auto-recovery successful"
                    $AlertCounter.PM2FailureCount = 0  # Reset counter on successful recovery
                }
                else {
                    $CheckResults.ActionsPerformed += "PM2 auto-recovery failed"
                }
            }
            else {
                Write-MonitorLog "PM2 failure threshold exceeded ($AlertThreshold) - manual intervention required" -Level Error
                $CheckResults.ActionsPerformed += "PM2 failure threshold exceeded - manual intervention required"
            }
        }
        else {
            # Reset PM2 failure counter if running
            if ($AlertCounter.PM2FailureCount -gt 0) {
                $AlertCounter.PM2FailureCount = 0
                Write-MonitorLog "PM2 is healthy - resetting failure counter" -Level Success
            }
        }
        
        # Check n8n status and perform recovery if needed
        $N8NStatus = Get-N8NStatus
        if (-not $N8NStatus.IsRunning) {
            Write-MonitorLog "n8n application is not running - initiating auto-recovery" -Level Warning
            $AlertCounter.N8NFailureCount++
            
            if ($AlertCounter.N8NFailureCount -le $AlertThreshold) {
                $RecoveryResult = Invoke-AutoRecovery -Component "N8N" -MaxAttempts $AutoRecoveryMaxAttempts
                if ($RecoveryResult) {
                    $CheckResults.ActionsPerformed += "n8n auto-recovery successful"
                    $AlertCounter.N8NFailureCount = 0  # Reset counter on successful recovery
                }
                else {
                    $CheckResults.ActionsPerformed += "n8n auto-recovery failed"
                }
            }
            else {
                Write-MonitorLog "n8n failure threshold exceeded ($AlertThreshold) - manual intervention required" -Level Error
                $CheckResults.ActionsPerformed += "n8n failure threshold exceeded - manual intervention required"
            }
        }
        else {
            # Reset n8n failure counter if running
            if ($AlertCounter.N8NFailureCount -gt 0) {
                $AlertCounter.N8NFailureCount = 0
                Write-MonitorLog "n8n is healthy - resetting failure counter" -Level Success
            }
        }
        
        # Collect performance metrics if enabled
        if ($EnablePerformanceMonitoring) {
            $CheckResults.PerformanceMetrics = Get-PerformanceMetrics
            if ($CheckResults.PerformanceMetrics) {
                $Metrics = $CheckResults.PerformanceMetrics.System
                Write-MonitorLog "Performance Metrics: CPU: $($Metrics.CPU)%, Memory: $($Metrics.Memory)%, Disk: $($Metrics.Disk)%" -Level Debug
                
                # Alert on high resource usage
                if ($Metrics.Memory -gt 90) {
                    Write-MonitorLog "High memory usage detected: $($Metrics.Memory)%" -Level Warning
                }
                if ($Metrics.Disk -gt 90) {
                    Write-MonitorLog "Low disk space detected: $($Metrics.Disk)% used" -Level Warning
                }
            }
        }
        
        # Update alert counters
        Set-AlertCounter $AlertCounter
        
        # Log summary
        if ($CheckResults.ActionsPerformed.Count -gt 0) {
            Write-MonitorLog "Actions performed: $($CheckResults.ActionsPerformed -join ', ')" -Level Info
        }
        else {
            Write-MonitorLog "No recovery actions needed - system is healthy" -Level Success
        }
        
    }
    catch {
        Write-MonitorLog "Health monitor check failed: $_" -Level Error
        $CheckResults.OverallHealth = "Error"
    }
    
    Write-MonitorLog "=== Health Monitor Check Completed ===" -Level Info
    return $CheckResults
}

# Main execution
try {
    Write-MonitorLog "=== StrangematicHub PM2 Health Monitor Started ===" -Level Info
    Write-MonitorLog "Monitor version: 1.0.0" -Level Info
    Write-MonitorLog "Check interval: $CheckIntervalMinutes minutes" -Level Info
    Write-MonitorLog "Alert threshold: $AlertThreshold failures" -Level Info
    Write-MonitorLog "Auto-recovery max attempts: $AutoRecoveryMaxAttempts" -Level Info
    Write-MonitorLog "Performance monitoring: $EnablePerformanceMonitoring" -Level Info
    
    if ($RunOnce) {
        Write-MonitorLog "Running single health check..." -Level Info
        $CheckResult = Invoke-HealthMonitorCheck
        Write-MonitorLog "Single check completed with overall health: $($CheckResult.OverallHealth)" -Level Info
    }
    else {
        Write-MonitorLog "Starting continuous monitoring loop..." -Level Info
        
        while ($true) {
            $CheckResult = Invoke-HealthMonitorCheck
            
            Write-MonitorLog "Next check in $CheckIntervalMinutes minutes..." -Level Info
            Start-Sleep -Seconds ($CheckIntervalMinutes * 60)
        }
    }
}
catch {
    Write-MonitorLog "Critical error in health monitor: $_" -Level Error
    Write-MonitorLog "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}
finally {
    Write-MonitorLog "Health monitor execution completed at $(Get-Date)" -Level Info
}