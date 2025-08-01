<#
.SYNOPSIS
    StrangematicHub PM2 Management Demo và Interactive Testing Script
    
.DESCRIPTION
    Interactive demo script để showcase tất cả PM2 management functions:
    - Demo tất cả PowerShell module functions
    - Interactive testing interface với menu system
    - Real-time monitoring demo
    - Troubleshooting utilities demo
    - Educational walkthrough cho new users
    
.NOTES
    Author: StrangematicHub
    Version: 1.0.0
    Requires: PowerShell 5.1+, PM2, Node.js
    
.EXAMPLE
    .\demo-pm2-management.ps1
    .\demo-pm2-management.ps1 -AutoDemo
    .\demo-pm2-management.ps1 -QuickDemo
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$AutoDemo,
    
    [Parameter(Mandatory=$false)]
    [switch]$QuickDemo,
    
    [Parameter(Mandatory=$false)]
    [switch]$NoColor,
    
    [Parameter(Mandatory=$false)]
    [int]$DemoSpeed = 2
)

# Import required modules
try {
    Import-Module "$PSScriptRoot\StrangematicPM2Management.psm1" -Force
    Write-Host "✓ StrangematicPM2Management module loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to load PM2 Management module: $_" -ForegroundColor Red
    Write-Host "Please ensure the module file exists in the same directory" -ForegroundColor Yellow
    exit 1
}

# Global variables
$script:DemoSession = @{
    StartTime = Get-Date
    ActionsPerformed = @()
    CurrentStep = 0
    TotalSteps = 0
}

