<#
.SYNOPSIS
    StrangematicHub PM2 Auto-Startup Installation Script
    
.DESCRIPTION
    Automatically installs and configures Task Scheduler tasks for PM2 auto-startup and health monitoring.
    Configures permissions, validates installation, and provides testing capabilities.
    
.NOTES
    Author: StrangematicHub
    Version: 1.0.0
    Requires: PowerShell 5.1+, Administrator privileges
    
.EXAMPLE
    .\install-pm2-autostart.ps1
    .\install-pm2-autostart.ps1 -Uninstall
    .\install-pm2-autostart.ps1 -TestOnly
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$Uninstall,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\ProgramData\StrangematicHub\Logs",
    
    [Parameter(Mandatory=$false)]
    [string]$ScriptPath = $PSScriptRoot
)

# Requires Administrator privileges
#Requires -RunAsAdministrator

# Initialize logging
$LogFile = Join-Path $LogPath "pm2-autostart-install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$EventLogSource = "StrangematicHub"

# Task names
$AutoStartTaskName = "StrangematicHub-PM2-AutoStart"
$HealthMonitorTaskName = "StrangematicHub-PM2-HealthMonitor"

# Ensure log directory exists
if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

function Write-InstallLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [INSTALL] [$Level] $Message"
    
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
}

function Test-Prerequisites {
    Write-InstallLog "Checking installation prerequisites..." -Level Info
    
    $Prerequisites = @{
        IsAdmin = $false
        PowerShellVersion = $false
        TaskSchedulerAvailable = $false
        ScriptFilesExist = $false
        NodeJSInstalled = $false
        PM2Installed = $false
        N8NInstalled = $false
    }
    
    # Check if running as Administrator
    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $Prerequisites.IsAdmin = $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    # Check PowerShell version
    $Prerequisites.PowerShellVersion = $PSVersionTable.PSVersion.Major -ge 5
    
    # Check Task Scheduler availability
    try {
        $TaskScheduler = New-Object -ComObject Schedule.Service
        $TaskScheduler.Connect()
        $Prerequisites.TaskSchedulerAvailable = $true
    }
    catch {
        $Prerequisites.TaskSchedulerAvailable = $false
    }
    
    # Check if required script files exist
    $RequiredFiles = @(
        "pm2-auto-startup.ps1",
        "StrangematicPM2Management.psm1",
        "StrangematicHub-AutoStart.xml",
        "pm2-health-monitor.ps1"
    )
    
    $MissingFiles = @()
    foreach ($File in $RequiredFiles) {
        $FilePath = Join-Path $ScriptPath $File
        if (-not (Test-Path $FilePath)) {
            $MissingFiles += $File
        }
    }
    $Prerequisites.ScriptFilesExist = $MissingFiles.Count -eq 0
    
    # Check Node.js installation
    try {
        $NodeVersion = & node --version 2>$null
        $Prerequisites.NodeJSInstalled = $LASTEXITCODE -eq 0
    }
    catch {
        $Prerequisites.NodeJSInstalled = $false
    }
    
    # Check PM2 installation
    try {
        $PM2Version = & pm2 --version 2>$null
        $Prerequisites.PM2Installed = $LASTEXITCODE -eq 0
    }
    catch {
        $Prerequisites.PM2Installed = $false
    }
    
    # Check n8n installation
    try {
        $N8NVersion = & n8n --version 2>$null
        $Prerequisites.N8NInstalled = $LASTEXITCODE -eq 0
    }
    catch {
        $Prerequisites.N8NInstalled = $false
    }
    
    # Report results
    Write-InstallLog "Prerequisites check results:" -Level Info
    Write-InstallLog "  Administrator privileges: $($Prerequisites.IsAdmin)" -Level $(if ($Prerequisites.IsAdmin) { "Success" } else { "Error" })
    Write-InstallLog "  PowerShell version >= 5.1: $($Prerequisites.PowerShellVersion)" -Level $(if ($Prerequisites.PowerShellVersion) { "Success" } else { "Error" })
    Write-InstallLog "  Task Scheduler available: $($Prerequisites.TaskSchedulerAvailable)" -Level $(if ($Prerequisites.TaskSchedulerAvailable) { "Success" } else { "Error" })
    Write-InstallLog "  Script files exist: $($Prerequisites.ScriptFilesExist)" -Level $(if ($Prerequisites.ScriptFilesExist) { "Success" } else { "Error" })
    Write-InstallLog "  Node.js installed: $($Prerequisites.NodeJSInstalled)" -Level $(if ($Prerequisites.NodeJSInstalled) { "Success" } else { "Warning" })
    Write-InstallLog "  PM2 installed: $($Prerequisites.PM2Installed)" -Level $(if ($Prerequisites.PM2Installed) { "Success" } else { "Warning" })
    Write-InstallLog "  n8n installed: $($Prerequisites.N8NInstalled)" -Level $(if ($Prerequisites.N8NInstalled) { "Success" } else { "Warning" })
    
    if ($MissingFiles.Count -gt 0) {
        Write-InstallLog "Missing script files: $($MissingFiles -join ', ')" -Level Error
    }
    
    return $Prerequisites
}

