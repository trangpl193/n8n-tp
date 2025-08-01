# ============================================
# N8N Manual Startup Script - Simplified
# ============================================

param(
    [switch]$Silent = $false
)

# ============================================
# LOGGING
# ============================================
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    if (-not $Silent) {
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
        
        Write-Host "$icon [$timestamp] $Message" -ForegroundColor $color
    }
}

# ============================================
# ADMIN PRIVILEGES CHECK
# ============================================
function Test-AdminPrivileges {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if (-not $isAdmin) {
        Write-Log "Khoi dong lai voi quyen Administrator..." "WARNING"
        
        $scriptPath = $MyInvocation.MyCommand.Path
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptPath`"")
        if ($Silent) { $arguments += "-Silent" }
        
        try {
            Start-Process PowerShell -ArgumentList $arguments -Verb RunAs
            exit 0
        } catch {
            Write-Log "Khong the khoi dong voi quyen admin: $($_.Exception.Message)" "ERROR"
            Read-Host "Nhan Enter de thoat"
            exit 1
        }
    }
    
    Write-Log "Dang chay voi quyen Administrator" "SUCCESS"
    
    # Prevent background task suspension
    try {
        Write-Log "Preventing background task suspension..." "INFO"
        powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_BACKGROUND_APPS_POLICY BackgroundAppPolicy 0 2>$null | Out-Null
        powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_BACKGROUND_APPS_POLICY BackgroundAppPolicy 0 2>$null | Out-Null  
        powercfg /SETACTIVE SCHEME_CURRENT 2>$null | Out-Null
        Write-Log "Background app suspension disabled" "SUCCESS"
    } catch {
        Write-Log "Could not modify power policy: $($_.Exception.Message)" "WARNING"
    }
    
    return $true
}

# ============================================
# PREREQUISITES CHECK
# ============================================
function Test-Prerequisites {
    Write-Log "Kiem tra cac dieu kien tien quyet..." "INFO"
    $allGood = $true
    
    # Check PostgreSQL Service
    try {
        $pgService = Get-Service -Name "postgresql-x64-17" -ErrorAction Stop
        if ($pgService.Status -eq "Running") {
            Write-Log "PostgreSQL service dang chay" "SUCCESS"
        } else {
            Write-Log "PostgreSQL service khong chay - dang khoi dong..." "WARNING"
            Start-Service -Name "postgresql-x64-17"
            Start-Sleep -Seconds 5
            Write-Log "PostgreSQL service da duoc khoi dong" "SUCCESS"
        }
    } catch {
        Write-Log "Loi PostgreSQL: $($_.Exception.Message)" "ERROR"
        $allGood = $false
    }
    
    # Check database connection
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect("localhost", 5432)
        $tcpClient.Close()
        Write-Log "Ket noi database thanh cong" "SUCCESS"
    } catch {
        Write-Log "Khong the ket noi database" "ERROR"
        $allGood = $false
    }
    
    # Check Cloudflared
    if (Test-Path "C:\cloudflared\cloudflared.exe") {
        Write-Log "Cloudflared executable co san" "SUCCESS"
    } else {
        Write-Log "Cloudflared khong tim thay" "ERROR"
        $allGood = $false
    }
    
    if (Test-Path "C:\cloudflared\config.yml") {
        Write-Log "Cloudflared config co san" "SUCCESS"
    } else {
        Write-Log "Cloudflared config khong tim thay" "ERROR"
        $allGood = $false
    }
    
    # Check n8n files
    if (Test-Path "ecosystem-stable.config.js") {
        Write-Log "n8n ecosystem config co san" "SUCCESS"
    } else {
        Write-Log "n8n ecosystem config khong tim thay" "ERROR"
        $allGood = $false
    }
    
    if (Test-Path ".env.production") {
        Write-Log "n8n environment file co san" "SUCCESS"
    } else {
        Write-Log "n8n environment file khong tim thay" "ERROR"
        $allGood = $false
    }
    
    return $allGood
}

# ============================================
# CLEANUP EXISTING PROCESSES
# ============================================
function Stop-ExistingProcesses {
    Write-Log "Don dep cac process cu..." "INFO"
    
    # Stop PM2
    try {
        pm2 kill 2>$null | Out-Null
        Start-Sleep -Seconds 3
        Write-Log "PM2 daemon da dung" "SUCCESS"
    } catch {
        Write-Log "PM2 khong chay" "INFO"
    }
    
    # Stop related processes
    @("cloudflared", "node") | ForEach-Object {
        $processes = Get-Process -Name $_ -ErrorAction SilentlyContinue
        if ($processes) {
            $processes | Stop-Process -Force -ErrorAction SilentlyContinue
            Write-Log "Da dung $_ processes ($($processes.Count))" "SUCCESS"
            Start-Sleep -Seconds 1
        }
    }
}

# ============================================
# START CLOUDFLARE TUNNEL
# ============================================
function Start-CloudflareTunnel {
    Write-Log "Khoi dong Cloudflare tunnel..." "INFO"
    
    try {
        # Start tunnel in background (hidden window)
        $process = Start-Process -FilePath "C:\cloudflared\cloudflared.exe" -ArgumentList "tunnel", "--config", "C:\cloudflared\config.yml", "run" -WindowStyle Hidden -PassThru
        Start-Sleep -Seconds 8
        
        if ($process -and -not $process.HasExited) {
            Write-Log "Cloudflare tunnel da khoi dong (PID: $($process.Id))" "SUCCESS"
            return $true
        } else {
            Write-Log "Khong the khoi dong Cloudflare tunnel" "ERROR"
            return $false
        }
        
    } catch {
        Write-Log "Loi khoi dong tunnel: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ============================================
# START N8N PRODUCTION
# ============================================
function Start-N8nProduction {
    Write-Log "Khoi dong n8n production..." "INFO"
    
    try {
        # Load environment variables
        if (Test-Path ".env.production") {
            Get-Content ".env.production" | ForEach-Object {
                if ($_ -match "^([^#].*)=(.*)$") {
                    $name = $matches[1].Trim()
                    $value = $matches[2].Trim()
                    [Environment]::SetEnvironmentVariable($name, $value, "Process")
                    Write-Log "Loaded env: $name" "INFO"
                }
            }
        }
        
        # Stop any existing n8n process
        try {
            pm2 stop strangematic-hub 2>$null | Out-Null
            pm2 delete strangematic-hub 2>$null | Out-Null
            Start-Sleep -Seconds 3
        } catch {
            # No existing process
        }
        
        # Start n8n with PM2 (using Windows-specific hidden start)
        Write-Log "Khoi dong PM2 voi ecosystem config..." "INFO"
        
        # Use cmd with /B flag to start without new window
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = "cmd.exe"
        $startInfo.Arguments = "/c pm2 start ecosystem-stable.config.js --env production"
        $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $startInfo.CreateNoWindow = $true
        $startInfo.UseShellExecute = $false
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        $process.Start() | Out-Null
        $process.WaitForExit()
        
        Start-Sleep -Seconds 25  # Wait for full startup
        
        # Check if process is running
        $pmList = pm2 list 2>$null
        $n8nOnline = $pmList | Select-String "strangematic-hub.*online"
        
        if ($n8nOnline) {
            Write-Log "n8n da khoi dong thanh cong voi PM2" "SUCCESS"
            
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
                Write-Log "Da an cac cua so node.exe" "INFO"
            } catch {
                Write-Log "Khong the an cua so node.exe: $($_.Exception.Message)" "WARNING"
            }
            
            # Test web interface
            $webReady = $false
            $webRetries = 0
            Write-Log "Kiem tra web interface..." "INFO"
            
            while (-not $webReady -and $webRetries -lt 12) {
                try {
                    $response = Invoke-WebRequest -Uri "http://localhost:5678" -TimeoutSec 8 -UseBasicParsing
                    if ($response.StatusCode -eq 200) {
                        $webReady = $true
                        Write-Log "n8n web interface da san sang" "SUCCESS"
                    }
                } catch {
                    $webRetries++
                    Write-Log "Dang cho web interface... ($webRetries/12)" "INFO"
                    Start-Sleep -Seconds 5
                }
            }
            
            if (-not $webReady) {
                Write-Log "Web interface chua phan hoi nhung process da chay" "WARNING"
            }
            
            return $true
        } else {
            Write-Log "n8n khong khoi dong duoc" "ERROR"
            
            # Show logs for debugging
            Write-Log "Kiem tra PM2 logs..." "INFO"
            try {
                $logs = pm2 logs strangematic-hub --lines 10 --nostream 2>$null
                if ($logs) {
                    Write-Log "PM2 logs gan day:" "WARNING"
                    $logs | ForEach-Object { Write-Log $_ "WARNING" }
                }
            } catch {
                Write-Log "Khong the lay PM2 logs" "WARNING"
            }
            
            return $false
        }
        
    } catch {
        Write-Log "Loi khoi dong n8n: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ============================================
# HEALTH CHECK
# ============================================
function Test-SystemHealth {
    Write-Log "Kiem tra tinh trang he thong..." "INFO"
    $healthScore = 0
    $totalChecks = 4
    
    # Database check
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect("localhost", 5432)
        $tcpClient.Close()
        $healthScore++
        Write-Log "Database: OK" "SUCCESS"
    } catch {
        Write-Log "Database: FAILED" "ERROR"
    }
    
    # Local n8n check
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5678" -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            $healthScore++
            Write-Log "n8n Local: OK" "SUCCESS"
        }
    } catch {
        Write-Log "n8n Local: FAILED" "ERROR"
    }
    
    # Domain check
    try {
        $response = Invoke-WebRequest -Uri "https://app.strangematic.com" -TimeoutSec 15 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            $healthScore++
            Write-Log "Domain: OK" "SUCCESS"
        }
    } catch {
        Write-Log "Domain: FAILED (co the dang khoi tao)" "WARNING"
    }
    
    # Process check
    $cloudflaredRunning = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
    $nodeRunning = Get-Process -Name "node" -ErrorAction SilentlyContinue
    if ($cloudflaredRunning -and $nodeRunning) {
        $healthScore++
        Write-Log "Processes: OK" "SUCCESS"
    } else {
        Write-Log "Processes: FAILED" "ERROR"
    }
    
    $healthPercent = [math]::Round(($healthScore / $totalChecks) * 100)
    $healthStatus = if ($healthPercent -ge 75) { "SUCCESS" } elseif ($healthPercent -ge 50) { "WARNING" } else { "ERROR" }
    Write-Log "Tong ket: $healthScore/$totalChecks ($healthPercent%)" $healthStatus
    
    return $healthPercent -ge 75
}

# ============================================
# MAIN EXECUTION
# ============================================

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "[START] N8N MANUAL STARTUP - STRANGEMATIC" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Check admin privileges
Test-AdminPrivileges | Out-Null

# Set location to script directory
Set-Location $PSScriptRoot

# Prerequisites check
if (-not (Test-Prerequisites)) {
    Write-Log "Dieu kien tien quyet khong du - dung script" "ERROR"
    if (-not $Silent) {
        Read-Host "Nhan Enter de thoat"
    }
    exit 1
}

# Stop existing processes
Stop-ExistingProcesses

# Start Cloudflare tunnel
if (-not (Start-CloudflareTunnel)) {
    Write-Log "Khong the khoi dong tunnel - dung script" "ERROR"
    if (-not $Silent) {
        Read-Host "Nhan Enter de thoat"
    }
    exit 1
}

# Start n8n
if (-not (Start-N8nProduction)) {
    Write-Log "Khong the khoi dong n8n - dung script" "ERROR"
    if (-not $Silent) {
        Read-Host "Nhan Enter de thoat"
    }
    exit 1
}

# Final health check
Write-Host ""
Write-Host "=======================================" -ForegroundColor Green
Write-Host "[CHECK] KIEM TRA CUOI CUNG" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

$systemHealthy = Test-SystemHealth

Write-Host ""
if ($systemHealthy) {
    Write-Host "[SUCCESS] HE THONG DA KHOI DONG THANH CONG!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[URL] Cac URL truy cap:" -ForegroundColor Cyan
    Write-Host "   • Local:  http://localhost:5678" -ForegroundColor White
    Write-Host "   • Domain: https://app.strangematic.com" -ForegroundColor White
    Write-Host "   • API:    https://api.strangematic.com" -ForegroundColor White
} else {
    Write-Host "[WARNING] HE THONG KHOI DONG VOI MOT SO VAN DE" -ForegroundColor Yellow
    Write-Host "   Hay kiem tra logs o tren de biet chi tiet" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[STATUS] PM2 Status:" -ForegroundColor Cyan
try {
    pm2 list
} catch {
    Write-Host "Khong the hien thi PM2 status" -ForegroundColor Red
}

Write-Host ""
if (-not $Silent) {
    Read-Host "Nhan Enter de thoat"
}