function Write-DemoLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error", "Success", "Header", "Highlight", "Prompt")]
        [string]$Level = "Info",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoNewLine
    )
    
    if ($NoColor) {
        if ($NoNewLine) {
            Write-Host $Message -NoNewline
        } else {
            Write-Host $Message
        }
        return
    }
    
    $Color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        "Header" { "Cyan" }
        "Highlight" { "Magenta" }
        "Prompt" { "DarkYellow" }
    }
    
    if ($NoNewLine) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    }
    else {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Wait-DemoStep {
    param(
        [int]$Seconds = $DemoSpeed,
        [string]$Message = "Press Enter to continue or 'q' to quit"
    )
    
    if ($AutoDemo) {
        Write-DemoLog "Auto-demo: waiting $Seconds seconds..." -Level Info
        Start-Sleep -Seconds $Seconds
        return $true
    }
    
    Write-DemoLog $Message -Level Prompt -NoNewLine
    $input = Read-Host
    
    if ($input -eq 'q' -or $input -eq 'quit') {
        Write-DemoLog "Demo terminated by user" -Level Warning
        return $false
    }
    
    return $true
}

function Show-DemoHeader {
    param([string]$Title, [string]$Description = "")
    
    $script:DemoSession.CurrentStep++
    
    Write-DemoLog "`n" + "="*80 -Level Header
    Write-DemoLog "STEP $($script:DemoSession.CurrentStep): $Title" -Level Header
    if ($Description) {
        Write-DemoLog $Description -Level Info
    }
    Write-DemoLog "="*80 -Level Header
}

function Add-DemoAction {
    param([string]$Action, [string]$Result)
    
    $script:DemoSession.ActionsPerformed += @{
        Step = $script:DemoSession.CurrentStep
        Action = $Action
        Result = $Result
        Timestamp = Get-Date
    }
}

function Show-WelcomeMessage {
    Clear-Host
    Write-DemoLog @"
╔══════════════════════════════════════════════════════════════════════════════╗
║                    STRANGEMATICHUB PM2 MANAGEMENT DEMO                      ║
║                                                                              ║
║  Chào mừng đến với interactive demo của PM2 Auto-Startup Solution!          ║
║                                                                              ║
║  Demo này sẽ showcase:                                                       ║
║  • Tất cả PowerShell management functions                                   ║
║  • Real-time monitoring capabilities                                        ║
║  • Troubleshooting utilities                                                ║
║  • Best practices và common workflows                                       ║
║                                                                              ║
║  Bạn có thể:                                                                ║
║  • Follow guided demo (recommended cho new users)                           ║
║  • Use interactive menu để explore specific features                        ║
║  • Run automated demo để see all features quickly                           ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
"@ -Level Header

    Write-DemoLog "`nDemo Options:" -Level Highlight
    Write-DemoLog "  [G] Guided Demo - Step-by-step walkthrough" -Level Info
    Write-DemoLog "  [I] Interactive Menu - Explore specific features" -Level Info
    Write-DemoLog "  [A] Auto Demo - Automated showcase of all features" -Level Info
    Write-DemoLog "  [Q] Quit" -Level Info
}

function Show-SystemStatus {
    Show-DemoHeader "System Status Overview" "Kiểm tra current state của PM2 và n8n services"
    
    Write-DemoLog "Đang kiểm tra system status..." -Level Info
    
    # PM2 Status
    Write-DemoLog "`n🔍 PM2 Daemon Status:" -Level Highlight
    try {
        $pm2Status = Get-PM2Status
        if ($pm2Status.IsRunning) {
            Write-DemoLog "  ✓ PM2 Daemon: RUNNING" -Level Success
            Write-DemoLog "  📊 Process Count: $($pm2Status.ProcessCount)" -Level Info
            
            if ($pm2Status.Processes.Count -gt 0) {
                Write-DemoLog "  📋 Managed Processes:" -Level Info
                foreach ($process in $pm2Status.Processes) {
                    $statusColor = if ($process.Status -eq "online") { "Success" } else { "Warning" }
                    Write-DemoLog "    • ID: $($process.Id) | Name: $($process.Name) | Status: $($process.Status) | Restarts: $($process.Restart)" -Level $statusColor
                }
            }
        } else {
            Write-DemoLog "  ✗ PM2 Daemon: NOT RUNNING" -Level Error
            if ($pm2Status.Error) {
                Write-DemoLog "  ❌ Error: $($pm2Status.Error)" -Level Error
            }
        }
        Add-DemoAction "Check PM2 Status" "PM2 Running: $($pm2Status.IsRunning), Processes: $($pm2Status.ProcessCount)"
    }
    catch {
        Write-DemoLog "  ❌ Failed to get PM2 status: $_" -Level Error
        Add-DemoAction "Check PM2 Status" "Failed: $_"
    }
    
    # n8n Status
    Write-DemoLog "`n🔍 n8n Application Status:" -Level Highlight
    try {
        $n8nStatus = Get-N8NStatus
        if ($n8nStatus.IsRunning) {
            Write-DemoLog "  ✓ n8n Application: RUNNING" -Level Success
            if ($n8nStatus.ProcessInfo) {
                Write-DemoLog "  📊 Process Info:" -Level Info
                Write-DemoLog "    • Process ID: $($n8nStatus.ProcessInfo.Id)" -Level Info
                Write-DemoLog "    • Status: $($n8nStatus.ProcessInfo.Status)" -Level Info
                Write-DemoLog "    • Restart Count: $($n8nStatus.ProcessInfo.Restart)" -Level Info
            }
        } else {
            Write-DemoLog "  ✗ n8n Application: NOT RUNNING" -Level Error
            if ($n8nStatus.Error) {
                Write-DemoLog "  ❌ Error: $($n8nStatus.Error)" -Level Error
            }
        }
        Add-DemoAction "Check n8n Status" "n8n Running: $($n8nStatus.IsRunning)"
    }
    catch {
        Write-DemoLog "  ❌ Failed to get n8n status: $_" -Level Error
        Add-DemoAction "Check n8n Status" "Failed: $_"
    }
    
    # Health Check
    Write-DemoLog "`n🏥 Overall Health Check:" -Level Highlight
    try {
        $healthCheck = Invoke-HealthCheck
        $healthColor = switch ($healthCheck.Overall) {
            "Healthy" { "Success" }
            "Warning" { "Warning" }
            "Critical" { "Error" }
            default { "Info" }
        }
        Write-DemoLog "  🎯 Overall Status: $($healthCheck.Overall)" -Level $healthColor
        Write-DemoLog "  🔧 PM2 Status: $($healthCheck.PM2Status)" -Level Info
        Write-DemoLog "  🚀 n8n Status: $($healthCheck.N8NStatus)" -Level Info
        
        if ($healthCheck.Issues.Count -gt 0) {
            Write-DemoLog "  ⚠️ Issues Found:" -Level Warning
            foreach ($issue in $healthCheck.Issues) {
                Write-DemoLog "    • $issue" -Level Warning
            }
        }
        
        if ($healthCheck.Recommendations.Count -gt 0) {
            Write-DemoLog "  💡 Recommendations:" -Level Highlight
            foreach ($rec in $healthCheck.Recommendations) {
                Write-DemoLog "    • $rec" -Level Info
            }
        }
        
        Add-DemoAction "Health Check" "Overall: $($healthCheck.Overall), Issues: $($healthCheck.Issues.Count)"
    }
    catch {
        Write-DemoLog "  ❌ Failed to perform health check: $_" -Level Error
        Add-DemoAction "Health Check" "Failed: $_"
    }
    
    if (-not (Wait-DemoStep)) { return $false }
    return $true
}

function Demo-ServiceManagement {
    Show-DemoHeader "Service Management Demo" "Demonstrate starting, stopping, và restarting services"
    
    Write-DemoLog "Trong section này, chúng ta sẽ demo các service management operations:" -Level Info
    Write-DemoLog "• Start PM2 Daemon" -Level Info
    Write-DemoLog "• Start n8n Application" -Level Info
    Write-DemoLog "• Restart n8n Application" -Level Info
    Write-DemoLog "• Stop n8n Application" -Level Info
    
    if (-not (Wait-DemoStep)) { return $false }
    
    # Demo Start PM2 Daemon
    Write-DemoLog "`n🚀 Starting PM2 Daemon..." -Level Highlight
    try {
        $result = Start-PM2Daemon
        if ($result.Success) {
            Write-DemoLog "  ✓ PM2 Daemon started successfully!" -Level Success
            if ($result.Message) {
                Write-DemoLog "  📝 Message: $($result.Message)" -Level Info
            }
        } else {
            Write-DemoLog "  ✗ Failed to start PM2 Daemon" -Level Error
            Write-DemoLog "  ❌ Error: $($result.Error)" -Level Error
        }
        Add-DemoAction "Start PM2 Daemon" "Success: $($result.Success)"
    }
    catch {
        Write-DemoLog "  ❌ Exception during PM2 start: $_" -Level Error
        Add-DemoAction "Start PM2 Daemon" "Exception: $_"
    }
    
    if (-not (Wait-DemoStep)) { return $false }
    
    # Demo Start n8n Application
    Write-DemoLog "`n🚀 Starting n8n Application..." -Level Highlight
    try {
        $result = Start-N8NApplication
        if ($result.Success) {
            Write-DemoLog "  ✓ n8n Application started successfully!" -Level Success
            if ($result.Message) {
                Write-DemoLog "  📝 Message: $($result.Message)" -Level Info
            }
            
            # Wait and verify
            Write-DemoLog "  ⏳ Waiting 10 seconds để verify startup..." -Level Info
            Start-Sleep -Seconds 10
            
            $verifyStatus = Get-N8NStatus
            if ($verifyStatus.IsRunning) {
                Write-DemoLog "  ✅ n8n Application verified running!" -Level Success
            } else {
                Write-DemoLog "  ⚠️ n8n Application may have issues after startup" -Level Warning
            }
        } else {
            Write-DemoLog "  ✗ Failed to start n8n Application" -Level Error
            Write-DemoLog "  ❌ Error: $($result.Error)" -Level Error
        }
        Add-DemoAction "Start n8n Application" "Success: $($result.Success)"
    }
    catch {
        Write-DemoLog "  ❌ Exception during n8n start: $_" -Level Error
        Add-DemoAction "Start n8n Application" "Exception: $_"
    }
    
    if (-not (Wait-DemoStep)) { return $false }
    
    # Demo Restart n8n Application
    Write-DemoLog "`n🔄 Restarting n8n Application..." -Level Highlight
    try {
        $result = Restart-N8NApplication
        if ($result.Success) {
            Write-DemoLog "  ✓ n8n Application restarted successfully!" -Level Success
            if ($result.Message) {
                Write-DemoLog "  📝 Message: $($result.Message)" -Level Info
            }
            
            # Wait and verify
            Write-DemoLog "  ⏳ Waiting 15 seconds để verify restart..." -Level Info
            Start-Sleep -Seconds 15
            
            $verifyStatus = Get-N8NStatus
            if ($verifyStatus.IsRunning) {
                Write-DemoLog "  ✅ n8n Application verified running after restart!" -Level Success
            } else {
                Write-DemoLog "  ⚠️ n8n Application may have issues after restart" -Level Warning
            }
        } else {
            Write-DemoLog "  ✗ Failed to restart n8n Application" -Level Error
            Write-DemoLog "  ❌ Error: $($result.Error)" -Level Error
        }
        Add-DemoAction "Restart n8n Application" "Success: $($result.Success)"
    }
    catch {
        Write-DemoLog "  ❌ Exception during n8n restart: $_" -Level Error
        Add-DemoAction "Restart n8n Application" "Exception: $_"
    }
    
    if (-not (Wait-DemoStep)) { return $false }
    
    # Demo Stop n8n Application (optional)
    Write-DemoLog "`n⚠️ Do you want to demo stopping n8n? (This will stop the application)" -Level Warning
    Write-DemoLog "Type 'yes' to proceed, or press Enter to skip: " -Level Prompt -NoNewLine
    $stopConfirm = Read-Host
    
    if ($stopConfirm -eq 'yes') {
        Write-DemoLog "`n🛑 Stopping n8n Application..." -Level Highlight
        try {
            $result = Stop-N8NApplication
            if ($result.Success) {
                Write-DemoLog "  ✓ n8n Application stopped successfully!" -Level Success
                if ($result.Message) {
                    Write-DemoLog "  📝 Message: $($result.Message)" -Level Info
                }
            } else {
                Write-DemoLog "  ✗ Failed to stop n8n Application" -Level Error
                Write-DemoLog "  ❌ Error: $($result.Error)" -Level Error
            }
            Add-DemoAction "Stop n8n Application" "Success: $($result.Success)"
        }
        catch {
            Write-DemoLog "  ❌ Exception during n8n stop: $_" -Level Error
            Add-DemoAction "Stop n8n Application" "Exception: $_"
        }
        
        # Restart it again for demo continuity
        Write-DemoLog "`n🔄 Restarting n8n for demo continuity..." -Level Info
        Start-N8NApplication | Out-Null
        Start-Sleep -Seconds 10
    } else {
        Write-DemoLog "  ⏭️ Skipping stop demo to keep n8n running" -Level Info
        Add-DemoAction "Stop n8n Application" "Skipped by user"
    }
    
    if (-not (Wait-DemoStep)) { return $false }
    return $true
}

function Demo-LogsAndMonitoring {
    Show-DemoHeader "Logs và Monitoring Demo" "Demonstrate log viewing và process monitoring capabilities"
    
    Write-DemoLog "Trong section này, chúng ta sẽ explore logging và monitoring features:" -Level Info
    Write-DemoLog "• View PM2 logs" -Level Info
    Write-DemoLog "• Get detailed process information" -Level Info
    Write-DemoLog "• Monitor system performance" -Level Info
    
    if (-not (Wait-DemoStep)) { return $false }
    
    # Demo PM2 Logs
    Write-DemoLog "`n📋 Getting PM2 Logs (last 20 lines)..." -Level Highlight
    try {
        $logsResult = Get-PM2Logs -Lines 20
        if ($logsResult.Success) {
            Write-DemoLog "  ✓ Successfully retrieved PM2 logs!" -Level Success
            Write-DemoLog "  📄 Recent Log Entries:" -Level Info
            
            if ($logsResult.Logs) {
                $logLines = $logsResult.Logs -split "`n" | Select-Object -Last 10
                foreach ($line in $logLines) {
                    if ($line.Trim()) {
                        Write-DemoLog "    $line" -Level Info
                    }
                }
                
                if ($logsResult.Logs -split "`n" | Measure-Object | Select-Object -ExpandProperty Count -gt 10) {
                    Write-DemoLog "    ... (showing last 10 lines, full logs available)" -Level Info
                }
            } else {
                Write-DemoLog "    (No recent log entries found)" -Level Warning
            }
        } else {
            Write-DemoLog "  ✗ Failed to get PM2 logs" -Level Error
            Write-DemoLog "  ❌ Error: $($logsResult.Error)" -Level Error
        }
        Add-DemoAction "Get PM2 Logs" "Success: $($logsResult.Success)"
    }
    catch {
        Write-DemoLog "  ❌ Exception getting PM2 logs: $_" -Level Error
        Add-DemoAction "Get PM2 Logs" "Exception: $_"
    }
    
    if (-not (Wait-DemoStep)) { return $false }
    
    # Demo Process Details
    Write-DemoLog "`n🔍 Getting Detailed Process Information..." -Level Highlight
    try {
        $detailsResult = Get-PM2ProcessDetails
        if ($detailsResult.Success) {
            Write-DemoLog "  ✓ Successfully retrieved process details!" -Level Success
            Write-DemoLog "  📊 Process Details:" -Level Info
            
            if ($detailsResult.Details) {
                $detailLines = $detailsResult.Details -split "`n" | Select-Object -First 15
                foreach ($line in $detailLines) {
                    if ($line.Trim()) {
                        Write-DemoLog "    $line" -Level Info
                    }
                }
                
                if ($detailsResult.Details -split "`n" | Measure-Object | Select-Object -ExpandProperty Count -gt 15) {
                    Write-DemoLog "    ... (showing first 15 lines, full details available)" -Level Info
                }
            } else {
                Write-DemoLog "    (No process details available)" -Level Warning
            }
        } else {
            Write-DemoLog "  ✗ Failed to get process details" -Level Error
            Write-DemoLog "  ❌ Error: $($detailsResult.Error)" -Level Error
        }
        Add-DemoAction "Get Process Details" "Success: $($detailsResult.Success)"
    }
    catch {
        Write-DemoLog "  ❌ Exception getting process details: $_" -Level Error
        Add-DemoAction "Get Process Details" "Exception: $_"
    }
    
    if (-not (Wait-DemoStep)) { return $false }
    
    # Demo System Performance Monitoring
    Write-DemoLog "`n📈 System Performance Monitoring..." -Level Highlight
    try {
        Write-DemoLog "  🔄 Collecting system metrics..." -Level Info
        
        # Get system metrics
        $cpu = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
        $memory = Get-WmiObject -Class Win32_OperatingSystem | ForEach-Object {
            [math]::Round((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / $_.TotalVisibleMemorySize) * 100, 2)
        }
        $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | Where-Object { $_.DeviceID -eq "C:" } | ForEach-Object {
            [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)
        }
        
        Write-DemoLog "  📊 Current System Performance:" -Level Success
        Write-DemoLog "    🖥️  CPU Usage: $cpu%" -Level $(if($cpu -gt 80) {"Warning"} elseif($cpu -gt 60) {"Info"} else {"Success"})
        Write-DemoLog "    💾 Memory Usage: $memory%" -Level $(if($memory -gt 90) {"Warning"} elseif($memory -gt 75) {"Info"} else {"Success"})
        Write-DemoLog "    💿 Disk Usage: $disk%" -Level $(if($disk -gt 90) {"Warning"} elseif($disk -gt 80) {"Info"} else {"Success"})
        
        # Performance recommendations
        if ($cpu -gt 80) {
            Write-DemoLog "    ⚠️ High CPU usage detected - consider checking running processes" -Level Warning
        }
        if ($memory -gt 90) {
            Write-DemoLog "    ⚠️ High memory usage detected - consider restarting applications" -Level Warning
        }
        if ($disk -gt 90) {
            Write-DemoLog "    ⚠️ Low disk space - consider cleaning up files" -Level Warning
        }
        
        Add-DemoAction "System Performance Check" "CPU: $cpu%, Memory: $memory%, Disk: $disk%"
    }
    catch {
        Write-DemoLog "  ❌ Exception during performance monitoring: $_" -Level Error
        Add-DemoAction "System Performance Check" "Exception: $_"
    }
    
    if (-not (Wait-DemoStep)) { return $false }
    return $true
}

function Demo-TroubleshootingUtilities {
    Show-DemoHeader "Troubleshooting Utilities Demo" "Demonstrate diagnostic và recovery tools"
    
    Write-DemoLog "Trong section này, chúng ta sẽ demo troubleshooting utilities:" -Level Info
    Write-DemoLog "• Advanced health diagnostics" -Level Info
    Write-DemoLog "• PM2 reset functionality" -Level Info
    Write-DemoLog "• System dependency checks" -Level Info
    Write-DemoLog "• Recovery procedures" -Level Info
    
    if (-not (Wait-DemoStep)) { return $false }
    
    # Demo Advanced Health Diagnostics
    Write-DemoLog "`n🏥 Advanced Health Diagnostics..." -Level Highlight
    try {
        Write-DemoLog "  🔍 Running comprehensive health check..." -Level Info
        $healthCheck = Invoke-HealthCheck
        
        Write-DemoLog "  📋 Detailed Health Report:" -Level Success
        Write-DemoLog "    🎯 Overall Status: $($healthCheck.Overall)" -Level $(
            switch ($healthCheck.Overall) {
                "Healthy" { "Success" }
                "Warning" { "Warning" }
                "Critical" { "Error" }
                default { "Info" }
            }
        )
        Write-DemoLog "    🔧 PM2 Status: $($healthCheck.PM2Status)" -Level Info
        Write-DemoLog "    🚀 n8n Status: $($healthCheck.N8NStatus)" -Level Info
        Write-DemoLog "    📅 Check Time: $($healthCheck.Timestamp)" -Level Info
        
        if ($healthCheck.Issues.Count -gt 0) {
            Write-DemoLog "    ⚠️ Issues Detected:" -Level Warning
            foreach ($issue in $healthCheck.Issues) {
                Write-DemoLog "      • $issue" -Level Warning
            }
        } else {
            Write-DemoLog "    ✅ No issues detected!" -Level Success
        }
        
        if ($healthCheck.Recommendations.Count -gt 0) {
            Write-DemoLog "    💡 Recommendations:" -Level Highlight
            foreach ($rec in $healthCheck.Recommendations) {
                Write-DemoLog "      • $rec" -Level Info
            }
        }
        
        Add-DemoAction "Advanced Health Check" "Status: $($healthCheck.Overall), Issues: $($healthCheck.Issues.Count)"
    }
    catch {
        Write-DemoLog "  ❌ Exception during health diagnostics: $_" -Level Error
        Add-DemoAction "Advanced Health Check" "Exception: $_"
    }
    
    if (-not (Wait-DemoStep)) { return $false }
    
    # Demo System Dependencies Check
    Write-DemoLog "`n🔧 System Dependencies Check..." -Level Highlight
    try {
        Write-DemoLog "  🔍 Checking system dependencies..." -Level Info
        
        # Check Node.js
        try {
            $nodeVersion = & node --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-DemoLog "    ✅ Node.js: Available ($nodeVersion)" -Level Success
            } else {
                Write-DemoLog "    ❌ Node.js: Not available" -Level Error
            }
        } catch {
            Write-DemoLog "    ❌ Node.js: Check failed ($_)" -Level Error
        }
        
        # Check PM2
        try {
            $pm2Version = & pm2 --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-DemoLog "    ✅ PM2: Available ($pm2Version)" -Level Success
            } else {
                Write-DemoLog "    ❌ PM2: Not available" -Level Error
            }
        } catch {
            Write-DemoLog "    ❌ PM2: Check failed ($_)" -Level Error
        }
        
        # Check n8n
        try {
            $n8nVersion = & n8n --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-DemoLog "    ✅ n8n: Available ($n8nVersion)" -Level Success
            } else {
                Write-DemoLog "    ❌ n8n: Not available" -Level Error
            }
        } catch {
            Write-DemoLog "    ❌ n8n: Check failed ($_)" -Level Error
        }
        
        # Check PowerShell version
        $psVersion = $PSVersionTable.PSVersion
        if ($psVersion.Major -ge 5) {
            Write-DemoLog "    ✅ PowerShell: Compatible ($psVersion)" -Level Success
        } else {
            Write-DemoLog "    ⚠️ PowerShell: Version may be too old ($psVersion)" -Level Warning
        }
        
        Add-DemoAction "Dependencies Check" "Completed system dependencies verification"
    }
    catch {
        Write-DemoLog "  ❌ Exception during dependencies check: $_" -Level Error
        Add-DemoAction "Dependencies Check" "Exception: $_"
    }
    
    if (-not (Wait-DemoStep)) { return $false }
    
    # Demo PM2 Reset (with caution)
    Write-DemoLog "`n⚠️ PM2 Reset Functionality Demo" -Level Warning
    Write-DemoLog "  🚨 WARNING: PM2 reset will kill all PM2 processes!" -Level Error
    Write-DemoLog "  This is an emergency recovery tool that should be used carefully." -Level Warning
    Write-DemoLog "  Type 'RESET' to proceed with demo, or press Enter to skip: " -Level Prompt -NoNewLine
    $resetConfirm = Read-Host
    
    if ($resetConfirm -eq 'RESET') {
        Write-DemoLog "`n🔄 Performing PM2 Reset..." -Level Highlight
        try {
            $resetResult = Reset-PM2
            if ($resetResult.Success) {
                Write-DemoLog "  ✅ PM2 reset completed successfully!" -Level Success
                Write-DemoLog "  📝 Message: $($resetResult.Message)" -Level Info
                
                # Wait and verify
                Write-DemoLog "  ⏳ Waiting 10 seconds for PM2 to stabilize..." -Level Info
                Start-Sleep -Seconds 10
                
                # Check PM2 status after reset
                $pm2Status = Get-PM2Status
                if ($pm2Status.IsRunning) {
                    Write-DemoLog "  ✅ PM2 daemon is running after reset!" -Level Success
                } else {
                    Write-DemoLog "  ⚠️ PM2 daemon may need manual restart" -Level Warning
                }
                
                # Restart n8n for demo continuity
                Write-DemoLog "  🔄 Restarting n8n for demo continuity..." -Level Info
                Start-N8NApplication | Out-
Null
                Start-Sleep -Seconds 10
            } else {
                Write-DemoLog "  ❌ PM2 reset failed!" -Level Error
                Write-DemoLog "  📝 Error: $($resetResult.Error)" -Level Error
            }
            Add-DemoAction "PM2 Reset" "Success: $($resetResult.Success)"
        }
        catch {
            Write-DemoLog "  ❌ Exception during PM2 reset: $_" -Level Error
            Add-DemoAction "PM2 Reset" "Exception: $_"
        }
    } else {
        Write-DemoLog "  ⏭️ Skipping PM2 reset demo for safety" -Level Info
        Add-DemoAction "PM2 Reset" "Skipped by user"
    }
    
    if (-not (Wait-DemoStep)) { return $false }
    return $true
}

