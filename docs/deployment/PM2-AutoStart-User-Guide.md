# Hướng Dẫn Sử Dụng Hàng Ngày - PM2 Auto-Startup Solution

## Tổng Quan

Tài liệu này cung cấp hướng dẫn sử dụng hàng ngày cho StrangematicHub PM2 Auto-Startup solution. Bao gồm các tác vụ thường xuyên, monitoring, maintenance, và troubleshooting.

## Quick Reference Commands

### 🚀 Essential Commands

```powershell
# Import PowerShell module
cd C:\Github\n8n-tp\scripts
Import-Module .\StrangematicPM2Management.psm1 -Force

# Check system status
Get-PM2Status
Get-N8NStatus
Invoke-HealthCheck

# Start/Stop services
Start-PM2Daemon
Start-N8NApplication
Stop-N8NApplication
Restart-N8NApplication
```

### 📊 Monitoring Commands

```powershell
# View logs
Get-PM2Logs -Lines 50
Get-PM2ProcessDetails

# Run health check
Invoke-HealthCheck

# Test system
.\test-pm2-autostart.ps1 -SkipInteractive
```

### 🔧 Management Commands

```powershell
# Task Scheduler management
Get-ScheduledTask -TaskName "*StrangematicHub*"
Start-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart"
Start-ScheduledTask -TaskName "StrangematicHub-PM2-HealthMonitor"

# Reset PM2 (emergency)
Reset-PM2
```

## Daily Operations

### 1. Morning Health Check

Mỗi sáng, thực hiện quick health check:

```powershell
# Navigate to scripts directory
cd C:\Github\n8n-tp\scripts

# Import module
Import-Module .\StrangematicPM2Management.psm1 -Force

# Comprehensive health check
$health = Invoke-HealthCheck
Write-Host "Overall Status: $($health.Overall)" -ForegroundColor $(if($health.Overall -eq "Healthy") {"Green"} else {"Red"})
Write-Host "PM2 Status: $($health.PM2Status)" -ForegroundColor Cyan
Write-Host "n8n Status: $($health.N8NStatus)" -ForegroundColor Cyan

# Check for issues
if ($health.Issues.Count -gt 0) {
    Write-Host "`nIssues Found:" -ForegroundColor Yellow
    $health.Issues | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
}

# Check recommendations
if ($health.Recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $health.Recommendations | ForEach-Object { Write-Host "  • $_" -ForegroundColor Yellow }
}
```

### 2. Checking Service Status

#### PM2 Daemon Status
```powershell
$pm2Status = Get-PM2Status
if ($pm2Status.IsRunning) {
    Write-Host "✓ PM2 Daemon: Running ($($pm2Status.ProcessCount) processes)" -ForegroundColor Green
    
    # List all processes
    $pm2Status.Processes | ForEach-Object {
        $color = if ($_.Status -eq "online") { "Green" } else { "Red" }
        Write-Host "  Process $($_.Id): $($_.Name) - $($_.Status)" -ForegroundColor $color
    }
} else {
    Write-Host "✗ PM2 Daemon: Not Running" -ForegroundColor Red
    if ($pm2Status.Error) {
        Write-Host "  Error: $($pm2Status.Error)" -ForegroundColor Red
    }
}
```

#### n8n Application Status
```powershell
$n8nStatus = Get-N8NStatus
if ($n8nStatus.IsRunning) {
    Write-Host "✓ n8n Application: Running" -ForegroundColor Green
    if ($n8nStatus.ProcessInfo) {
        Write-Host "  Process ID: $($n8nStatus.ProcessInfo.Id)" -ForegroundColor Cyan
        Write-Host "  Status: $($n8nStatus.ProcessInfo.Status)" -ForegroundColor Cyan
        Write-Host "  Restarts: $($n8nStatus.ProcessInfo.Restart)" -ForegroundColor Cyan
    }
} else {
    Write-Host "✗ n8n Application: Not Running" -ForegroundColor Red
    if ($n8nStatus.Error) {
        Write-Host "  Error: $($n8nStatus.Error)" -ForegroundColor Red
    }
}
```

### 3. Log Review

#### View Recent Logs
```powershell
# PM2 application logs
$logs = Get-PM2Logs -Lines 20
if ($logs.Success) {
    Write-Host "Recent PM2 Logs:" -ForegroundColor Cyan
    $logs.Logs | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "Failed to get logs: $($logs.Error)" -ForegroundColor Red
}
```

#### System Log Files
```powershell
# Auto-startup logs
$logPath = "C:\ProgramData\StrangematicHub\Logs"
$latestStartupLog = Get-ChildItem "$logPath\pm2-auto-startup-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latestStartupLog) {
    Write-Host "Latest Auto-Startup Log: $($latestStartupLog.Name)" -ForegroundColor Cyan
    Get-Content $latestStartupLog.FullName -Tail 10
}

