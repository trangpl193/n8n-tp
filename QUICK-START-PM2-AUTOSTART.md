# Quick Start Guide - StrangematicHub PM2 Auto-Startup

## 🚀 5-Minute Setup

### Prerequisites
- Windows 10/11 với Administrator privileges
- PowerShell 5.1+
- Node.js và npm installed

### Installation
```powershell
# 1. Open PowerShell as Administrator
# 2. Navigate to project directory
cd C:\Github\n8n-tp\scripts

# 3. Install dependencies (if needed)
npm install -g pm2 n8n

# 4. Run installation
.\install-pm2-autostart.ps1

# 5. Verify installation
.\test-pm2-autostart.ps1 -SkipInteractive
```

## ⚡ Essential Commands

### Quick Status Check
```powershell
cd C:\Github\n8n-tp\scripts
Import-Module .\StrangematicPM2Management.psm1 -Force

# Check everything
Invoke-HealthCheck

# Individual checks
Get-PM2Status
Get-N8NStatus
```

### Service Management
```powershell
# Start services
Start-PM2Daemon
Start-N8NApplication

# Restart n8n
Restart-N8NApplication

# Stop n8n
Stop-N8NApplication

# Emergency reset
Reset-PM2
```

### View Logs
```powershell
# PM2 logs
Get-PM2Logs -Lines 50

# System logs
Get-Content "C:\ProgramData\StrangematicHub\Logs\pm2-auto-startup-*.log" -Tail 20
```

## 🔧 Common Tasks

### Check if Auto-Startup is Working
```powershell
# Check scheduled tasks
Get-ScheduledTask -TaskName "*StrangematicHub*"

# Manual test
Start-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart"
```

### Troubleshooting
```powershell
# Run comprehensive test
.\test-pm2-autostart.ps1

# Interactive demo
.\demo-pm2-management.ps1

# Check dependencies
node --version
pm2 --version
n8n --version
```

### Access n8n Web Interface
- Open browser: http://localhost:5678
- Default domain: http://strangematic.com:5678

## 🆘 Emergency Procedures

### n8n Won't Start
```powershell
# 1. Check PM2 first
Get-PM2Status

# 2. Start PM2 if needed
Start-PM2Daemon

# 3. Start n8n
Start-N8NApplication

# 4. Check port conflicts
Get-NetTCPConnection -LocalPort 5678
```

### Complete System Reset
```powershell
# WARNING: This stops all services
Reset-PM2
Start-Sleep -Seconds 10
Start-PM2Daemon
Start-N8NApplication
```

### Reinstall Tasks
```powershell
# Remove and recreate scheduled tasks
.\install-pm2-autostart.ps1 -Uninstall
.\install-pm2-autostart.ps1 -Force
```

## 📊 Verification Checklist

After installation, verify these items:

- [ ] **Scheduled Tasks Created**
  ```powershell
  Get-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart"
  Get-ScheduledTask -TaskName "StrangematicHub-PM2-HealthMonitor"
  ```

- [ ] **Services Running**
  ```powershell
  Get-PM2Status | Select-Object IsRunning
  Get-N8NStatus | Select-Object IsRunning
  ```

- [ ] **Web Interface Accessible**
  - Open http://localhost:5678 in browser

- [ ] **Auto-Startup Works**
  ```powershell
  # Test task manually
  Start-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart"
  ```

- [ ] **Health Monitoring Active**
  ```powershell
  # Check recent health monitor logs
  Get-ChildItem "C:\ProgramData\StrangematicHub\Logs\pm2-health-monitor-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  ```

## 🔗 Quick Links

| Resource | Location | Purpose |
|----------|----------|---------|
| **Installation Guide** | [`docs/deployment/PM2-AutoStart-Installation-Guide.md`](docs/deployment/PM2-AutoStart-Installation-Guide.md) | Detailed setup instructions |
| **User Guide** | [`docs/deployment/PM2-AutoStart-User-Guide.md`](docs/deployment/PM2-AutoStart-User-Guide.md) | Daily operations manual |
| **Test Script** | [`scripts/test-pm2-autostart.ps1`](scripts/test-pm2-autostart.ps1) | Comprehensive testing |
| **Demo Script** | [`scripts/demo-pm2-management.ps1`](scripts/demo-pm2-management.ps1) | Interactive feature demo |
| **PowerShell Module** | [`scripts/StrangematicPM2Management.psm1`](scripts/StrangematicPM2Management.psm1) | Core management functions |

## 📞 Quick Help

### Common Error Messages

| Error | Solution |
|-------|----------|
| "PM2 executable not found" | Install PM2: `npm install -g pm2` |
| "Access denied" | Run PowerShell as Administrator |
| "Task already exists" | Use `-Force` parameter |
| "Port 5678 in use" | Check for conflicting processes |
| "n8n not found" | Install n8n: `npm install -g n8n` |

### Performance Issues

| Symptom | Quick Fix |
|---------|-----------|
| Slow startup | Check system resources |
| High memory usage | Restart n8n: `Restart-N8NApplication` |
| Service crashes | Check logs: `Get-PM2Logs` |
| Auto-start fails | Verify task: `Get-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart"` |

## 🎯 Next Steps

After completing quick start:

1. **Explore Features**: Run [`demo-pm2-management.ps1`](scripts/demo-pm2-management.ps1)
2. **Read User Guide**: Review daily operations in [`PM2-AutoStart-User-Guide.md`](docs/deployment/PM2-AutoStart-User-Guide.md)
3. **Set Up Monitoring**: Configure alerts và notifications
4. **Backup Configuration**: Export scheduled tasks và scripts
5. **Schedule Maintenance**: Plan regular health checks

## 📋 PowerShell Aliases (Optional)

Add to your PowerShell profile for quick access:

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

# Quick navigation
function goto-scripts { Set-Location "C:\Github\n8n-tp\scripts" }
function goto-logs { Set-Location "C:\ProgramData\StrangematicHub\Logs" }

# Aliases
Set-Alias -Name pms -Value pm2-status
Set-Alias -Name n8ns -Value n8n-status
Set-Alias -Name hc -Value health-check
Set-Alias -Name pmr -Value pm2-restart
```

## 🏷️ Version Information

- **Solution Version**: 1.0.0
- **Last Updated**: 2025-01-01
- **Compatibility**: Windows 10/11, PowerShell 5.1+, Node.js 16+, PM2 5+, n8n 1.0+
- **Domain**: strangematic.com
- **Default Port**: 5678

---

**💡 Pro Tip**: Bookmark this page và keep it handy for quick reference. For detailed troubleshooting, always refer to the full User Guide.

**🔒 Security Note**: All tasks run with SYSTEM privileges để ensure pre-login startup capability. Review security settings regularly.

**📈 Monitoring**: Health monitoring runs every 5 minutes automatically. Check logs regularly for any issues.