function Demo-RealTimeMonitoring {
    Show-DemoHeader "Real-Time Monitoring Demo" "Demonstrate continuous monitoring capabilities"
    
    Write-DemoLog "Trong section này, chúng ta sẽ demo real-time monitoring:" -Level Info
    Write-DemoLog "• Continuous health monitoring" -Level Info
    Write-DemoLog "• Performance tracking" -Level Info
    Write-DemoLog "• Alert simulation" -Level Info
    
    if (-not (Wait-DemoStep)) { return $false }
    
    Write-DemoLog "`n📊 Starting Real-Time Monitoring (30 seconds)..." -Level Highlight
    Write-DemoLog "  🔄 Monitoring system every 5 seconds..." -Level Info
    
    $monitoringStart = Get-Date
    $monitoringEnd = $monitoringStart.AddSeconds(30)
    $iteration = 1
    
    while ((Get-Date) -lt $monitoringEnd) {
        Write-DemoLog "`n  📈 Monitoring Iteration $iteration ($(Get-Date -Format 'HH:mm:ss')):" -Level Highlight
        
        try {
            # Quick health check
            $health = Invoke-HealthCheck
            Write-DemoLog "    🎯 Overall Health: $($health.Overall)" -Level $(
                switch ($health.Overall) {
                    "Healthy" { "Success" }
                    "Warning" { "Warning" }
                    "Critical" { "Error" }
                    default { "Info" }
                }
            )
            
            # System metrics
            $cpu = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
            $memory = Get-WmiObject -Class Win32_OperatingSystem | ForEach-Object {
                [math]::Round((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / $_.TotalVisibleMemorySize) * 100, 2)
            }
            
            Write-DemoLog "    🖥️  CPU: $cpu% | 💾 Memory: $memory%" -Level Info
            
            # Service status
            $pm2Status = Get-PM2Status
            $n8nStatus = Get-N8NStatus
            Write-DemoLog "    🔧 PM2: $($pm2Status.IsRunning) | 🚀 n8n: $($n8nStatus.IsRunning)" -Level Info
            
            # Alert simulation
            if ($cpu -gt 80 -or $memory -gt 90) {
                Write-DemoLog "    🚨 ALERT: High resource usage detected!" -Level Error
            }
            
            if (-not $pm2Status.IsRunning -or -not $n8nStatus.IsRunning) {
                Write-DemoLog "    🚨 ALERT: Service down detected!" -Level Error
            }
            
        }
        catch {
            Write-DemoLog "    ❌ Monitoring error: $_" -Level Error
        }
        
        $iteration++
        
        # Check if user wants to stop early
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq 'Q') {
                Write-DemoLog "`n  ⏹️ Monitoring stopped by user" -Level Warning
                break
            }
        }
        
        Start-Sleep -Seconds 5
    }
    
    Write-DemoLog "`n  ✅ Real-time monitoring demo completed!" -Level Success
    Add-DemoAction "Real-Time Monitoring" "Completed $iteration iterations"
    
    if (-not (Wait-DemoStep)) { return $false }
    return $true
}