# Health monitor logs
$latestHealthLog = Get-ChildItem "$logPath\pm2-health-monitor-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latestHealthLog) {
    Write-Host "`nLatest Health Monitor Log: $($latestHealthLog.Name)" -ForegroundColor Cyan
    Get-Content $latestHealthLog.FullName -Tail 10
}
```

## Common Management Tasks

### 1. Starting Services

#### Start PM2 Daemon
```powershell
$result = Start-PM2Daemon
if ($result.Success) {
    Write-Host "✓ PM2 Daemon started successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to start PM2 Daemon: $($result.Error)" -ForegroundColor Red
}
```

#### Start n8n Application
```powershell
$result = Start-N8NApplication
if ($result.Success) {
    Write-Host "✓ n8n Application started successfully" -ForegroundColor Green
    
    # Wait and verify
    Start-Sleep -Seconds 10
    $status = Get-N8NStatus
    if ($status.IsRunning) {
        Write-Host "✓ n8n Application verified running" -ForegroundColor Green
    } else {
        Write-Host "⚠ n8n Application may have issues" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Failed to start n8n Application: $($result.Error)" -ForegroundColor Red
}
```

### 2. Stopping Services

#### Stop n8n Application
```powershell
$result = Stop-N8NApplication
if ($result.Success) {
    Write-Host "✓ n8n Application stopped successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to stop n8n Application: $($result.Error)" -ForegroundColor Red
}
```

#### Emergency Stop (Kill PM2)
```powershell
# Only use in emergency situations
Write-Host "⚠ Emergency stop - killing PM2 daemon" -ForegroundColor Yellow
$result = Reset-PM2
if ($result.Success) {
    Write-Host "✓ PM2 reset completed" -ForegroundColor Green
} else {
    Write-Host "✗ PM2 reset failed: $($result.Error)" -ForegroundColor Red
}
```

### 3. Restarting Services

#### Restart n8n Application
```powershell
Write-Host "Restarting n8n application..." -ForegroundColor Yellow
$result = Restart-N8NApplication
if ($result.Success) {
    Write-Host "✓ n8n Application restarted successfully" -ForegroundColor Green
    
    # Verify restart
    Start-Sleep -Seconds 15
    $status = Get-N8NStatus
    if ($status.IsRunning) {
        Write-Host "✓ n8n Application is running after restart" -ForegroundColor Green
    } else {
        Write-Host "✗ n8n Application failed to start after restart" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Failed to restart n8n Application: $($result.Error)" -ForegroundColor Red
}
```

#### Full System Restart
```powershell
Write-Host "Performing full system restart..." -ForegroundColor Yellow

# Step 1: Stop n8n
Write-Host "1. Stopping n8n..." -ForegroundColor Cyan
Stop-N8NApplication

# Step 2: Reset PM2
Write-Host "2. Resetting PM2..." -ForegroundColor Cyan
Reset-PM2

# Step 3: Wait
Write-Host "3. Waiting for cleanup..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Step 4: Start PM2
Write-Host "4. Starting PM2..." -ForegroundColor Cyan
Start-PM2Daemon

# Step 5: Start n8n
Write-Host "5. Starting n8n..." -ForegroundColor Cyan
Start-N8NApplication

# Step 6: Verify
Write-Host "6. Verifying system..." -ForegroundColor Cyan
Start-Sleep -Seconds 15
$health = Invoke-HealthCheck
Write-Host "System Status: $($health.Overall)" -ForegroundColor $(if($health.Overall -eq "Healthy") {"Green"} else {"Red"})
```

## Monitoring và Performance

### 1. Performance Monitoring

#### System Resource Usage
```powershell
# Get system metrics
$cpu = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
$memory = Get-WmiObject -Class Win32_OperatingSystem | ForEach-Object {
    [math]::Round((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / $_.TotalVisibleMemorySize) * 100, 2)
}
$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | Where-Object { $_.DeviceID -eq "C:" } | ForEach-Object {
    [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)
}

Write-Host "System Performance:" -ForegroundColor Cyan
Write-Host "  CPU Usage: $cpu%" -ForegroundColor $(if($cpu -gt 80) {"Red"} elseif($cpu -gt 60) {"Yellow"} else {"Green"})
Write-Host "  Memory Usage: $memory%" -ForegroundColor $(if($memory -gt 90) {"Red"} elseif($memory -gt 75) {"Yellow"} else {"Green"})
Write-Host "  Disk Usage: $disk%" -ForegroundColor $(if($disk -gt 90) {"Red"} elseif($disk -gt 80) {"Yellow"} else {"Green"})
```

#### Process Details
```powershell
$details = Get-PM2ProcessDetails
if ($details.Success) {
    Write-Host "PM2 Process Details:" -ForegroundColor Cyan
    $details.Details | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "Failed to get process details: $($details.Error)" -ForegroundColor Red
}
```

### 2. Health Monitoring

#### Automated Health Check
```powershell
function Invoke-DailyHealthCheck {
    Write-Host "=== Daily Health Check ===" -ForegroundColor Cyan
    
    $health = Invoke-HealthCheck
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Create health report
    $report = @"
Health Check Report - $timestamp
=====================================
Overall Status: $($health.Overall)
PM2 Status: $($health.PM2Status)
n8n Status: $($health.N8NStatus)

"@
    
    if ($health.Issues.Count -gt 0) {
        $report += "Issues Found:`n"
        $health.Issues | ForEach-Object { $report += "  • $_`n" }
        $report += "`n"
    }
    
    if ($health.Recommendations.Count -gt 0) {
        $report += "Recommendations:`n"
        $health.Recommendations | ForEach-Object { $report += "  • $_`n" }
    }
    
    # Save report
    $reportPath = "C:\ProgramData\StrangematicHub\Reports\daily-health-$(Get-Date -Format 'yyyyMMdd').txt"
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host $report
    Write-Host "Report saved to: $reportPath" -ForegroundColor Green
    
    return $health
}

# Run daily health check
Invoke-DailyHealthCheck
```

### 3. Task Scheduler Monitoring

#### Check Scheduled Tasks
```powershell
Write-Host "Scheduled Tasks Status:" -ForegroundColor Cyan

# Auto-Start Task
$autoStartTask = Get-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart" -ErrorAction SilentlyContinue
if ($autoStartTask) {
    $taskInfo = Get-ScheduledTaskInfo -TaskName "StrangematicHub-PM2-AutoStart"
    Write-Host "  Auto-Start Task:" -ForegroundColor Yellow
    Write-Host "    State: $($autoStartTask.State)" -ForegroundColor $(if($autoStartTask.State -eq "Ready") {"Green"} else {"Red"})
    Write-Host "    Last Run: $($taskInfo.LastRunTime)" -ForegroundColor Cyan
    Write-Host "    Last Result: $($taskInfo.LastTaskResult)" -ForegroundColor $(if($taskInfo.LastTaskResult -eq 0) {"Green"} else {"Red"})
    Write-Host "    Next Run: $($taskInfo.NextRunTime)" -ForegroundColor Cyan
} else {
    Write-Host "  ✗ Auto-Start Task: Not Found" -ForegroundColor Red
}

# Health Monitor Task
$healthTask = Get-ScheduledTask -TaskName "StrangematicHub-PM2-HealthMonitor" -ErrorAction SilentlyContinue
if ($healthTask) {
    $taskInfo = Get-ScheduledTaskInfo -TaskName "StrangematicHub-PM2-HealthMonitor"
    Write-Host "  Health Monitor Task:" -ForegroundColor Yellow
    Write-Host "    State: $($healthTask.State)" -ForegroundColor $(if($healthTask.State -eq "Ready") {"Green"} else {"Red"})
    Write-Host "    Last Run: $($taskInfo.LastRunTime)" -ForegroundColor Cyan
    Write-Host "    Last Result: $($taskInfo.LastTaskResult)" -ForegroundColor $(if($taskInfo.LastTaskResult -eq 0) {"Green"} else {"Red"})
    Write-Host "    Next Run: $($taskInfo.NextRunTime)" -ForegroundColor Cyan
} else {
    Write-Host "  ✗ Health Monitor Task: Not Found" -ForegroundColor Red
}
```

## Troubleshooting Guide

### 1. Common Issues và Solutions

#### Issue: PM2 Daemon Not Starting
```powershell
# Diagnosis
Write-Host "Diagnosing PM2 Daemon issues..." -ForegroundColor Yellow

# Check if PM2 is installed
try {
    $pm2Version = & pm2 --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ PM2 is installed: $pm2Version" -ForegroundColor Green
    } else {
        Write-Host "✗ PM2 is not accessible" -ForegroundColor Red
        Write-Host "Solution: Install PM2 with 'npm install -g pm2'" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ PM2 command failed: $_" -ForegroundColor Red
}

# Check Node.js
try {
    $nodeVersion = & node --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Node.js is available: $nodeVersion" -ForegroundColor Green
    } else {
        Write-Host "✗ Node.js is not accessible" -ForegroundColor Red
        Write-Host "Solution: Install Node.js from https://nodejs.org" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Node.js command failed: $_" -ForegroundColor Red
}

# Try to start PM2
Write-Host "Attempting to start PM2..." -ForegroundColor Cyan
$result = Start-PM2Daemon
if ($result.Success) {
    Write-Host "✓ PM2 started successfully" -ForegroundColor Green
} else {
    Write-Host "✗ PM2 start failed: $($result.Error)" -ForegroundColor Red
    Write-Host "Try manual PM2 reset..." -ForegroundColor Yellow
    Reset-PM2
}
```

#### Issue: n8n Application Won't Start
```powershell
# Diagnosis
Write-Host "Diagnosing n8n Application issues..." -ForegroundColor Yellow

# Check if n8n is installed
try {
    $n8nVersion = & n8n --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ n8n is installed: $n8nVersion" -ForegroundColor Green
    } else {
        Write-Host "✗ n8n is not accessible" -ForegroundColor Red
        Write-Host "Solution: Install n8n with 'npm install -g n8n'" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ n8n command failed: $_" -ForegroundColor Red
}

# Check PM2 status first
$pm2Status = Get-PM2Status
if (-not $pm2Status.IsRunning) {
    Write-Host "✗ PM2 daemon is not running - start PM2 first" -ForegroundColor Red
    Start-PM2Daemon
    Start-Sleep -Seconds 5
}

# Check port availability
$portInUse = Get-NetTCPConnection -LocalPort 5678 -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Host "⚠ Port 5678 is in use by another process" -ForegroundColor Yellow
    Write-Host "Process: $($portInUse.OwningProcess)" -ForegroundColor Cyan
    Write-Host "Solution: Stop the conflicting process or change n8n port" -ForegroundColor Yellow
}

# Try to start n8n
Write-Host "Attempting to start n8n..." -ForegroundColor Cyan
$result = Start-N8NApplication
if ($result.Success) {
    Write-Host "✓ n8n started successfully" -ForegroundColor Green
    
    # Verify after delay
    Start-Sleep -Seconds 15
    $status = Get-N8NStatus
    if ($status.IsRunning) {
        Write-Host "✓ n8n is running and stable" -ForegroundColor Green
    } else {
        Write-Host "⚠ n8n started but may be unstable" -ForegroundColor Yellow
        Write-Host "Check logs for details" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ n8n start failed: $($result.Error)" -ForegroundColor Red
}
```

#### Issue: Task Scheduler Tasks Not Running
```powershell
# Check task status
Write-Host "Checking Task Scheduler issues..." -ForegroundColor Yellow

$tasks = @("StrangematicHub-PM2-AutoStart", "StrangematicHub-PM2-HealthMonitor")
foreach ($taskName in $tasks) {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName
        Write-Host "Task: $taskName" -ForegroundColor Cyan
        Write-Host "  State: $($task.State)" -ForegroundColor $(if($task.State -eq "Ready") {"Green"} else {"Red"})
        Write-Host "  Last Result: $($taskInfo.LastTaskResult)" -ForegroundColor $(if($taskInfo.LastTaskResult -eq 0) {"Green"} else {"Red"})
        
        if ($task.State -ne "Ready") {
            Write-Host "  Solution: Enable the task" -ForegroundColor Yellow
            Enable-ScheduledTask -TaskName $taskName
        }
        
        if ($taskInfo.LastTaskResult -ne 0) {
            Write-Host "  Solution: Check task configuration and logs" -ForegroundColor Yellow
            Write-Host "  Manual test: Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor Cyan
        }
    } else {
        Write-Host "✗ Task not found: $taskName" -ForegroundColor Red
        Write-Host "  Solution: Reinstall tasks with install-pm2-autostart.ps1" -ForegroundColor Yellow
    }
}
```

### 2. Emergency Procedures

#### Complete System Reset
```powershell
function Invoke-EmergencyReset {
    Write-Host "=== EMERGENCY SYSTEM RESET ===" -ForegroundColor Red
    Write-Host "This will stop all services and restart them" -ForegroundColor Yellow
    
    $confirm = Read-Host "Continue? (y/N)"
    if ($confirm -ne 'y') {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        return
    }
    
    try {
        # Step 1: Kill all PM2 processes
        Write-Host "1. Killing PM2 processes..." -ForegroundColor Cyan
        & pm2 kill 2>$null
        
        # Step 2: Stop any remaining n8n processes
        Write-Host "2. Stopping n8n processes..." -ForegroundColor Cyan
        Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*n8n*" } | Stop-Process -Force
        
        # Step 3: Clear PM2 logs
        Write-Host "3. Clearing PM2 logs..." -ForegroundColor Cyan
        & pm2 flush 2>$null
        
        # Step 4: Wait for cleanup
        Write-Host "4. Waiting for cleanup..." -ForegroundColor Cyan
        Start-Sleep -Seconds 10
        
        # Step 5: Restart services
        Write-Host "5. Restarting services..." -ForegroundColor Cyan
        Start-PM2Daemon
        Start-Sleep -Seconds 5
        Start-N8NApplication
        
        # Step 6: Verify
        Write-Host "6. Verifying system..." -ForegroundColor Cyan
        Start-Sleep -Seconds 15
        $health = Invoke-HealthCheck
        
        if ($health.Overall -eq "Healthy") {
            Write-Host "✓ Emergency reset completed successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠ Emergency reset completed with issues" -ForegroundColor Yellow
            Write-Host "Issues: $($health.Issues -join ', ')" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "✗ Emergency reset failed: $_" -ForegroundColor Red
    }
}

# Uncomment to run emergency reset
# Invoke-EmergencyReset
```

#### Reinstall Tasks
```powershell
function Invoke-TaskReinstall {
    Write-Host "=== TASK REINSTALLATION ===" -ForegroundColor Yellow
    
    $confirm = Read-Host "This will remove and recreate scheduled tasks. Continue? (y/N)"
    if ($confirm -ne 'y') {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        return
    }
    
    try {
        # Navigate to scripts directory
        $scriptsPath = "C:\Github\n8n-tp\scripts"
        if (-not (Test-Path $scriptsPath)) {
            Write-Host "✗ Scripts directory not found: $scriptsPath" -ForegroundColor Red
            return
        }
        
        Set-Location $scriptsPath
        
        # Uninstall existing tasks
        Write-Host "1. Uninstalling existing tasks..." -ForegroundColor Cyan
        .\install-pm2-autostart.ps1 -Uninstall
        
        # Wait
        Start-Sleep -Seconds 3
        
        # Reinstall tasks
        Write-Host "2. Reinstalling tasks..." -ForegroundColor Cyan
        .\install-pm2-autostart.ps1 -Force
        
        # Verify
        Write-Host "3. Verifying installation..." -ForegroundColor Cyan
        .\install-pm2-autostart.ps1 -TestOnly
        
        Write-Host "✓ Task reinstallation completed" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Task reinstallation failed: $_" -ForegroundColor Red
    }
}

# Uncomment to run task reinstallation
# Invoke-TaskReinstall
```

## Performance Tuning

### 1. Optimization Settings

#### PM2 Configuration
```powershell
# Optimize PM2 for n8n
function Optimize-PM2Configuration {
    Write-Host "Optimizing PM2 configuration..." -ForegroundColor Cyan
    
    # Stop n8n if running
    Stop-N8NApplication
    
    # Start with optimized settings
    $result = Start-N8NApplication -WorkingDirectory "C:\Github\n8n-tp" -ProcessName "n8n"
    
    if ($result.Success) {
        Write-Host "✓ n8n started with optimized configuration" -ForegroundColor Green
        
        # Set memory limit
        & pm2 set pm2:max-memory-restart 1G
        
        # Enable monitoring
        & pm2 set pm2:autodump true
        & pm2 set pm2:autorestart true
        
        Write-Host "✓ PM2 optimization completed" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to start n8n with optimization" -ForegroundColor Red
    }
}
```

#### System Resource Monitoring
```powershell
function Start-ResourceMonitoring {
    param(
        [int]$IntervalSeconds = 60,
        [int]$DurationMinutes = 10
    )
    
    Write-Host "Starting resource monitoring for $DurationMinutes minutes..." -ForegroundColor Cyan
    
    $endTime = (Get-Date).AddMinutes($DurationMinutes)
    $logFile = "C:\ProgramData\StrangematicHub\Logs\resource-monitor-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    
    # Create CSV header
    "Timestamp,CPU%,Memory%,Disk%,PM2_Running,N8N_Running" | Out-File -FilePath $logFile -Encoding UTF8
    
    while ((Get-Date) -lt $endTime) {
        # Get system metrics
        $cpu = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
        $memory = Get-WmiObject -Class Win32_OperatingSystem | ForEach-Object {
            [math]::Round((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / $_.TotalVisibleMemorySize) * 100, 2)
        }
        $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | Where-Object { $_.DeviceID -eq "C:" } | ForEach-Object {
            [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)
        }
        
        # Get service status
        $pm2Status = (Get-PM2Status).IsRunning
        $n8nStatus = (Get-N8NStatus).IsRunning
        
        # Log data
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp,$cpu,$memory,$disk,$pm2Status,$n8nStatus" | Out-File -FilePath $logFile -Append -Encoding UTF8
        
        # Display current status
        Write-Host "[$timestamp] CPU: $cpu%, Memory: $memory%, Disk: $disk%, PM2: $pm2Status, n8n: $n8nStatus" -ForegroundColor Cyan
        
        Start-Sleep -Seconds $IntervalSeconds
    }
    
    Write-Host "Resource monitoring completed. Log saved to: $logFile" -ForegroundColor Green
}

# Example usage:
# Start-ResourceMonitoring -IntervalSeconds 30 -DurationMinutes 5
```

## Security Considerations

### 1. Access Control

#### Check Service Account Permissions
```powershell
# Verify SYSTEM account has necessary permissions
$systemSid = "S-1-5-18"
Write-Host "Checking SYSTEM account permissions..." -ForegroundColor Cyan

# Check if tasks run as SYSTEM
$autoStartTask = Get-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart" -ErrorAction SilentlyContinue
if ($autoStartTask) {
    $principal = $autoStartTask.Principal
    if ($principal.UserId -eq $systemSid) {
        Write-Host "✓ Auto-Start task runs as SYSTEM" -ForegroundColor Green
    } else {
        Write-Host "⚠ Auto-Start task runs as: $($principal.UserId)" -ForegroundColor Yellow
    }
}
```

#### Audit Log Access
```powershell
# Check log directory permissions
$logPath = "C:\ProgramData\StrangematicHub\Logs"
if (Test-Path $logPath) {
    $acl = Get-Acl $logPath
    Write-Host "Log directory permissions:" -ForegroundColor Cyan
    $acl.Access | ForEach-Object {
        Write-Host "  $($_.IdentityReference): $($_.FileSystemRights)" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Log directory not found: $logPath" -ForegroundColor Red
}
```

### 2. Network Security

#### Check n8n Network Configuration
```powershell
# Check n8n listening ports
Write-Host "Checking n8n network configuration..." -ForegroundColor Cyan

$n8nConnections = Get-NetTCPConnection | Where-Object { $_.LocalPort -eq 5678 -or $_.LocalPort -eq 5679 }
if ($n8nConnections) {
    Write-Host "n8n Network Connections:" -ForegroundColor Yellow
    $n8nConnections | ForEach-Object {
        Write-Host "  Port $($_.LocalPort): $($_.State) (Process: $($_.OwningProcess))" -ForegroundColor Cyan
    }
} else {
Write-Host "✗ No n8n network connections found" -ForegroundColor Red
}

# Check firewall rules
Write-Host "`nChecking Windows Firewall rules..." -ForegroundColor Cyan
$firewallRules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*n8n*" -or $_.DisplayName -like "*5678*" }
if ($firewallRules) {
    Write-Host "n8n Firewall Rules:" -ForegroundColor Yellow
    $firewallRules | ForEach-Object {
        Write-Host "  $($_.DisplayName): $($_.Enabled) ($($_.Direction))" -ForegroundColor Cyan
    }
} else {
    Write-Host "⚠ No specific n8n firewall rules found" -ForegroundColor Yellow
    Write-Host "Consider creating firewall rules for port 5678" -ForegroundColor Yellow
}
```

## Maintenance Schedule

### Daily Tasks (5 minutes)
```powershell
# Daily maintenance script
function Invoke-DailyMaintenance {
    Write-Host "=== DAILY MAINTENANCE ===" -ForegroundColor Cyan
    
    # 1. Health check
    Write-Host "1. Running health check..." -ForegroundColor Yellow
    $health = Invoke-HealthCheck
    Write-Host "   Overall Status: $($health.Overall)" -ForegroundColor $(if($health.Overall -eq "Healthy") {"Green"} else {"Red"})
    
    # 2. Check disk space
    Write-Host "2. Checking disk space..." -ForegroundColor Yellow
    $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | Where-Object { $_.DeviceID -eq "C:" } | ForEach-Object {
        [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)
    }
    Write-Host "   Disk Usage: $disk%" -ForegroundColor $(if($disk -gt 90) {"Red"} elseif($disk -gt 80) {"Yellow"} else {"Green"})
    
    # 3. Check recent logs for errors
    Write-Host "3. Checking recent logs..." -ForegroundColor Yellow
    $logPath = "C:\ProgramData\StrangematicHub\Logs"
    $recentLogs = Get-ChildItem "$logPath\*.log" | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-24) }
    $errorCount = 0
    foreach ($log in $recentLogs) {
        $errors = Get-Content $log.FullName | Where-Object { $_ -like "*ERROR*" -or $_ -like "*FAIL*" }
        $errorCount += $errors.Count
    }
    Write-Host "   Recent Errors: $errorCount" -ForegroundColor $(if($errorCount -eq 0) {"Green"} elseif($errorCount -lt 5) {"Yellow"} else {"Red"})
    
    # 4. Verify scheduled tasks
    Write-Host "4. Verifying scheduled tasks..." -ForegroundColor Yellow
    $tasks = @("StrangematicHub-PM2-AutoStart", "StrangematicHub-PM2-HealthMonitor")
    $taskIssues = 0
    foreach ($taskName in $tasks) {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if (-not $task -or $task.State -ne "Ready") {
            $taskIssues++
        }
    }
    Write-Host "   Task Issues: $taskIssues" -ForegroundColor $(if($taskIssues -eq 0) {"Green"} else {"Red"})
    
    Write-Host "=== DAILY MAINTENANCE COMPLETED ===" -ForegroundColor Cyan
}

# Run daily maintenance
Invoke-DailyMaintenance
```

### Weekly Tasks (15 minutes)
```powershell
# Weekly maintenance script
function Invoke-WeeklyMaintenance {
    Write-Host "=== WEEKLY MAINTENANCE ===" -ForegroundColor Cyan
    
    # 1. Comprehensive test
    Write-Host "1. Running comprehensive test..." -ForegroundColor Yellow
    Set-Location "C:\Github\n8n-tp\scripts"
    $testResult = .\test-pm2-autostart.ps1 -SkipInteractive
    Write-Host "   Test Result: Exit Code $LASTEXITCODE" -ForegroundColor $(if($LASTEXITCODE -eq 0) {"Green"} else {"Red"})
    
    # 2. Log cleanup
    Write-Host "2. Cleaning old logs..." -ForegroundColor Yellow
    $logPath = "C:\ProgramData\StrangematicHub\Logs"
    $oldLogs = Get-ChildItem "$logPath\*.log" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
    $cleanedCount = $oldLogs.Count
    $oldLogs | Remove-Item -Force
    Write-Host "   Cleaned $cleanedCount old log files" -ForegroundColor Green
    
    # 3. Performance review
    Write-Host "3. Performance review..." -ForegroundColor Yellow
    $cpu = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
    $memory = Get-WmiObject -Class Win32_OperatingSystem | ForEach-Object {
        [math]::Round((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / $_.TotalVisibleMemorySize) * 100, 2)
    }
    Write-Host "   Average CPU: $cpu%, Memory: $memory%" -ForegroundColor Cyan
    
    # 4. Update check
    Write-Host "4. Checking for updates..." -ForegroundColor Yellow
    try {
        $nodeVersion = & node --version 2>$null
        $pm2Version = & pm2 --version 2>$null
        $n8nVersion = & n8n --version 2>$null
        Write-Host "   Node.js: $nodeVersion, PM2: $pm2Version, n8n: $n8nVersion" -ForegroundColor Cyan
    } catch {
        Write-Host "   Update check failed: $_" -ForegroundColor Red
    }
    
    Write-Host "=== WEEKLY MAINTENANCE COMPLETED ===" -ForegroundColor Cyan
}

# Run weekly maintenance
# Invoke-WeeklyMaintenance
```

### Monthly Tasks (30 minutes)
```powershell
# Monthly maintenance script
function Invoke-MonthlyMaintenance {
    Write-Host "=== MONTHLY MAINTENANCE ===" -ForegroundColor Cyan
    
    # 1. Full system backup
    Write-Host "1. Creating configuration backup..." -ForegroundColor Yellow
    $backupPath = "C:\ProgramData\StrangematicHub\Backups\$(Get-Date -Format 'yyyyMM')"
    New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
    
    # Backup scripts
    Copy-Item "C:\Github\n8n-tp\scripts\*.ps1" $backupPath -Force
    Copy-Item "C:\Github\n8n-tp\scripts\*.psm1" $backupPath -Force
    Copy-Item "C:\Github\n8n-tp\scripts\*.xml" $backupPath -Force
    
    # Export scheduled tasks
    Export-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart" | Out-File "$backupPath\AutoStart-Task.xml" -Encoding UTF8
    Export-ScheduledTask -TaskName "StrangematicHub-PM2-HealthMonitor" | Out-File "$backupPath\HealthMonitor-Task.xml" -Encoding UTF8
    
    Write-Host "   Backup created: $backupPath" -ForegroundColor Green
    
    # 2. Security audit
    Write-Host "2. Running security audit..." -ForegroundColor Yellow
    $securityIssues = 0
    
    # Check execution policy
    $execPolicy = Get-ExecutionPolicy
    if ($execPolicy -eq "Unrestricted") {
        Write-Host "   ⚠ Execution policy is unrestricted" -ForegroundColor Yellow
        $securityIssues++
    }
    
    # Check task permissions
    $autoStartTask = Get-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart" -ErrorAction SilentlyContinue
    if ($autoStartTask -and $autoStartTask.Principal.UserId -ne "S-1-5-18") {
        Write-Host "   ⚠ Auto-start task not running as SYSTEM" -ForegroundColor Yellow
        $securityIssues++
    }
    
    Write-Host "   Security Issues: $securityIssues" -ForegroundColor $(if($securityIssues -eq 0) {"Green"} else {"Yellow"})
    
    # 3. Performance optimization
    Write-Host "3. Performance optimization..." -ForegroundColor Yellow
    
    # Clear PM2 logs
    & pm2 flush 2>$null
    
    # Restart services for fresh start
    Write-Host "   Restarting services..." -ForegroundColor Cyan
    Restart-N8NApplication
    Start-Sleep -Seconds 15
    
    $health = Invoke-HealthCheck
    Write-Host "   Post-restart health: $($health.Overall)" -ForegroundColor $(if($health.Overall -eq "Healthy") {"Green"} else {"Red"})
    
    Write-Host "=== MONTHLY MAINTENANCE COMPLETED ===" -ForegroundColor Cyan
}

# Run monthly maintenance
# Invoke-MonthlyMaintenance
```

## Best Practices

### 1. Operational Best Practices

#### Regular Monitoring
- **Daily**: Quick health check và log review
- **Weekly**: Comprehensive testing và performance review
- **Monthly**: Full maintenance và security audit

#### Change Management
- **Always test changes** trong development environment trước
- **Backup configurations** trước khi thay đổi
- **Document all changes** và reasons
- **Have rollback plan** sẵn sàng

#### Incident Response
- **Monitor alerts** từ health monitoring system
- **Respond quickly** to critical issues
- **Document incidents** và resolutions
- **Review và improve** processes regularly

### 2. Security Best Practices

#### Access Control
```powershell
# Verify only authorized users can access scripts
$scriptsPath = "C:\Github\n8n-tp\scripts"
$acl = Get-Acl $scriptsPath
Write-Host "Scripts directory permissions:" -ForegroundColor Cyan
$acl.Access | Where-Object { $_.AccessControlType -eq "Allow" } | ForEach-Object {
    Write-Host "  $($_.IdentityReference): $($_.FileSystemRights)" -ForegroundColor Yellow
}
```

#### Log Security
```powershell
# Ensure logs are protected
$logPath = "C:\ProgramData\StrangematicHub\Logs"
$acl = Get-Acl $logPath
$acl.SetAccessRuleProtection($true, $false)
$acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")))
$acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")))
Set-Acl -Path $logPath -AclObject $acl
```

### 3. Performance Best Practices

#### Resource Management
- **Monitor system resources** regularly
- **Set appropriate limits** cho PM2 processes
- **Clean up old logs** định kỳ
- **Optimize startup sequence** để reduce boot time

#### Scaling Considerations
- **Single instance** cho development/testing
- **Multiple instances** có thể cần cho production
- **Load balancing** nếu cần high availability
- **Database optimization** cho better performance

## Useful Scripts và Aliases

### PowerShell Profile Setup
Thêm vào PowerShell profile để có quick access:

```powershell
# Add to $PROFILE
function pm2-status { 
    Import-Module "C:\Github\n8n-tp\scripts\StrangematicPM2Management.psm1" -Force
    Get-PM2Status 
}

function n8n-status { 
    Import-Module "C:\Github\n8n-tp\scripts\StrangematicPM2Management.psm1" -Force
    Get-N8NStatus 
}

function health-check { 
    Import-Module "C:\Github\n8n-tp\scripts\StrangematicPM2Management.psm1" -Force
    Invoke-HealthCheck 
}

function pm2-restart { 
    Import-Module "C:\Github\n8n-tp\scripts\StrangematicPM2Management.psm1" -Force
    Restart-N8NApplication 
}

function pm2-logs { 
    Import-Module "C:\Github\n8n-tp\scripts\StrangematicPM2Management.psm1" -Force
    Get-PM2Logs -Lines 50 
}

# Quick navigation
function goto-scripts { Set-Location "C:\Github\n8n-tp\scripts" }
function goto-logs { Set-Location "C:\ProgramData\StrangematicHub\Logs" }

# Aliases
Set-Alias -Name pms -Value pm2-status
Set-Alias -Name n8ns -Value n8n-status
Set-Alias -Name hc -Value health-check
Set-Alias -Name pmr -Value pm2-restart
Set-Alias -Name pml -Value pm2-logs
```

### Batch Scripts for Quick Access

#### `pm2-quick-check.bat`
```batch
@echo off
echo StrangematicHub PM2 Quick Check
echo ================================
powershell -NoProfile -ExecutionPolicy Bypass -Command "cd C:\Github\n8n-tp\scripts; Import-Module .\StrangematicPM2Management.psm1 -Force; $h = Invoke-HealthCheck; Write-Host 'Overall Status:' $h.Overall -ForegroundColor $(if($h.Overall -eq 'Healthy') {'Green'} else {'Red'})"
pause
```

#### `pm2-restart.bat`
```batch
@echo off
echo StrangematicHub PM2 Restart
echo ============================
powershell -NoProfile -ExecutionPolicy Bypass -Command "cd C:\Github\n8n-tp\scripts; Import-Module .\StrangematicPM2Management.psm1 -Force; Write-Host 'Restarting n8n...' -ForegroundColor Yellow; $r = Restart-N8NApplication; if($r.Success) { Write-Host 'Success!' -ForegroundColor Green } else { Write-Host 'Failed:' $r.Error -ForegroundColor Red }"
pause
```

## FAQ - Frequently Asked Questions

### Q: Làm sao để kiểm tra n8n có đang chạy không?
```powershell
# Method 1: Using module function
Import-Module "C:\Github\n8n-tp\scripts\StrangematicPM2Management.psm1" -Force
$status = Get-N8NStatus
Write-Host "n8n Status: $($status.IsRunning)"

# Method 2: Direct PM2 check
pm2 list

# Method 3: Check web interface
Start-Process "http://localhost:5678"
```

### Q: n8n không start được sau khi restart máy?
```powershell
# Check auto-start task
Get-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart" | Get-ScheduledTaskInfo

# Manual start
cd C:\Github\n8n-tp\scripts
Import-Module .\StrangematicPM2Management.psm1 -Force
Start-PM2Daemon
Start-N8NApplication

# Check logs
Get-Content "C:\ProgramData\StrangematicHub\Logs\pm2-auto-startup-*.log" -Tail 20
```

### Q: Làm sao để thay đổi port của n8n?
```powershell
# Set environment variable
[Environment]::SetEnvironmentVariable("N8N_PORT", "5679", "Machine")

# Restart n8n
Restart-N8NApplication

# Verify new port
Get-NetTCPConnection -LocalPort 5679
```

### Q: Health monitor không hoạt động?
```powershell
# Check task status
Get-ScheduledTask -TaskName "StrangematicHub-PM2-HealthMonitor"

# Manual test
cd C:\Github\n8n-tp\scripts
.\pm2-health-monitor.ps1 -RunOnce

# Check logs
Get-Content "C:\ProgramData\StrangematicHub\Logs\pm2-health-monitor-*.log" -Tail 20
```

### Q: Làm sao để backup configuration?
```powershell
# Create backup directory
$backupPath = "C:\Backup\StrangematicHub-$(Get-Date -Format 'yyyyMMdd')"
New-Item -Path $backupPath -ItemType Directory -Force

# Backup scripts
Copy-Item "C:\Github\n8n-tp\scripts\*" $backupPath -Recurse

# Export scheduled tasks
Export-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart" | Out-File "$backupPath\AutoStart.xml"
Export-ScheduledTask -TaskName "StrangematicHub-PM2-HealthMonitor" | Out-File "$backupPath\HealthMonitor.xml"

# Backup environment variables
Get-ChildItem Env: | Where-Object { $_.Name -like "*N8N*" } | Out-File "$backupPath\environment.txt"
```

## Support và Resources

### Documentation Links
- **Installation Guide**: [`PM2-AutoStart-Installation-Guide.md`](./PM2-AutoStart-Installation-Guide.md)
- **Quick Start**: [`QUICK-START-PM2-AUTOSTART.md`](../../QUICK-START-PM2-AUTOSTART.md)
- **Testing Guide**: Use [`test-pm2-autostart.ps1`](../../scripts/test-pm2-autostart.ps1)
- **Demo Script**: Use [`demo-pm2-management.ps1`](../../scripts/demo-pm2-management.ps1)

### Log Locations
- **Auto-startup logs**: `C:\ProgramData\StrangematicHub\Logs\pm2-auto-startup-*.log`
- **Health monitor logs**: `C:\ProgramData\StrangematicHub\Logs\pm2-health-monitor-*.log`
- **Installation logs**: `C:\ProgramData\StrangematicHub\Logs\pm2-autostart-install-*.log`
- **Test reports**: `C:\ProgramData\StrangematicHub\Reports\PM2-AutoStart-Test-Report-*.html`

### Emergency Contacts
- **System Administrator**: Check internal documentation
- **n8n Community**: https://community.n8n.io/
- **PM2 Documentation**: https://pm2.keymetrics.io/docs/

### Version Information
- **Solution Version**: 1.0.0
- **Last Updated**: 2025-01-01
- **Compatible with**: Windows 10/11, PowerShell 5.1+, Node.js 16+, PM2 5+, n8n 1.0+

---

**Lưu ý**: Tài liệu này được cập nhật thường xuyên. Kiểm tra version mới nhất trước khi thực hiện các tác vụ quan trọng.