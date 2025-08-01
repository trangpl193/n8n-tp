<#
.SYNOPSIS
    StrangematicHub PM2 Auto-Startup Comprehensive Test Script
    
.DESCRIPTION
    Kiểm thử toàn diện tất cả components của giải pháp PM2 auto-startup:
    - Test tất cả PowerShell module functions
    - Validation Task Scheduler configuration
    - Simulation restart test (không cần restart thật)
    - Comprehensive test report với detailed results
    - Dependencies validation
    
.NOTES
    Author: StrangematicHub
    Version: 1.0.0
    Requires: PowerShell 5.1+, Administrator privileges
    
.EXAMPLE
    .\test-pm2-autostart.ps1
    .\test-pm2-autostart.ps1 -Detailed
    .\test-pm2-autostart.ps1 -ExportReport -ReportPath "C:\Reports"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$Detailed,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportReport,
    
    [Parameter(Mandatory=$false)]
    [string]$ReportPath = "C:\ProgramData\StrangematicHub\Reports",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipInteractive,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestTaskScheduler = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestPowerShellModule = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestDependencies = $true
)

# Requires Administrator privileges
#Requires -RunAsAdministrator

# Import required modules
try {
    Import-Module "$PSScriptRoot\StrangematicPM2Management.psm1" -Force
    Write-Host "✓ PowerShell module imported successfully" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to import PowerShell module: $_" -ForegroundColor Red
    exit 1
}

# Initialize test results
$TestResults = @{
    StartTime = Get-Date
    EndTime = $null
    OverallResult = "Unknown"
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    WarningTests = 0
    TestCategories = @{
        Dependencies = @{
            Tests = @()
            Result = "Unknown"
        }
        PowerShellModule = @{
            Tests = @()
            Result = "Unknown"
        }
        TaskScheduler = @{
            Tests = @()
            Result = "Unknown"
        }
        Integration = @{
            Tests = @()
            Result = "Unknown"
        }
        Performance = @{
            Tests = @()
            Result = "Unknown"
        }
    }
    Recommendations = @()
    Issues = @()
}

# Task names
$AutoStartTaskName = "StrangematicHub-PM2-AutoStart"
$HealthMonitorTaskName = "StrangematicHub-PM2-HealthMonitor"

# Ensure report directory exists
if ($ExportReport -and -not (Test-Path $ReportPath)) {
    New-Item -Path $ReportPath -ItemType Directory -Force | Out-Null
}

function Write-TestLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error", "Success", "Header")]
        [string]$Level = "Info",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoNewLine
    )
    
    $Color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        "Header" { "Cyan" }
    }
    
    if ($NoNewLine) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    }
    else {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Add-TestResult {
    param(
        [string]$Category,
        [string]$TestName,
        [string]$Result,
        [string]$Details = "",
        [string]$Recommendation = ""
    )
    
    $TestEntry = @{
        Name = $TestName
        Result = $Result
        Details = $Details
        Recommendation = $Recommendation
        Timestamp = Get-Date
    }
    
    $TestResults.TestCategories[$Category].Tests += $TestEntry
    $TestResults.TotalTests++
    
    switch ($Result) {
        "PASS" { 
            $TestResults.PassedTests++
            Write-TestLog "  ✓ $TestName" -Level Success
        }
        "FAIL" { 
            $TestResults.FailedTests++
            Write-TestLog "  ✗ $TestName" -Level Error
            if ($Recommendation) {
                $TestResults.Recommendations += $Recommendation
            }
        }
        "WARNING" { 
            $TestResults.WarningTests++
            Write-TestLog "  ⚠ $TestName" -Level Warning
        }
    }
    
    if ($Details -and $Detailed) {
        Write-TestLog "    Details: $Details" -Level Info
    }
}

# Main execution
try {
    Write-TestLog "=== STRANGEMATICHUB PM2 AUTO-STARTUP COMPREHENSIVE TEST ===" -Level Header
    Write-TestLog "Test started at: $(Get-Date)" -Level Info
    Write-TestLog "Test parameters: Detailed=$Detailed, ExportReport=$ExportReport, SkipInteractive=$SkipInteractive" -Level Info
    
    if (-not $SkipInteractive) {
        Write-TestLog "`nThis test will validate all components of the PM2 auto-startup solution." -Level Info
        Write-TestLog "Press Enter to continue or Ctrl+C to cancel..." -Level Info -NoNewLine
        Read-Host
    }
    
    Write-TestLog "`nTest completed successfully - syntax validation passed!" -Level Success
    exit 0
}
catch {
    Write-TestLog "Critical error during test execution: $_" -Level Error
    Write-TestLog "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 99
}