function Show-InteractiveMenu {
    while ($true) {
        Clear-Host
        Write-DemoLog @"
╔══════════════════════════════════════════════════════════════════════════════╗
║                         INTERACTIVE PM2 MANAGEMENT MENU                     ║
╚══════════════════════════════════════════════════════════════════════════════╝
"@ -Level Header

        Write-DemoLog "`n🎯 Available Options:" -Level Highlight
        Write-DemoLog "  [1] System Status Overview" -Level Info
        Write-DemoLog "  [2] Service Management Demo" -Level Info
        Write-DemoLog "  [3] Logs và Monitoring Demo" -Level Info
        Write-DemoLog "  [4] Troubleshooting Utilities Demo" -Level Info
        Write-DemoLog "  [5] Real-Time Monitoring Demo" -Level Info
        Write-DemoLog "  [6] Run Comprehensive Test" -Level Info
        Write-DemoLog "  [7] View Demo Session Summary" -Level Info
        Write-DemoLog "  [Q] Quit" -Level Info
        
        Write-DemoLog "`nSelect an option (1-7, Q): " -Level Prompt -NoNewLine
        $choice = Read-Host
        
        switch ($choice.ToUpper()) {
            '1' { 
                if (-not (Show-SystemStatus)) { return }
            }
            '2' { 
                if (-not (Demo-ServiceManagement)) { return }
            }
            '3' { 
                if (-not (Demo-LogsAndMonitoring)) { return }
            }
            '4' { 
                if (-not (Demo-TroubleshootingUtilities)) { return }
            }
            '5' { 
                if (-not (Demo-RealTimeMonitoring)) { return }
            }
            '6' { 
                Write-DemoLog "`n🧪 Running Comprehensive Test..." -Level Highlight
                try {
                    Set-Location $PSScriptRoot
                    $testResult = & .\test-pm2-autostart.ps1 -SkipInteractive
                    Write-DemoLog "Test completed with exit code: $LASTEXITCODE" -Level $(if($LASTEXITCODE -eq 0) {"Success"} else {"Warning"})
                    Add-DemoAction "Comprehensive Test" "Exit Code: $LASTEXITCODE"
                }
                catch {
                    Write-DemoLog "Test execution failed: $_" -Level Error
                    Add-DemoAction "Comprehensive Test" "Failed: $_"
                }
                Wait-DemoStep -Message "Press Enter to continue..."
            }
            '7' { 
                Show-DemoSummary
                Wait-DemoStep -Message "Press Enter to continue..."
            }
            'Q' { 
                Write-DemoLog "`n👋 Exiting interactive menu..." -Level Info
                return 
            }
            default { 
                Write-DemoLog "`n❌ Invalid option. Please select 1-7 or Q." -Level Error
                Start-Sleep -Seconds 2
            }
        }
    }
}

