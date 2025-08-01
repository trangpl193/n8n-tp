# StrangematicHub PM2 Auto-Startup Solution

A comprehensive Windows Task Scheduler solution for automatically starting PM2 daemon and n8n application on system boot, with health monitoring and auto-recovery capabilities.

## 📋 Overview

This solution provides enterprise-grade automation for PM2 and n8n startup on Windows systems, featuring:

- **Automatic startup** on Windows boot with dependency checking
- **Health monitoring** every 5 minutes with auto-recovery
- **Comprehensive logging** to files and Windows Event Log
- **Retry mechanisms** with exponential backoff
- **Performance monitoring** and alerting
- **Easy installation** and management

## 🏗️ Architecture

### Components

1. **[`pm2-auto-startup.ps1`](pm2-auto-startup.ps1)** - Main startup script
2. **[`StrangematicPM2Management.psm1`](StrangematicPM2Management.psm1)** - PowerShell management module
3. **[`StrangematicHub-AutoStart.xml`](StrangematicHub-AutoStart.xml)** - Task Scheduler configuration
4. **[`pm2-health-monitor.ps1`](pm2-health-monitor.ps1)** - Health monitoring script
5. **[`install-pm2-autostart.ps1`](install-pm2-autostart.ps1)** - Installation and setup script

### Startup Sequence

```
Windows Boot
    ↓ (60s delay)
PostgreSQL Check (60s timeout)
    ↓
Network Connectivity Check (30s timeout)
    ↓
PM2 Daemon Start (3 retries, 60s intervals)
    ↓
n8n Application Start (3 retries, 60s intervals)
    ↓
Health Check Verification
    ↓
Health Monitor (every 5 minutes)
```

## 🚀 Quick Start

### Prerequisites

- Windows 11 (or Windows 10)
- PowerShell 5.1 or higher
- Administrator privileges
- Node.js installed
- PM2 installed (`npm install -g pm2`)
- n8n installed (`npm install -g n8n`)

### Installation

