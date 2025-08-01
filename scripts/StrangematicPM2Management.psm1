<#
.SYNOPSIS
    StrangematicHub PM2 Management Module
    
.DESCRIPTION
    PowerShell module for managing PM2 processes, health monitoring, and troubleshooting utilities.
    
.NOTES
    Author: StrangematicHub
    Version: 1.0.0
    Requires: PowerShell 5.1+, PM2, Node.js
#>

# Module variables
$script:PM2ExecutablePath = $null
$script:NodeExecutablePath = $null
$script:N8NExecutablePath = $null
$script:N8NWorkingDirectory = $null
$script:N8NProcessName = "n8n"

# Initialize module
function Initialize-PM2Management {
    [CmdletBinding()]
    param()
    
    # Find PM2 executable
    $script:PM2ExecutablePath = Get-Command "pm2" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if (-not $script:PM2ExecutablePath) {
        # Try common installation paths
        $CommonPaths = @(
            "$env:APPDATA\npm\pm2.cmd",
            "$env:ProgramFiles\nodejs\pm2.cmd",
            "C:\Program Files\nodejs\pm2.cmd",
            "C:\Program Files (x86)\nodejs\pm2.cmd"
        )
        
        foreach ($Path in $CommonPaths) {
            if (Test-Path $Path) {
                $script:PM2ExecutablePath = $Path
                break
            }
        }
    }
    
    # Find Node.js executable
    $script:NodeExecutablePath = Get-Command "node" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    
    # Find n8n executable
    $script:N8NExecutablePath = Get-Command "n8n" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if (-not $script:N8NExecutablePath) {
        # Try common installation paths
        $CommonPaths = @(
            "$env:APPDATA\npm\n8n.cmd",
            "$env:ProgramFiles\nodejs\n8n.cmd",
            "C:\Program Files\nodejs\n8n.cmd",
            "C:\Program Files (x86)\nodejs\n8n.cmd"
        )
        
        foreach ($Path in $CommonPaths) {
            if (Test-Path $Path) {
                $script:N8NExecutablePath = $Path
                break
            }
        }
    }
    
    # Set n8n working directory (default to current directory)
    $script:N8NWorkingDirectory = Get-Location
}

# Initialize on module import
Initialize-PM2Management

function Get-PM2Status {
    <#
    .SYNOPSIS
        Gets the current status of PM2 daemon
    #>
    [CmdletBinding()]
    param()
    
    try {
        if (-not $script:PM2ExecutablePath) {
            return @{
                IsRunning = $false
                Error = "PM2 executable not found"
                ProcessCount = 0
                Processes = @()
            }
        }
        
        # Check if PM2 daemon is running
        $PM2Process = Get-Process -Name "PM2*" -ErrorAction SilentlyContinue
        $IsDaemonRunning = $PM2Process -ne $null
        
        # Get PM2 process list
        $PM2ListOutput = & $script:PM2ExecutablePath list --no-color 2>&1
        $ProcessCount = 0
        $Processes = @()
        
        if ($LASTEXITCODE -eq 0 -and $PM2ListOutput) {
            # Parse PM2 list output
            $Lines = $PM2ListOutput -split "`n" | Where-Object { $_ -match "^\s*\d+\s*\|" }
            $ProcessCount = $Lines.Count
            
            foreach ($Line in $Lines) {
                if ($Line -match "^\s*(\d+)\s*\|\s*(\S+)\s*\|\s*(\S+)\s*\|\s*(\S+)\s*\|\s*(\S+)") {
                    $Processes += @{
                        Id = $Matches[1]
                        Name = $Matches[2]
                        Mode = $Matches[3]
                        Status = $Matches[4]
                        Restart = $Matches[5]
                    }
                }
            }
        }
        
        return @{
            IsRunning = $IsDaemonRunning
            ProcessCount = $ProcessCount
            Processes = $Processes
            Error = $null
        }
    }
    catch {
        return @{
            IsRunning = $false
            Error = $_.Exception.Message
            ProcessCount = 0
            Processes = @()
        }
    }
}