function Install-EventLogSource {
    try {
        if (-not [System.Diagnostics.EventLog]::SourceExists($EventLogSource)) {
            Write-InstallLog "Creating Event Log source: $EventLogSource" -Level Info
            New-EventLog -LogName Application -Source $EventLogSource
            Write-InstallLog "Event Log source created successfully" -Level Success
        }
        else {
            Write-InstallLog "Event Log source already exists: $EventLogSource" -Level Info
        }
        return $true
    }
    catch {
        Write-InstallLog "Failed to create Event Log source: $_" -Level Error
        return $false
    }
}

function Install-AutoStartTask {
    try {
        Write-InstallLog "Installing PM2 Auto-Start task..." -Level Info
        
        # Check if task already exists
        $ExistingTask = Get-ScheduledTask -TaskName $AutoStartTaskName -ErrorAction SilentlyContinue
        if ($ExistingTask -and -not $Force) {
            Write-InstallLog "Auto-Start task already exists. Use -Force to overwrite." -Level Warning
            return $false
        }
        
        if ($ExistingTask) {
            Write-InstallLog "Removing existing Auto-Start task..." -Level Info
            Unregister-ScheduledTask -TaskName $AutoStartTaskName -Confirm:$false
        }
        
        # Update XML configuration with current script path
        $XMLPath = Join-Path $ScriptPath "StrangematicHub-AutoStart.xml"
        $XMLContent = Get-Content $XMLPath -Raw
        
        # Replace placeholder paths with actual paths
        $XMLContent = $XMLContent -replace 'C:\\Github\\n8n-tp', $ScriptPath.Replace('\', '\\')
        $XMLContent = $XMLContent -replace 'C:\\Github\\n8n-tp\\scripts\\pm2-auto-startup\.ps1', (Join-Path $ScriptPath "pm2-auto-startup.ps1").Replace('\', '\\')
        
        # Save updated XML to temp file
        $TempXMLPath = Join-Path $env:TEMP "StrangematicHub-AutoStart-temp.xml"
        $XMLContent | Set-Content $TempXMLPath -Encoding UTF8
        
        # Register the task
        Register-ScheduledTask -Xml (Get-Content $TempXMLPath -Raw) -TaskName $AutoStartTaskName
        
        # Clean up temp file
        Remove-Item $TempXMLPath -Force -ErrorAction SilentlyContinue
        
        Write-InstallLog "Auto-Start task installed successfully" -Level Success
        return $true
    }
    catch {
        Write-InstallLog "Failed to install Auto-Start task: $_" -Level Error
        return $false
    }
}

function Install-HealthMonitorTask {
    try {
        Write-InstallLog "Installing PM2 Health Monitor task..." -Level Info
        
        # Check if task already exists
        $ExistingTask = Get-ScheduledTask -TaskName $HealthMonitorTaskName -ErrorAction SilentlyContinue
        if ($ExistingTask -and -not $Force) {
            Write-InstallLog "Health Monitor task already exists. Use -Force to overwrite." -Level Warning
            return $false
        }
        
        if ($ExistingTask) {
            Write-InstallLog "Removing existing Health Monitor task..." -Level Info
            Unregister-ScheduledTask -TaskName $HealthMonitorTaskName -Confirm:$false
        }
        
        # Create Health Monitor task
        $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$(Join-Path $ScriptPath 'pm2-health-monitor.ps1')`" -LogPath `"$LogPath`""
        $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 365)
        $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd -MultipleInstances IgnoreNew
        
        Register-ScheduledTask -TaskName $HealthMonitorTaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description "StrangematicHub PM2 Health Monitor - Monitors PM2 and n8n health every 5 minutes with auto-recovery capabilities"
        
        Write-InstallLog "Health Monitor task installed successfully" -Level Success
        return $true
    }
    catch {
        Write-InstallLog "Failed to install Health Monitor task: $_" -Level Error
        return $false
    }
}

function Uninstall-Tasks {
    Write-InstallLog "Uninstalling StrangematicHub PM2 tasks..." -Level Info
    
    $UninstallSuccess = $true
    
    # Remove Auto-Start task
    try {
        $AutoStartTask = Get-ScheduledTask -TaskName $AutoStartTaskName -ErrorAction SilentlyContinue
        if ($AutoStartTask) {
            Unregister-ScheduledTask -TaskName $AutoStartTaskName -Confirm:$false
            Write-InstallLog "Auto-Start task removed successfully" -Level Success
        }
        else {
            Write-InstallLog "Auto-Start task not found" -Level Info
        }
    }
    catch {
        Write-InstallLog "Failed to remove Auto-Start task: $_" -Level Error
        $UninstallSuccess = $false
    }
    
    # Remove Health Monitor task
    try {
        $HealthMonitorTask = Get-ScheduledTask -TaskName $HealthMonitorTaskName -ErrorAction SilentlyContinue
        if ($HealthMonitorTask) {
            Unregister-ScheduledTask -TaskName $HealthMonitorTaskName -Confirm:$false
            Write-InstallLog "Health Monitor task removed successfully" -Level Success
        }
        else {
            Write-InstallLog "Health Monitor task not found" -Level Info
        }
    }
    catch {
        Write-InstallLog "Failed to remove Health Monitor task: $_" -Level Error
        $UninstallSuccess = $false
    }
    
    return $UninstallSuccess
}

function Test-Installation {
    Write-InstallLog "Testing installation..." -Level Info
    
    $TestResults = @{
        AutoStartTaskExists = $false
        HealthMonitorTaskExists = $false
        AutoStartTaskEnabled = $false
        HealthMonitorTaskEnabled = $false
        ScriptExecutionTest = $false
        OverallSuccess = $false
    }
    
    # Test Auto-Start task
    try {
        $AutoStartTask = Get-ScheduledTask -TaskName $AutoStartTaskName -ErrorAction SilentlyContinue
        $TestResults.AutoStartTaskExists = $AutoStartTask -ne $null
        $TestResults.AutoStartTaskEnabled = $AutoStartTask.State -eq "Ready"
        
        Write-InstallLog "Auto-Start task exists: $($TestResults.AutoStartTaskExists)" -Level $(if ($TestResults.AutoStartTaskExists) { "Success" } else { "Error" })
        Write-InstallLog "Auto-Start task enabled: $($TestResults.AutoStartTaskEnabled)" -Level $(if ($TestResults.AutoStartTaskEnabled) { "Success" } else { "Error" })
    }
    catch {
        Write-InstallLog "Failed to test Auto-Start task: $_" -Level Error
    }
    
    # Test Health Monitor task
    try {
        $HealthMonitorTask = Get-ScheduledTask -TaskName $HealthMonitorTaskName -ErrorAction SilentlyContinue
        $TestResults.HealthMonitorTaskExists = $HealthMonitorTask -ne $null
        $TestResults.HealthMonitorTaskEnabled = $HealthMonitorTask.State -eq "Ready"
        
        Write-InstallLog "Health Monitor task exists: $($TestResults.HealthMonitorTaskExists)" -Level $(if ($TestResults.HealthMonitorTaskExists) { "Success" } else { "Error" })
        Write-InstallLog "Health Monitor task enabled: $($TestResults.HealthMonitorTaskEnabled)" -Level $(if ($TestResults.HealthMonitorTaskEnabled) { "Success" } else { "Error" })
    }
    catch {
        Write-InstallLog "Failed to test Health Monitor task: $_" -Level Error
    }
    
    # Test script execution
    try {
        Write-InstallLog "Testing script execution..." -Level Info
        $HealthMonitorScript = Join-Path $ScriptPath "pm2-health-monitor.ps1"
        
        # Run health monitor once to test
        $TestProcess = Start-Process -FilePath "PowerShell.exe" -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$HealthMonitorScript`"", "-RunOnce", "-LogPath", "`"$LogPath`"" -Wait -PassThru -WindowStyle Hidden
        
        $TestResults.ScriptExecutionTest = $TestProcess.ExitCode -eq 0
        Write-InstallLog "Script execution test: $($TestResults.ScriptExecutionTest)" -Level $(if ($TestResults.ScriptExecutionTest) { "Success" } else { "Warning" })
    }
    catch {
        Write-InstallLog "Script execution test failed: $_" -Level Warning
        $TestResults.ScriptExecutionTest = $false
    }
    
    # Overall success
    $TestResults.OverallSuccess = $TestResults.AutoStartTaskExists -and $TestResults.HealthMonitorTaskExists -and $TestResults.AutoStartTaskEnabled -and $TestResults.HealthMonitorTaskEnabled
    
    Write-InstallLog "Overall installation test: $($TestResults.OverallSuccess)" -Level $(if ($TestResults.OverallSuccess) { "Success" } else { "Warning" })
    
    return $TestResults
}

function Show-InstallationSummary {
    param(
        [hashtable]$TestResults
    )
    
    Write-InstallLog "=== Installation Summary ===" -Level Info
    Write-InstallLog "Installation completed at: $(Get-Date)" -Level Info
    Write-InstallLog "Log file location: $LogFile" -Level Info
    Write-InstallLog "" -Level Info
    Write-InstallLog "Installed Tasks:" -Level Info
    Write-InstallLog "  - $AutoStartTaskName (Auto-Start on boot)" -Level Info
    Write-InstallLog "  - $HealthMonitorTaskName (Health monitoring every 5 minutes)" -Level Info
    Write-InstallLog "" -Level Info
    Write-InstallLog "Next Steps:" -Level Info
    Write-InstallLog "  1. Restart your computer to test auto-start functionality" -Level Info
    Write-InstallLog "  2. Monitor logs in: $LogPath" -Level Info
    Write-InstallLog "  3. Use Task Scheduler to manually run tasks for testing" -Level Info
    Write-InstallLog "  4. Check Event Viewer (Application log) for StrangematicHub events" -Level Info
    Write-InstallLog "" -Level Info
    Write-InstallLog "Manual Testing Commands:" -Level Info
    Write-InstallLog "  Start-ScheduledTask -TaskName '$AutoStartTaskName'" -Level Info
    Write-InstallLog "  Start-ScheduledTask -TaskName '$HealthMonitorTaskName'" -Level Info
    Write-InstallLog "=== End Summary ===" -Level Info
}

# Main execution
try {
    Write-InstallLog "=== StrangematicHub PM2 Auto-Startup Installation Started ===" -Level Info
    Write-InstallLog "Installation version: 1.0.0" -Level Info
    Write-InstallLog "Script path: $ScriptPath" -Level Info
    Write-InstallLog "Log path: $LogPath" -Level Info
    
    if ($TestOnly) {
        Write-InstallLog "Running in test-only mode..." -Level Info
        $TestResults = Test-Installation
        exit $(if ($TestResults.OverallSuccess) { 0 } else { 1 })
    }
    
    if ($Uninstall) {
        Write-InstallLog "Running in uninstall mode..." -Level Info
        $UninstallResult = Uninstall-Tasks
        Write-InstallLog "Uninstallation completed: $UninstallResult" -Level $(if ($UninstallResult) { "Success" } else { "Error" })
        exit $(if ($UninstallResult) { 0 } else { 1 })
    }
    
    # Check prerequisites
    $Prerequisites = Test-Prerequisites
    
    $CriticalIssues = @()
    if (-not $Prerequisites.IsAdmin) { $CriticalIssues += "Administrator privileges required" }
    if (-not $Prerequisites.PowerShellVersion) { $CriticalIssues += "PowerShell 5.1 or higher required" }
    if (-not $Prerequisites.TaskSchedulerAvailable) { $CriticalIssues += "Task Scheduler not available" }
    if (-not $Prerequisites.ScriptFilesExist) { $CriticalIssues += "Required script files missing" }
    
    if ($CriticalIssues.Count -gt 0) {
        Write-InstallLog "Critical issues found:" -Level Error
        foreach ($Issue in $CriticalIssues) {
            Write-InstallLog "  - $Issue" -Level Error
        }
        Write-InstallLog "Installation cannot continue. Please resolve these issues and try again." -Level Error
        exit 1
    }
    
    # Warn about optional dependencies
    $Warnings = @()
    if (-not $Prerequisites.NodeJSInstalled) { $Warnings += "Node.js not found - PM2 and n8n may not work" }
    if (-not $Prerequisites.PM2Installed) { $Warnings += "PM2 not found - auto-startup will fail" }
    if (-not $Prerequisites.N8NInstalled) { $Warnings += "n8n not found - application startup will fail" }
    
    if ($Warnings.Count -gt 0) {
        Write-InstallLog "Warnings (installation will continue):" -Level Warning
        foreach ($Warning in $Warnings) {
            Write-InstallLog "  - $Warning" -Level Warning
        }
    }
    
    # Install Event Log source
    Install-EventLogSource | Out-Null
    
    # Install tasks with automatic force if tasks exist
    Write-InstallLog "Installing tasks..." -Level Info
    
    # Check if tasks already exist and set Force if needed
    $AutoStartExists = Get-ScheduledTask -TaskName $AutoStartTaskName -ErrorAction SilentlyContinue
    $HealthMonitorExists = Get-ScheduledTask -TaskName $HealthMonitorTaskName -ErrorAction SilentlyContinue
    
    if (($AutoStartExists -or $HealthMonitorExists) -and -not $Force) {
        Write-InstallLog "Existing tasks detected. Automatically enabling Force mode to overwrite..." -Level Warning
        $Force = $true
    }
    
    $AutoStartInstalled = Install-AutoStartTask
    $HealthMonitorInstalled = Install-HealthMonitorTask
    
    if ($AutoStartInstalled -and $HealthMonitorInstalled) {
        Write-InstallLog "All tasks installed successfully" -Level Success
        
        # Test installation
        $TestResults = Test-Installation
        
        # Show summary
        Show-InstallationSummary -TestResults $TestResults
        
        Write-InstallLog "=== Installation Completed Successfully ===" -Level Success
        exit 0
    }
    else {
        Write-InstallLog "Installation completed with errors" -Level Error
        Write-InstallLog "Auto-Start task: $AutoStartInstalled" -Level $(if ($AutoStartInstalled) { "Success" } else { "Error" })
        Write-InstallLog "Health Monitor task: $HealthMonitorInstalled" -Level $(if ($HealthMonitorInstalled) { "Success" } else { "Error" })
        exit 1
    }
}
catch {
    Write-InstallLog "Critical error during installation: $_" -Level Error
    Write-InstallLog "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}
finally {
    Write-InstallLog "Installation script execution completed at $(Get-Date)" -Level Info
}