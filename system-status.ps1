# ============================================
# 📊 STRANGEMATIC SYSTEM STATUS CHECKER
# ============================================
# Comprehensive status monitoring for automation hub

param(
    [switch]$Detailed,
    [switch]$Monitor,
    [int]$MonitorInterval = 30
)

Write-Host "📊 STRANGEMATIC SYSTEM STATUS" -ForegroundColor Green
Write-Host "=" * 50

function Test-PostgreSQL {
    Write-Host "`n🗄️ PostgreSQL Status:" -ForegroundColor Yellow
    
    try {
        $service = Get-Service -Name "PostgreSQL*" -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq "Running") {
            Write-Host "✅ Service: Running ($($service.DisplayName))" -ForegroundColor Green
            
            # Test connection
            try {
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $tcpClient.Connect("localhost", 5432)
                $tcpClient.Close()
                Write-Host "✅ Connection: Port 5432 accessible" -ForegroundColor Green
            } catch {
                Write-Host "❌ Connection: Port 5432 not accessible" -ForegroundColor Red
            }
        } else {
            Write-Host "❌ Service: Not running or not found" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Error checking PostgreSQL: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-PM2Status {
    Write-Host "`n🔧 PM2 Status:" -ForegroundColor Yellow
    
    try {
        $pm2Output = pm2 jlist | ConvertFrom-Json
        if ($pm2Output) {
            foreach ($app in $pm2Output) {
                $status = if ($app.pm2_env.status -eq "online") { "✅" } else { "❌" }
                $memory = [math]::Round($app.monit.memory / 1MB, 1)
                $cpu = $app.monit.cpu
                
                Write-Host "$status $($app.name): $($app.pm2_env.status) (CPU: $cpu%, RAM: ${memory}MB)" -ForegroundColor $(if ($app.pm2_env.status -eq "online") { "Green" } else { "Red" })
                
                if ($Detailed) {
                    Write-Host "    Uptime: $($app.pm2_env.pm_uptime)" -ForegroundColor Gray
                    Write-Host "    Restarts: $($app.pm2_env.restart_time)" -ForegroundColor Gray
                }
            }
        } else {
            Write-Host "ℹ️ No PM2 processes running" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "❌ PM2 not available or error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-ProcessStatus {
    Write-Host "`n🔍 Process Status:" -ForegroundColor Yellow
    
    $targetProcesses = @("node", "cloudflared")
    
    foreach ($processName in $targetProcesses) {
        $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if ($processes) {
            Write-Host "✅ $processName processes: $($processes.Count)" -ForegroundColor Green
            if ($Detailed) {
                $processes | Format-Table Name, Id, CPU, WorkingSet -AutoSize
            }
        } else {
            Write-Host "❌ $processName: No processes found" -ForegroundColor Red
        }
    }
}

function Test-NetworkConnectivity {
    Write-Host "`n🌐 Network Connectivity:" -ForegroundColor Yellow
    
    $endpoints = @{
        "Localhost n8n" = "http://localhost:5678"
        "Domain HTTPS" = "https://app.strangematic.com"
        "API Endpoint" = "https://api.strangematic.com"
        "Status Page" = "https://status.strangematic.com"
    }
    
    foreach ($endpoint in $endpoints.GetEnumerator()) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint.Value -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
            Write-Host "✅ $($endpoint.Key): $($response.StatusCode)" -ForegroundColor Green
            
            if ($Detailed) {
                Write-Host "    Response Time: $($response.Headers.'x-response-time')" -ForegroundColor Gray
                Write-Host "    Content Length: $($response.Content.Length) bytes" -ForegroundColor Gray
            }
        } catch {
            Write-Host "❌ $($endpoint.Key): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Test-SystemResources {
    Write-Host "`n💻 System Resources:" -ForegroundColor Yellow
    
    # CPU Usage
    $cpu = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 2
    $cpuUsage = [math]::Round(($cpu.CounterSamples | Measure-Object CookedValue -Average).Average, 1)
    $cpuStatus = if ($cpuUsage -lt 70) { "✅" } else { "⚠️" }
    Write-Host "$cpuStatus CPU Usage: $cpuUsage%" -ForegroundColor $(if ($cpuUsage -lt 70) { "Green" } else { "Yellow" })
    
    # Memory Usage
    $memory = Get-CimInstance -ClassName Win32_OperatingSystem
    $totalMemGB = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 1)
    $freeMemGB = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)
    $usedMemGB = $totalMemGB - $freeMemGB
    $memUsagePercent = [math]::Round(($usedMemGB / $totalMemGB) * 100, 1)
    
    $memStatus = if ($memUsagePercent -lt 80) { "✅" } else { "⚠️" }
    Write-Host "$memStatus Memory Usage: $usedMemGB/$totalMemGB GB ($memUsagePercent%)" -ForegroundColor $(if ($memUsagePercent -lt 80) { "Green" } else { "Yellow" })
    
    # Disk Space
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    foreach ($drive in $disk) {
        $totalGB = [math]::Round($drive.Size / 1GB, 1)
        $freeGB = [math]::Round($drive.FreeSpace / 1GB, 1)
        $usedGB = $totalGB - $freeGB
        $diskUsagePercent = [math]::Round(($usedGB / $totalGB) * 100, 1)
        
        $diskStatus = if ($diskUsagePercent -lt 85) { "✅" } else { "⚠️" }
        Write-Host "$diskStatus Disk $($drive.DeviceID) Usage: $usedGB/$totalGB GB ($diskUsagePercent%)" -ForegroundColor $(if ($diskUsagePercent -lt 85) { "Green" } else { "Yellow" })
    }
}

function Test-ServiceHealth {
    Write-Host "`n🏥 Service Health Check:" -ForegroundColor Yellow
    
    $healthChecks = @{
        "Database Connection" = {
            try {
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $tcpClient.Connect("localhost", 5432)
                $tcpClient.Close()
                return $true
            } catch { return $false }
        }
        "n8n Web Interface" = {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:5678" -TimeoutSec 5 -UseBasicParsing
                return $response.StatusCode -eq 200
            } catch { return $false }
        }
        "Domain SSL" = {
            try {
                $response = Invoke-WebRequest -Uri "https://app.strangematic.com" -TimeoutSec 10 -UseBasicParsing
                return $response.StatusCode -eq 200
            } catch { return $false }
        }
        "Cloudflare Tunnel" = {
            $process = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
            return $process -ne $null
        }
    }
    
    foreach ($check in $healthChecks.GetEnumerator()) {
        $result = & $check.Value
        $status = if ($result) { "✅" } else { "❌" }
        $color = if ($result) { "Green" } else { "Red" }
        Write-Host "$status $($check.Key)" -ForegroundColor $color
    }
}

function Show-QuickSummary {
    Write-Host "`n⚡ QUICK SUMMARY:" -ForegroundColor Cyan
    
    # Overall system health score
    $score = 0
    $total = 6
    
    # Check PM2
    try {
        $pm2 = pm2 jlist | ConvertFrom-Json
        if ($pm2 -and ($pm2 | Where-Object { $_.pm2_env.status -eq "online" })) { $score++ }
    } catch { }
    
    # Check processes
    if (Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue) { $score++ }
    if (Get-Process -Name "node" -ErrorAction SilentlyContinue) { $score++ }
    
    # Check services
    $pgService = Get-Service -Name "PostgreSQL*" -ErrorAction SilentlyContinue
    if ($pgService -and $pgService.Status -eq "Running") { $score++ }
    
    # Check connectivity
    try {
        $local = Invoke-WebRequest -Uri "http://localhost:5678" -TimeoutSec 5 -UseBasicParsing
        if ($local.StatusCode -eq 200) { $score++ }
    } catch { }
    
    try {
        $domain = Invoke-WebRequest -Uri "https://app.strangematic.com" -TimeoutSec 10 -UseBasicParsing
        if ($domain.StatusCode -eq 200) { $score++ }
    } catch { }
    
    $percentage = [math]::Round(($score / $total) * 100)
    $healthColor = if ($percentage -ge 80) { "Green" } elseif ($percentage -ge 60) { "Yellow" } else { "Red" }
    
    Write-Host "🎯 System Health: $score/$total ($percentage%)" -ForegroundColor $healthColor
    
    if ($percentage -eq 100) {
        Write-Host "🎉 All systems operational!" -ForegroundColor Green
        Write-Host "🌐 Access: https://app.strangematic.com" -ForegroundColor Cyan
    } elseif ($percentage -ge 80) {
        Write-Host "⚠️ System mostly operational with minor issues" -ForegroundColor Yellow
    } else {
        Write-Host "❌ System has significant issues requiring attention" -ForegroundColor Red
    }
}

# Main execution
if ($Monitor) {
    Write-Host "Starting monitoring mode (Interval: $MonitorInterval seconds)" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Gray
    
    while ($true) {
        Clear-Host
        Write-Host "📊 STRANGEMATIC SYSTEM MONITOR - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
        Write-Host "=" * 70
        
        Show-QuickSummary
        Test-PM2Status
        Test-NetworkConnectivity
        
        Write-Host "`n⏱️ Next update in $MonitorInterval seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds $MonitorInterval
    }
} else {
    # Single run mode
    Test-PostgreSQL
    Test-PM2Status
    Test-ProcessStatus
    Test-NetworkConnectivity
    
    if ($Detailed) {
        Test-SystemResources
        Test-ServiceHealth
    }
    
    Show-QuickSummary
    
    Write-Host "`n" + "=" * 50
    Write-Host "Status check completed at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
}
