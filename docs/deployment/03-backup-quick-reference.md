# Backup & Recovery Quick Reference Guide

**🚨 EMERGENCY CONTACT:** strangematic.com automation hub
**📱 Remote Access:** UltraViewer ID + Password
**🌐 Domain:** https://app.strangematic.com

---

## 🚨 EMERGENCY RECOVERY COMMANDS

### **⚡ Instant Database Recovery:**
```powershell
# CRITICAL: Stop all services first
pm2 stop all
Stop-Service postgresql-x64-14

# Quick restore latest database backup
$Latest = Get-ChildItem "C:\automation\backup\database" -Name "*.7z" | Sort-Object CreationTime -Descending | Select-Object -First 1
7z x "C:\automation\backup\database\$Latest" -o"C:\temp\emergency" -p"secure_backup_password"
psql -h localhost -U postgres -c "DROP DATABASE IF EXISTS strangematic_n8n; CREATE DATABASE strangematic_n8n OWNER strangematic_user;"
psql -h localhost -U strangematic_user -d strangematic_n8n -f "C:\temp\emergency\*.sql"

# Restart services
Start-Service postgresql-x64-14
pm2 start ecosystem.config.js
```

### **⚡ Instant Workflow Recovery:**
```powershell
# Quick restore workflows only
Set-Location "C:\automation\n8n"
$Latest = Get-ChildItem "C:\automation\backup\combined" -Name "*.7z" | Sort-Object CreationTime -Descending | Select-Object -First 1
7z x "C:\automation\backup\combined\$Latest" -o"C:\temp\workflow-emergency" -p"secure_export_password"
node packages/cli/bin/n8n import:workflow --separate --input="C:\temp\workflow-emergency\workflows"
pm2 restart strangematic-hub
```

---

## 📋 DAILY BACKUP CHECKLIST

### **✅ Manual Backup Verification:**
```powershell
# Quick health check
C:\automation\backup\scripts\backup-health-check.ps1

# Expected output:
# Database: HEALTHY (backup < 25 hours old)
# Workflows: HEALTHY (backup < 25 hours old)
# Source Code: HEALTHY (backup < 25 hours old)
# System: HEALTHY (backup < 7 days old)
```

### **⚠️ Critical File Locations:**
```yaml
Database Backups:    C:\automation\backup\database\*.7z
Workflow Exports:    C:\automation\backup\combined\*.7z
Source Code:         C:\automation\backup\source-code\*.7z
System Config:       C:\automation\backup\system\*.7z
Health Reports:      C:\automation\backup\health-report.json
```

---

## 🔄 SCHEDULED BACKUP STATUS

### **📅 Automatic Schedule:**
```yaml
Database Backup:     Every 6 hours (00:00, 06:00, 12:00, 18:00)
Workflow Export:     Daily at 02:00 AM
Source Code:         Daily at 03:00 AM
System Config:       Weekly Sundays at 04:00 AM
Health Check:        Every 15 minutes
```

### **🔍 Quick Status Check:**
```powershell
# Check scheduled tasks
Get-ScheduledTask | Where-Object {$_.TaskName -like "*Strangematic*"} | Format-Table TaskName, State, LastRunTime

# Check PM2 status
pm2 status

# Check disk space
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, @{Name="FreeGB";Expression={[math]::Round($_.FreeSpace/1GB,2)}}
```

---

## 🛠️ COMMON BACKUP OPERATIONS

### **📦 Manual Backup Execution:**
```powershell
# Run all backup scripts manually
C:\automation\backup\scripts\postgresql-backup.ps1
C:\automation\backup\scripts\n8n-workflow-backup.ps1
C:\automation\backup\scripts\source-code-backup.ps1
C:\automation\backup\scripts\system-config-backup.ps1
```

### **🧪 Test Backup Integrity:**
```powershell
# Monthly backup validation
C:\automation\backup\scripts\backup-test.ps1

# Expected results:
# ✅ Database backup integrity: PASS
# ✅ Workflow backup integrity: PASS
# ✅ Source code backup integrity: PASS
# ✅ Restore simulation: PASS
```

### **📊 Backup Metrics:**
```powershell
# Generate backup statistics
C:\automation\backup\scripts\backup-metrics.ps1

# View latest metrics
Get-Content "C:\automation\backup\metrics\backup-metrics_$(Get-Date -Format 'yyyy-MM-dd').json" | ConvertFrom-Json
```