function Run-GuidedDemo {
    Write-DemoLog "`n🎯 Starting Guided Demo..." -Level Highlight
    Write-DemoLog "This demo will walk you through all PM2 management features step by step." -Level Info
    
    if (-not (Wait-DemoStep -Message "Press Enter to start the guided demo...")) { return }
    
    $script:TotalSteps = 5
    
    # Step 1: System Status
    if (-not (Show-SystemStatus)) { return }
    
    # Step 2: Service Management
    if (-not (Demo-ServiceManagement)) { return }
    
    # Step 3: Logs and Monitoring
    if (-not (Demo-LogsAndMonitoring)) { return }
    
    # Step 4: Troubleshooting
    if (-not (Demo-TroubleshootingUtilities)) { return }
    
    # Step 5: Real-Time Monitoring
    if (-not (Demo-RealTimeMonitoring)) { return }
    
    # Demo completed
    Show-DemoHeader "Guided Demo Completed!" "Congratulations! You've completed the full PM2 management demo."
    
    Write-DemoLog "🎉 Guided demo completed successfully!" -Level Success
    Write-DemoLog "You've learned about:" -Level Info
    Write-DemoLog "  ✅ System status checking" -Level Success
    Write-DemoLog "  ✅ Service management operations" -Level Success
    Write-DemoLog "  ✅ Log viewing và monitoring" -Level Success
    Write-DemoLog "  ✅ Troubleshooting utilities" -Level Success
    Write-DemoLog "  ✅ Real-time monitoring capabilities" -Level Success
    
    Show-DemoSummary
}

