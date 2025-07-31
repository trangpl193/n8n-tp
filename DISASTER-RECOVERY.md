# 🛡️ DISASTER RECOVERY & BACKUP STRATEGY

## 1. SOURCE CODE RECOVERY

### **Git-based Recovery**
```powershell
# Rollback to last known good state
git log --oneline -10  # Xem 10 commits gần nhất
git checkout main      # Switch to stable production
git reset --hard HEAD~1  # Rollback 1 commit (if needed)

# Emergency hotfix branch
git checkout -b hotfix/emergency-fix-$(Get-Date -Format "yyyyMMdd-HHmm")
# Fix issue
git commit -m "hotfix: emergency fix description"
git checkout main
git merge hotfix/emergency-fix-*
```

### **PM2 Service Recovery**
```powershell
# Stop all services
pm2 stop all

# Restart from known good config
pm2 start ecosystem-stable.config.js
pm2 start ecosystem-tunnel.config.js

# Check status
pm2 status
pm2 logs --lines 50
```

## 2. DATABASE RECOVERY

### **Database Backup Strategy (Setup)**
```sql
-- Create backup directory
-- Run this daily via scheduled task

-- Production backup
pg_dump -U strangematic_user -h localhost -p 5432 strangematic_n8n > C:\backup\n8n_prod_$(date +%Y%m%d_%H%M%S).sql

-- Development backup  
pg_dump -U strangematic_dev -h localhost -p 5432 strangematic_n8n_dev > C:\backup\n8n_dev_$(date +%Y%m%d_%H%M%S).sql
```

### **Database Restore Process**
```powershell
# Stop n8n service first
pm2 stop strangematic-hub

# Connect to PostgreSQL
psql -U postgres -h localhost -p 5432

# Drop and recreate database (CAREFUL!)
DROP DATABASE strangematic_n8n;
CREATE DATABASE strangematic_n8n;
GRANT ALL PRIVILEGES ON DATABASE strangematic_n8n TO strangematic_user;

# Restore from backup
psql -U strangematic_user -h localhost -p 5432 -d strangematic_n8n -f C:\backup\n8n_prod_YYYYMMDD_HHMMSS.sql

# Restart service
pm2 start ecosystem-stable.config.js
```

## 3. FULL SYSTEM RECOVERY

### **Recovery Priority Order**
1. **Database Recovery** (Critical data)
2. **Source Code Recovery** (Git rollback)
3. **Service Recovery** (PM2 restart)
4. **Domain Recovery** (Cloudflare tunnel)

### **Emergency Recovery Script**
```powershell
# emergency-recovery.ps1
Write-Host "🚨 EMERGENCY RECOVERY PROTOCOL" -ForegroundColor Red

# Step 1: Stop all services
pm2 stop all

# Step 2: Git recovery to last known state
cd C:\Github\n8n-tp
git checkout main
git reset --hard HEAD~1  # Adjust as needed

# Step 3: Restart core services
pm2 start ecosystem-stable.config.js
pm2 start ecosystem-tunnel.config.js

# Step 4: Verify services
pm2 status
Invoke-WebRequest -Uri "https://app.strangematic.com" -Method GET

Write-Host "✅ Recovery completed. Check services status." -ForegroundColor Green
```

## 4. BACKUP AUTOMATION

### **Daily Backup Script**
```powershell
# daily-backup.ps1 (Schedule via Task Scheduler)
$BackupDir = "C:\backup\$(Get-Date -Format 'yyyy-MM-dd')"
New-Item -Path $BackupDir -ItemType Directory -Force

# Database backup
$env:PGPASSWORD = "postgres123"
pg_dump -U strangematic_user -h localhost -p 5432 strangematic_n8n > "$BackupDir\n8n_prod.sql"

# Git backup (create archive)
cd C:\Github\n8n-tp
git archive --format=zip --output="$BackupDir\n8n-source.zip" HEAD

# Config backup
Copy-Item "ecosystem-stable.config.js" "$BackupDir\"
Copy-Item "ecosystem-tunnel.config.js" "$BackupDir\"
Copy-Item ".env" "$BackupDir\"

Write-Host "✅ Daily backup completed: $BackupDir" -ForegroundColor Green
```

## 5. MONITORING & HEALTH CHECKS

### **Health Check Script**
```powershell
# health-check.ps1
Write-Host "🔍 SYSTEM HEALTH CHECK" -ForegroundColor Cyan

# PM2 processes
pm2 status

# Database connection
$env:PGPASSWORD = "postgres123"
psql -U strangematic_user -h localhost -p 5432 -d strangematic_n8n -c "SELECT NOW();"

# Domain connectivity
$Response = Invoke-WebRequest -Uri "https://app.strangematic.com" -Method GET
Write-Host "Domain Status: $($Response.StatusCode)" -ForegroundColor $(if($Response.StatusCode -eq 200){"Green"}else{"Red"})

# Disk space
Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"} | ForEach-Object {
    $FreeSpaceGB = [math]::Round($_.FreeSpace / 1GB, 2)
    Write-Host "Free Space: $FreeSpaceGB GB" -ForegroundColor $(if($FreeSpaceGB -gt 50){"Green"}else{"Yellow"})
}
```

---
*Disaster recovery strategy cho Dell OptiPlex 3060 - strangematic.com automation hub*