---

## 🚨 RECOVERY SCENARIOS

### **Scenario A: Workflow Corruption**
```yaml
Symptoms: Workflows not executing, errors in n8n interface
Recovery Time: 5-10 minutes
Steps:
1. pm2 stop strangematic-hub
2. Run workflow recovery command (see above)
3. pm2 start strangematic-hub
4. Test critical workflows
```

### **Scenario B: Database Issues**
```yaml
Symptoms: n8n won't start, database connection errors
Recovery Time: 10-20 minutes
Steps:
1. Run database recovery command (see above)
2. Verify all workflows restored
3. Check execution history
4. Test webhook endpoints
```

### **Scenario C: Complete System Failure**
```yaml
Symptoms: System won't boot, hardware failure
Recovery Time: 2-4 hours
Steps:
1. Fresh Windows installation
2. Restore from system backup
3. Follow full deployment checklist
4. Validate all services
```

---

## 📞 EMERGENCY CONTACTS & PROCEDURES

### **🔧 Technical Issues:**
```yaml
Remote Access:
- UltraViewer: [ID] + [Password]
- Backup RDP: app.strangematic.com:3389

Critical Services:
- Cloudflare Tunnel: Check dashboard
- PostgreSQL: Check Windows services
- PM2: Check process status

Log Locations:
- n8n Logs: C:\automation\logs\strangematic.log
- System Logs: Windows Event Viewer
- Backup Logs: C:\automation\backup\*.log
```

### **📋 Escalation Procedure:**
```yaml
Level 1: Automated Recovery (5-10 min)
- Try emergency recovery commands
- Check scheduled task status
- Verify basic service health

Level 2: Manual Intervention (15-30 min)
- Remote access via UltraViewer
- Manual backup execution
- Service restart procedures

Level 3: Full Recovery (1-4 hours)
- System rebuild from backups
- Complete validation testing
- Documentation updates
```

---

## 🔍 TROUBLESHOOTING GUIDE

### **❌ Common Backup Issues:**

**Issue: "Backup failed - Access denied"**
```powershell
Solution:
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
# Check file permissions
icacls "C:\automation\backup" /grant "SYSTEM:(OI)(CI)F"
```

**Issue: "Database backup timeout"**
```powershell
Solution:
# Check PostgreSQL status
Get-Service postgresql-x64-14
# Increase timeout in backup script
$env:PGCONNECT_TIMEOUT = "60"
```

**Issue: "7-Zip compression failed"**
```powershell
Solution:
# Check disk space
Get-WmiObject -Class Win32_LogicalDisk
# Verify 7-Zip installation
where.exe 7z
```

**Issue: "n8n export command failed"**
```powershell
Solution:
# Check n8n service status
pm2 status strangematic-hub
# Verify database connection
psql -h localhost -U strangematic_user -d strangematic_n8n -c "SELECT COUNT(*) FROM workflow_entity;"
```

### **✅ Quick Diagnostics:**
```powershell
# Comprehensive system check
Write-Host "=== SYSTEM STATUS ===" -ForegroundColor Green
Get-Service postgresql-x64-14, cloudflared | Format-Table Name, Status
pm2 status
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, @{Name="FreeGB";Expression={[math]::Round($_.FreeSpace/1GB,2)}}

Write-Host "=== BACKUP STATUS ===" -ForegroundColor Yellow
Get-ChildItem "C:\automation\backup" -Recurse -Name "*.7z" | Measure-Object
Get-Content "C:\automation\backup\health-report.json" | ConvertFrom-Json | Select-Object Date, Status

Write-Host "=== NETWORK STATUS ===" -ForegroundColor Cyan
Test-NetConnection app.strangematic.com -Port 443
Test-NetConnection localhost -Port 5678
```

---

## 📚 RELATED DOCUMENTATION

- **[Full Backup Strategy](docs/deployment/02-backup-restore-strategy.md)** - Complete backup procedures
- **[Phase 1 Deployment](docs/deployment/01-phase1-foundation-checklist.md)** - Initial setup
- **[Hardware Configuration](.cursor/rules/hardware-configuration.mdc)** - System specs
- **[Strangematic Deployment](.cursor/rules/strangematic-deployment.mdc)** - Deployment rules

---

*Quick reference guide cho strangematic.com automation hub backup và recovery operations với emergency procedures for 24/7 availability.*