function Start-PM2Daemon {
    <#
    .SYNOPSIS
        Starts the PM2 daemon
    #>
    [CmdletBinding()]
    param()
    
    try {
        if (-not $script:PM2ExecutablePath) {
            return @{
                Success = $false
                Error = "PM2 executable not found"
            }
        }
        
        # Check if already running
        $Status = Get-PM2Status
        if ($Status.IsRunning) {
            return @{
                Success = $true
                Message = "PM2 daemon is already running"
            }
        }
        
        # Start PM2 daemon
        $StartOutput = & $script:PM2ExecutablePath ping 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            return @{
                Success = $true
                Message = "PM2 daemon started successfully"
            }
        }
        else {
            return @{
                Success = $false
                Error = "Failed to start PM2 daemon: $StartOutput"
            }
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-N8NStatus {
    <#
    .SYNOPSIS
        Gets the current status of n8n application
    #>
    [CmdletBinding()]
    param()
    
    try {
        $PM2Status = Get-PM2Status
        
        if (-not $PM2Status.IsRunning) {
            return @{
                IsRunning = $false
                Error = "PM2 daemon is not running"
                ProcessInfo = $null
            }
        }
        
        # Find n8n process in PM2
        $N8NProcess = $PM2Status.Processes | Where-Object { $_.Name -eq $script:N8NProcessName }
        
        if ($N8NProcess) {
            $IsRunning = $N8NProcess.Status -eq "online"
            return @{
                IsRunning = $IsRunning
                ProcessInfo = $N8NProcess
                Error = $null
            }
        }
        else {
            return @{
                IsRunning = $false
                ProcessInfo = $null
                Error = "n8n process not found in PM2"
            }
        }
    }
    catch {
        return @{
            IsRunning = $false
            ProcessInfo = $null
            Error = $_.Exception.Message
        }
    }
}

function Start-N8NApplication {
    <#
    .SYNOPSIS
        Starts the n8n application using PM2
    #>
    [CmdletBinding()]
    param(
        [string]$WorkingDirectory = $script:N8NWorkingDirectory,
        [string]$ProcessName = $script:N8NProcessName
    )
    
    try {
        if (-not $script:PM2ExecutablePath) {
            return @{
                Success = $false
                Error = "PM2 executable not found"
            }
        }
        
        if (-not $script:N8NExecutablePath) {
            return @{
                Success = $false
                Error = "n8n executable not found"
            }
        }
        
        # Check if n8n is already running
        $N8NStatus = Get-N8NStatus
        if ($N8NStatus.IsRunning) {
            return @{
                Success = $true
                Message = "n8n application is already running"
            }
        }
        
        # Start n8n with PM2
        $StartArgs = @(
            "start",
            $script:N8NExecutablePath,
            "--name", $ProcessName,
            "--cwd", $WorkingDirectory,
            "--no-autorestart",
            "--max-memory-restart", "1G"
        )
        
        $StartOutput = & $script:PM2ExecutablePath @StartArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            return @{
                Success = $true
                Message = "n8n application started successfully"
                Output = $StartOutput
            }
        }
        else {
            return @{
                Success = $false
                Error = "Failed to start n8n application: $StartOutput"
            }
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Stop-N8NApplication {
    <#
    .SYNOPSIS
        Stops the n8n application
    #>
    [CmdletBinding()]
    param(
        [string]$ProcessName = $script:N8NProcessName
    )
    
    try {
        if (-not $script:PM2ExecutablePath) {
            return @{
                Success = $false
                Error = "PM2 executable not found"
            }
        }
        
        $StopOutput = & $script:PM2ExecutablePath stop $ProcessName 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            return @{
                Success = $true
                Message = "n8n application stopped successfully"
                Output = $StopOutput
            }
        }
        else {
            return @{
                Success = $false
                Error = "Failed to stop n8n application: $StopOutput"
            }
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Restart-N8NApplication {
    <#
    .SYNOPSIS
        Restarts the n8n application
    #>
    [CmdletBinding()]
    param(
        [string]$ProcessName = $script:N8NProcessName
    )
    
    try {
        if (-not $script:PM2ExecutablePath) {
            return @{
                Success = $false
                Error = "PM2 executable not found"
            }
        }
        
        $RestartOutput = & $script:PM2ExecutablePath restart $ProcessName 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            return @{
                Success = $true
                Message = "n8n application restarted successfully"
                Output = $RestartOutput
            }
        }
        else {
            return @{
                Success = $false
                Error = "Failed to restart n8n application: $RestartOutput"
            }
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-PM2Logs {
    <#
    .SYNOPSIS
        Gets PM2 logs for troubleshooting
    #>
    [CmdletBinding()]
    param(
        [string]$ProcessName = $script:N8NProcessName,
        [int]$Lines = 50
    )
    
    try {
        if (-not $script:PM2ExecutablePath) {
            return @{
                Success = $false
                Error = "PM2 executable not found"
                Logs = $null
            }
        }
        
        $LogsOutput = & $script:PM2ExecutablePath logs $ProcessName --lines $Lines --nostream 2>&1
        
        return @{
            Success = $true
            Logs = $LogsOutput
            Error = $null
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Logs = $null
        }
    }
}

function Invoke-HealthCheck {
    <#
    .SYNOPSIS
        Performs comprehensive health check of PM2 and n8n
    #>
    [CmdletBinding()]
    param()
    
    try {
        $HealthReport = @{
            Timestamp = Get-Date
            Overall = "Unknown"
            PM2Status = "Unknown"
            N8NStatus = "Unknown"
            Issues = @()
            Recommendations = @()
        }
        
        # Check PM2 status
        $PM2Status = Get-PM2Status
        if ($PM2Status.IsRunning) {
            $HealthReport.PM2Status = "Running ($($PM2Status.ProcessCount) processes)"
        }
        else {
            $HealthReport.PM2Status = "Not Running"
            $HealthReport.Issues += "PM2 daemon is not running"
            $HealthReport.Recommendations += "Start PM2 daemon using Start-PM2Daemon"
        }
        
        # Check n8n status
        $N8NStatus = Get-N8NStatus
        if ($N8NStatus.IsRunning) {
            $HealthReport.N8NStatus = "Running"
        }
        else {
            $HealthReport.N8NStatus = "Not Running"
            $HealthReport.Issues += "n8n application is not running"
            $HealthReport.Recommendations += "Start n8n application using Start-N8NApplication"
        }
        
        # Check system resources
        $MemoryUsage = Get-WmiObject -Class Win32_OperatingSystem | ForEach-Object {
            [math]::Round((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / $_.TotalVisibleMemorySize) * 100, 2)
        }
        
        if ($MemoryUsage -gt 90) {
            $HealthReport.Issues += "High memory usage: $MemoryUsage%"
            $HealthReport.Recommendations += "Consider restarting applications or increasing system memory"
        }
        
        # Check disk space
        $DiskSpace = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | Where-Object { $_.DeviceID -eq "C:" } | ForEach-Object {
            [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)
        }
        
        if ($DiskSpace -gt 90) {
            $HealthReport.Issues += "Low disk space: $DiskSpace% used"
            $HealthReport.Recommendations += "Clean up disk space or expand storage"
        }
        
        # Determine overall health
        if ($HealthReport.Issues.Count -eq 0) {
            $HealthReport.Overall = "Healthy"
        }
        elseif ($PM2Status.IsRunning -and $N8NStatus.IsRunning) {
            $HealthReport.Overall = "Warning"
        }
        else {
            $HealthReport.Overall = "Critical"
        }
        
        return $HealthReport
    }
    catch {
        return @{
            Timestamp = Get-Date
            Overall = "Error"
            PM2Status = "Error"
            N8NStatus = "Error"
            Issues = @("Health check failed: $($_.Exception.Message)")
            Recommendations = @("Check system logs and try running health check again")
        }
    }
}

function Get-PM2ProcessDetails {
    <#
    .SYNOPSIS
        Gets detailed information about PM2 processes
    #>
    [CmdletBinding()]
    param(
        [string]$ProcessName = $script:N8NProcessName
    )
    
    try {
        if (-not $script:PM2ExecutablePath) {
            return @{
                Success = $false
                Error = "PM2 executable not found"
                Details = $null
            }
        }
        
        $DetailsOutput = & $script:PM2ExecutablePath show $ProcessName 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            return @{
                Success = $true
                Details = $DetailsOutput
                Error = $null
            }
        }
        else {
            return @{
                Success = $false
                Error = "Failed to get process details: $DetailsOutput"
                Details = $null
            }
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Details = $null
        }
    }
}

function Reset-PM2 {
    <#
    .SYNOPSIS
        Resets PM2 daemon and all processes
    #>
    [CmdletBinding()]
    param()
    
    try {
        if (-not $script:PM2ExecutablePath) {
            return @{
                Success = $false
                Error = "PM2 executable not found"
            }
        }
        
        # Kill PM2 daemon
        $KillOutput = & $script:PM2ExecutablePath kill 2>&1
        
        # Wait a moment
        Start-Sleep -Seconds 3
        
        # Restart PM2 daemon
        $StartResult = Start-PM2Daemon
        
        if ($StartResult.Success) {
            return @{
                Success = $true
                Message = "PM2 reset successfully"
            }
        }
        else {
            return @{
                Success = $false
                Error = "Failed to restart PM2 after reset: $($StartResult.Error)"
            }
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Get-PM2Status',
    'Start-PM2Daemon',
    'Get-N8NStatus',
    'Start-N8NApplication',
    'Stop-N8NApplication',
    'Restart-N8NApplication',
    'Get-PM2Logs',
    'Invoke-HealthCheck',
    'Get-PM2ProcessDetails',
    'Reset-PM2'
)