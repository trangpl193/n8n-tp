# ============================================
# 🚀 N8N Manual Startup Script - Simplified
# ============================================
# Đơn giản hóa để khởi chạy manual n8n với đầy đủ thông số
# Chỉ chạy khi cần, không tự động

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
        Write-Log "Khởi động lại với quyền Administrator..." "WARNING"
        
        $scriptPath = $MyInvocation.MyCommand.Path
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptPath`"")
        if ($Silent) { $arguments += "-Silent" }
        
        try {
            Start-Process PowerShell -ArgumentList $arguments -Verb RunAs
            exit 0
        } catch {
            Write-Log "Không thể khởi động với quyền admin: $($_.Exception.Message)" "ERROR"
            Read-Host "Nhấn Enter để thoát"
            exit 1
        }
    }
    
    Write-Log "Đang chạy với quyền Administrator" "SUCCESS"
    return $true
}

# ============================================
# PREREQUISITES CHECK
# ============================================
function Test-Prerequisites {
    Write-Log "Kiểm tra các điều kiện tiên quyết..." "INFO"
    $allGood = $true
    
    # Check PostgreSQL Service
    try {
        $pgService = Get-Service -Name "postgresql-x64-17" -ErrorAction Stop
        if ($pgService.Status -eq "Running") {
            Write-Log "PostgreSQL service đang chạy" "SUCCESS"
        } else {
            Write-Log "PostgreSQL service không chạy - đang khởi động..." "WARNING"
            Start-Service -Name "postgresql-x64-17"
            Start-Sleep -Seconds 5
            Write-Log "PostgreSQL service đã được khởi động" "SUCCESS"
        }
    } catch {
        Write-Log "Lỗi PostgreSQL: $($_.Exception.Message)" "ERROR"
        $allGood = $false
    }
    
    # Check database connection
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect("localhost", 5432)
        $tcpClient.Close()
        Write-Log "Kết nối database thành công" "SUCCESS"
    } catch {
        Write-Log "Không thể kết nối database" "ERROR"
        $allGood = $false
    }
    
    # Check Cloudflared
    if (Test-Path "C:\cloudflared\cloudflared.exe") {
        Write-Log "Cloudflared executable có sẵn" "SUCCESS"
    } else {
        Write-Log "Cloudflared không tìm thấy" "ERROR"
        $allGood = $false
    }
    
    if (Test-Path "C:\cloudflared\config.yml") {
        Write-Log "Cloudflared config có sẵn" "SUCCESS"
    } else {
        Write-Log "Cloudflared config không tìm thấy" "ERROR"
        $allGood = $false
    }
    
    # Check n8n files
    if (Test-Path "ecosystem-stable.config.js") {
        Write-Log "n8n ecosystem config có sẵn" "SUCCESS"
    } else {
        Write-Log "n8n ecosystem config không tìm thấy" "ERROR"
        $allGood = $false
    }
    
    if (Test-Path ".env.production") {
        Write-Log "n8n environment file có sẵn" "SUCCESS"
    } else {
        Write-Log "n8n environment file không tìm thấy" "ERROR"
        $allGood = $false
    }
    
    return $allGood
}

# ============================================
# CLEANUP EXISTING PROCESSES
# ============================================
function Stop-ExistingProcesses {
    Write-Log "Dọn dẹp các process cũ..." "INFO"
    
    # Stop PM2
    try {
        pm2 kill 2>$null | Out-Null
        Start-Sleep -Seconds 3
        Write-Log "PM2 daemon đã dừng" "SUCCESS"
    } catch {
        Write-Log "PM2 không chạy" "INFO"
    }
    
    # Stop related processes
    @("cloudflared", "node") | ForEach-Object {
        $processes = Get-Process -Name $_ -ErrorAction SilentlyContinue
        if ($processes) {
            $processes | Stop-Process -Force -ErrorAction SilentlyContinue
            Write-Log "Đã dừng $_processes ($($processes.Count))" "SUCCESS"
            Start-Sleep -Seconds 1
        }
    }
}

# ============================================
# START CLOUDFLARE TUNNEL
# ============================================
function Start-CloudflareTunnel {
    Write-Log "Khởi động Cloudflare tunnel..." "INFO"
    
    try {
        # Start tunnel in background
        $process = Start-Process -FilePath "C:\cloudflared\cloudflared.exe" -ArgumentList "tunnel", "--config", "C:\cloudflared\config.yml", "run" -WindowStyle Hidden -PassThru
        Start-Sleep -Seconds 8
        
        if ($process -and -not $process.HasExited) {
            Write-Log "Cloudflare tunnel đã khởi động (PID: $($process.Id))" "SUCCESS"
            return $true
        } else {
            Write-Log "Không thể khởi động Cloudflare tunnel" "ERROR"
            return $false
        }
        
    } catch {
        Write-Log "Lỗi khởi động tunnel: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ============================================
# START N8N PRODUCTION
# ============================================
function Start-N8nProduction {
    Write-Log "Khởi động n8n production..." "INFO"
    
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
        
        # Start n8n with PM2
        Write-Log "Khởi động PM2 với ecosystem config..." "INFO"
        pm2 start ecosystem-stable.config.js --env production | Out-Null
        Start-Sleep -Seconds 25  # Wait for full startup
        
        # Check if process is running
        $pmList = pm2 list 2>$null
        $n8nOnline = $pmList | Select-String "strangematic-hub.*online"
        
        if ($n8nOnline) {
            Write-Log "n8n đã khởi động thành công với PM2" "SUCCESS"
            
            # Test web interface
            $webReady = $false
            $webRetries = 0
            Write-Log "Kiểm tra web interface..." "INFO"
            
            while (-not $webReady -and $webRetries -lt 12) {
                try {
                    $response = Invoke-WebRequest -Uri "http://localhost:5678" -TimeoutSec 8 -UseBasicParsing
                    if ($response.StatusCode -eq 200) {
                        $webReady = $true
                        Write-Log "n8n web interface đã sẵn sàng" "SUCCESS"
                    }
                } catch {
                    $webRetries++
                    Write-Log "Đang chờ web interface... ($webRetries/12)" "INFO"
                    Start-Sleep -Seconds 5
                }
            }
            
            if (-not $webReady) {
                Write-Log "Web interface chưa phản hồi nhưng process đã chạy" "WARNING"
            }
            
            return $true
        } else {
            Write-Log "n8n không khởi động được" "ERROR"
            
            # Show logs for debugging
            Write-Log "Kiểm tra PM2 logs..." "INFO"
            try {
                $logs = pm2 logs strangematic-hub --lines 10 --nostream 2>$null
                if ($logs) {
                    Write-Log "PM2 logs gần đây:" "WARNING"
                    $logs | ForEach-Object { Write-Log $_ "WARNING" }
                }
            } catch {
                Write-Log "Không thể lấy PM2 logs" "WARNING"
            }
            
            return $false
        }
        
    } catch {
        Write-Log "Lỗi khởi động n8n: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ============================================
# HEALTH CHECK
# ============================================
function Test-SystemHealth {
    Write-Log "Kiểm tra tình trạng hệ thống..." "INFO"
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
Write-Host "[OK] N8N MANUAL STARTUP - STRANGEMATIC" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Check admin privileges
Test-AdminPrivileges | Out-Null

# Set location to script directory
Set-Location $PSScriptRoot

# Prerequisites check
if (-not (Test-Prerequisites)) {
    Write-Log "Điều kiện tiên quyết không đủ - dừng script" "ERROR"
    if (-not $Silent) {
        Read-Host "Nhấn Enter để thoát"
    }
    exit 1
}

# Stop existing processes
Stop-ExistingProcesses

# Start Cloudflare tunnel
if (-not (Start-CloudflareTunnel)) {
    Write-Log "Không thể khởi động tunnel - dừng script" "ERROR"
    if (-not $Silent) {
        Read-Host "Nhấn Enter để thoát"
    }
    exit 1
}

# Start n8n
if (-not (Start-N8nProduction)) {
    Write-Log "Không thể khởi động n8n - dừng script" "ERROR"
    if (-not $Silent) {
        Read-Host "Nhấn Enter để thoát"
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
    Write-Host "Không thể hiển thị PM2 status" -ForegroundColor Red
}

Write-Host ""
if (-not $Silent) {
    Read-Host "Nhấn Enter để thoát"
}