1. **Clone or download** all script files to a directory (e.g., `C:\Github\n8n-tp\scripts\`)

2. **Run the installer** as Administrator:
   ```powershell
   # Open PowerShell as Administrator
   cd C:\Github\n8n-tp\scripts
   .\install-pm2-autostart.ps1
   ```

3. **Restart your computer** to test the auto-startup functionality

### Verification

Check if tasks are installed:
```powershell
Get-ScheduledTask -TaskName "StrangematicHub*"
```

View recent logs:
```powershell
Get-Content "C:\ProgramData\StrangematicHub\Logs\pm2-auto-startup-$(Get-Date -Format 'yyyyMMdd').log" -Tail 20
```

## 📖 Detailed Usage

### Manual Task Execution

Test the auto-startup manually:
```powershell
Start-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart"
```

Run health monitor once:
```powershell
Start-ScheduledTask -TaskName "StrangematicHub-PM2-HealthMonitor"
```

### PowerShell Module Functions

Import the management module:
```powershell
Import-Module ".\StrangematicPM2Management.psm1"
```

Available functions:
```powershell
# Check PM2 status
Get-PM2Status

# Start PM2 daemon
Start-PM2Daemon

# Check n8n status
Get-N8NStatus

# Start n8n application
Start-N8NApplication

# Perform health check
Invoke-HealthCheck

# Get PM2 logs
Get-PM2Logs -Lines 50

# Reset PM2 (kill and restart)
Reset-PM2
```

### Health Monitor Options

Run health monitor with custom settings:
```powershell
.\pm2-health-monitor.ps1 -CheckIntervalMinutes 10 -AlertThreshold 5 -RunOnce
```

Parameters:
- `-CheckIntervalMinutes`: How often to check (default: 5)
- `-AlertThreshold`: Max failures before requiring manual intervention (default: 3)
- `-AutoRecoveryMaxAttempts`: Max auto-recovery attempts (default: 2)
- `-RunOnce`: Run a single check and exit
- `-EnablePerformanceMonitoring`: Enable system performance monitoring

### Installation Options

```powershell
# Install with custom paths
.\install-pm2-autostart.ps1 -LogPath "D:\Logs\StrangematicHub" -ScriptPath "D:\Scripts"

# Force reinstall (overwrite existing tasks)
.\install-pm2-autostart.ps1 -Force

# Test installation without installing
.\install-pm2-autostart.ps1 -TestOnly

# Uninstall all tasks
.\install-pm2-autostart.ps1 -Uninstall
```

## 📊 Monitoring and Logging

### Log Locations

- **Main logs**: `C:\ProgramData\StrangematicHub\Logs\`
- **Windows Event Log**: Application log, source "StrangematicHub"
- **Task Scheduler logs**: Task Scheduler Library → StrangematicHub

### Log Files

- `pm2-auto-startup-YYYYMMDD.log` - Auto-startup execution logs
- `pm2-health-monitor-YYYYMMDD.log` - Health monitoring logs
- `pm2-autostart-install-YYYYMMDD-HHMMSS.log` - Installation logs
- `alert-counter.json` - Failure counter for alerting

### Event Log Integration

View StrangematicHub events:
```powershell
Get-EventLog -LogName Application -Source "StrangematicHub" -Newest 10
```

## 🔧 Configuration

### Customizing Timeouts

Edit [`pm2-auto-startup.ps1`](pm2-auto-startup.ps1) parameters:
```powershell
param(
    [int]$PostgreSQLTimeoutSeconds = 60,    # PostgreSQL wait time
    [int]$NetworkTimeoutSeconds = 30,       # Network connectivity timeout
    [int]$MaxRetries = 3,                   # Max retry attempts
    [int]$RetryDelaySeconds = 60            # Delay between retries
)
```

### Modifying Task Schedule

Edit [`StrangematicHub-AutoStart.xml`](StrangematicHub-AutoStart.xml):
- Change `<Delay>PT60S</Delay>` to modify boot delay
- Modify `<RestartPolicy>` for different retry behavior

### Health Monitor Frequency

The health monitor runs every 5 minutes by default. To change:
1. Uninstall existing task: `.\install-pm2-autostart.ps1 -Uninstall`
2. Edit the installation script's trigger interval
3. Reinstall: `.\install-pm2-autostart.ps1`

## 🚨 Troubleshooting

### Common Issues

**PM2 not starting:**
```powershell
# Check if PM2 is in PATH
pm2 --version

# Check PM2 status
Get-PM2Status

# Reset PM2
Reset-PM2
```

**n8n not starting:**
```powershell
# Check if n8n is installed
n8n --version

# Check n8n status
Get-N8NStatus

# View PM2 logs
Get-PM2Logs
```

**Task not running:**
```powershell
# Check task status
Get-ScheduledTask -TaskName "StrangematicHub*"

# View task history
Get-ScheduledTaskInfo -TaskName "StrangematicHub-PM2-AutoStart"

# Run task manually
Start-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart"
```

### Debug Mode

Enable verbose logging by editing scripts and changing log levels to "Debug".

### Manual Recovery

If auto-recovery fails:
```powershell
# Stop all PM2 processes
pm2 kill

# Start PM2 daemon
pm2 ping

# Start n8n
pm2 start n8n --name n8n

# Verify status
pm2 status
```

## 🔒 Security Considerations

- Tasks run with **SYSTEM** privileges for pre-login capability
- Scripts use **ExecutionPolicy Bypass** - ensure scripts are from trusted sources
- Log files contain system information - secure log directory appropriately
- Event Log entries are visible to all users - avoid logging sensitive data

## 📈 Performance Impact

- **Boot delay**: 60 seconds (configurable)
- **Memory usage**: ~10-20MB for PowerShell processes
- **CPU usage**: Minimal during normal operation
- **Disk I/O**: Log files rotate daily, health checks every 5 minutes

## 🔄 Updates and Maintenance

### Updating Scripts

1. Stop running tasks:
   ```powershell
   Stop-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart"
   Stop-ScheduledTask -TaskName "StrangematicHub-PM2-HealthMonitor"
   ```

2. Update script files

3. Reinstall tasks:
   ```powershell
   .\install-pm2-autostart.ps1 -Force
   ```

### Log Rotation

Logs are created daily. To clean old logs:
```powershell
# Remove logs older than 30 days
Get-ChildItem "C:\ProgramData\StrangematicHub\Logs\*.log" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item
```

## 📋 Task Scheduler Details

### Auto-Start Task
- **Name**: StrangematicHub-PM2-AutoStart
- **Trigger**: At system startup (60s delay)
- **User**: SYSTEM
- **Run Level**: Highest Available
- **Restart Policy**: 3 attempts, 1-minute intervals

### Health Monitor Task
- **Name**: StrangematicHub-PM2-HealthMonitor
- **Trigger**: Every 5 minutes (starts 5 minutes after boot)
- **User**: SYSTEM
- **Run Level**: Highest Available
- **Duration**: Indefinite

## 🆘 Support

### Getting Help

1. **Check logs** in `C:\ProgramData\StrangematicHub\Logs\`
2. **View Event Log** for StrangematicHub events
3. **Run health check** manually: `Invoke-HealthCheck`
4. **Test installation**: `.\install-pm2-autostart.ps1 -TestOnly`

### Reporting Issues

When reporting issues, include:
- Windows version and PowerShell version
- Complete error messages from logs
- Output of `Get-ScheduledTaskInfo` for both tasks
- PM2 and n8n versions

## 📄 License

This solution is part of the StrangematicHub infrastructure automation toolkit.

---

**Version**: 1.0.0  
**Last Updated**: January 2025  
**Compatibility**: Windows 11, Windows 10, PowerShell 5.1+