function Run-AutoDemo {
    Write-DemoLog "`n🤖 Starting Automated Demo..." -Level Highlight
    Write-DemoLog "This will automatically showcase all features with minimal interaction." -Level Info
    Write-DemoLog "Demo speed: $DemoSpeed seconds between steps" -Level Info
    
    $script:TotalSteps = 5
    
    # Run all demo sections automatically
    Show-SystemStatus | Out-Null
    Demo-ServiceManagement | Out-Null
    Demo-LogsAndMonitoring | Out-Null
    Demo-TroubleshootingUtilities | Out-Null
    Demo-RealTimeMonitoring | Out-Null
    
    Write-DemoLog "`n🎉 Automated demo completed!" -Level Success
    Show-DemoSummary
}

function Show-DemoSummary {
    Write-DemoLog "`n" + "="*80 -Level Header
    Write-DemoLog "DEMO SESSION SUMMARY" -Level Header
    Write-DemoLog "="*80 -Level Header
    
    $duration = (Get-Date) - $script:DemoSession.StartTime
    Write-DemoLog "📅 Session Duration: $($duration.ToString('hh\:mm\:ss'))" -Level Info
    Write-DemoLog "🎯 Total Steps Completed: $($script:DemoSession.CurrentStep)" -Level Info
    Write-DemoLog "🔧 Actions Performed: $($script:DemoSession.ActionsPerformed.Count)" -Level Info
    
    if ($script:DemoSession.ActionsPerformed.Count -gt 0) {
        Write-DemoLog "`n📋 Actions Summary:" -Level Highlight
        foreach ($action in $script:DemoSession.ActionsPerformed) {
            $timestamp = $action.Timestamp.ToString("HH:mm:ss")
            Write-DemoLog "  [$timestamp] Step $($action.Step): $($action.Action) - $($action.Result)" -Level Info
        }
    }
    
    Write-DemoLog "`n💡 Next Steps:" -Level Highlight
    Write-DemoLog "  • Review the User Guide for daily operations" -Level Info
    Write-DemoLog "  • Run the comprehensive test script for validation" -Level Info
    Write-DemoLog "  • Check the Installation Guide for setup details" -Level Info
    Write-DemoLog "  • Use the Quick Start Guide for common tasks" -Level Info
    
    Write-DemoLog "`n📚 Documentation Links:" -Level Highlight
    Write-DemoLog "  • Installation Guide: docs/deployment/PM2-AutoStart-Installation-Guide.md" -Level Info
    Write-DemoLog "  • User Guide: docs/deployment/PM2-AutoStart-User-Guide.md" -Level Info
    Write-DemoLog "  • Quick Start: QUICK-START-PM2-AUTOSTART.md" -Level Info
    Write-DemoLog "  • Test Script: scripts/test-pm2-autostart.ps1" -Level Info
}

# Main execution
try {
    if ($QuickDemo) {
        $AutoDemo = $true
        $DemoSpeed = 1
    }
    
    if ($AutoDemo) {
        Run-AutoDemo
    } else {
        Show-WelcomeMessage
        
        Write-DemoLog "`nSelect demo mode: " -Level Prompt -NoNewLine
        $mode = Read-Host
        
        switch ($mode.ToUpper()) {
            'G' { Run-GuidedDemo }
            'I' { Show-InteractiveMenu }
            'A' { Run-AutoDemo }
            'Q' { 
                Write-DemoLog "Demo cancelled by user" -Level Info
                exit 0
            }
            default { 
                Write-DemoLog "Invalid selection. Starting Interactive Menu..." -Level Warning
                Start-Sleep -Seconds 2
                Show-InteractiveMenu
            }
        }
    }
    
    Write-DemoLog "`n👋 Thank you for using StrangematicHub PM2 Management Demo!" -Level Success
    Write-DemoLog "For more information, check the documentation files." -Level Info
}
catch {
    Write-DemoLog "`n❌ Critical error during demo execution: $_" -Level Error
    Write-DemoLog "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}
finally {
    Write-DemoLog "`nDemo session ended at $(Get-Date)" -Level Info
}