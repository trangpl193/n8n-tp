# Hướng Dẫn Cài Đặt Chi Tiết - PM2 Auto-Startup Solution

## Tổng Quan

Tài liệu này cung cấp hướng dẫn từng bước để cài đặt và cấu hình giải pháp PM2 Auto-Startup cho StrangematicHub. Giải pháp này đảm bảo PM2 daemon và n8n application tự động khởi động khi Windows boot, kể cả trước khi user login.

### Kiến Trúc Giải Pháp

```
Windows Boot
    ↓
Task Scheduler (SYSTEM privileges)
    ↓
pm2-auto-startup.ps1
    ↓
StrangematicPM2Management.psm1
    ↓
PM2 Daemon → n8n Application
    ↓
pm2-health-monitor.ps1 (every 5 minutes)
```

## Prerequisites và System Requirements

### 1. System Requirements

| Component | Requirement | Ghi Chú |
|-----------|-------------|---------|
| **Operating System** | Windows 10/11 Pro/Enterprise | Home edition có thể có limitations |
| **PowerShell** | Version 5.1 hoặc cao hơn | Kiểm tra: `$PSVersionTable.PSVersion` |
| **Administrator Rights** | Required | Cần thiết cho Task Scheduler configuration |
| **Disk Space** | Tối thiểu 100MB free space | Cho logs và temporary files |
| **Memory** | Tối thiểu 4GB RAM | Recommended 8GB+ cho production |

### 2. Software Dependencies

#### Node.js và npm
```powershell
# Kiểm tra Node.js installation
node --version
npm --version

# Nếu chưa cài đặt, download từ: https://nodejs.org/
# Recommended: LTS version
```

#### PM2 Process Manager
```powershell
# Cài đặt PM2 globally
npm install -g pm2

# Kiểm tra installation
pm2 --version
pm2 list
```

#### n8n Workflow Automation
```powershell
# Cài đặt n8n globally
npm install -g n8n

# Kiểm tra installation
n8n --version
```

### 3. Network Requirements

- **Internet connectivity** cho npm package installation
- **Port 5432** available cho PostgreSQL (nếu sử dụng)
- **Port 5678** available cho n8n web interface (default)
- **Firewall rules** configured appropriately

## Cài Đặt Từng Bước

### Bước 1: Chuẩn Bị Environment

#### 1.1 Tạo Directory Structure
```powershell
# Chạy với Administrator privileges
New-Item -Path "C:\ProgramData\StrangematicHub" -ItemType Directory -Force
New-Item -Path "C:\ProgramData\StrangematicHub\Logs" -ItemType Directory -Force
New-Item -Path "C:\ProgramData\StrangematicHub\Reports" -ItemType Directory -Force
New-Item -Path "C:\ProgramData\StrangematicHub\Config" -ItemType Directory -Force
```

#### 1.2 Set Execution Policy
```powershell
# Kiểm tra current execution policy
Get-ExecutionPolicy

# Set execution policy (nếu cần)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

#### 1.3 Verify Prerequisites
```powershell
# Chạy script kiểm tra prerequisites
cd C:\Github\n8n-tp\scripts
.\test-pm2-autostart.ps1 -TestDependencies -SkipInteractive
```

### Bước 2: Download và Verify Scripts

#### 2.1 Verify Script Files
Đảm bảo các files sau có mặt trong `C:\Github\n8n-tp\scripts\`:

```
✓ install-pm2-autostart.ps1          # Installation script
✓ pm2-auto-startup.ps1               # Auto-startup script
✓ pm2-health-monitor.ps1             # Health monitoring script
✓ StrangematicPM2Management.psm1     # PowerShell module
✓ StrangematicHub-AutoStart.xml      # Task Scheduler template
✓ test-pm2-autostart.ps1             # Testing script
```

#### 2.2 Verify Script Integrity
```powershell
# Test script syntax
cd C:\Github\n8n-tp\scripts
Get-ChildItem *.ps1 | ForEach-Object {
    Write-Host "Testing $($_.Name)..." -ForegroundColor Yellow
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $_.FullName -Raw), [ref]$null)
    Write-Host "✓ $($_.Name) syntax OK" -ForegroundColor Green
}
```

### Bước 3: Chạy Installation Script

#### 3.1 Pre-Installation Test
```powershell
# Test installation prerequisites
cd C:\Github\n8n-tp\scripts
.\install-pm2-autostart.ps1 -TestOnly
```

#### 3.2 Run Installation
```powershell
# Chạy installation với Administrator privileges
cd C:\Github\n8n-tp\scripts
.\install-pm2-autostart.ps1

# Hoặc với custom parameters
.\install-pm2-autostart.ps1 -LogPath "D:\CustomLogs" -Force
```

#### 3.3 Installation Output
Kết quả mong đợi:
```
=== StrangematicHub PM2 Auto-Startup Installation Started ===
[INFO] Checking installation prerequisites...
[SUCCESS] Administrator privileges: True
[SUCCESS] PowerShell version >= 5.1: True
[SUCCESS] Task Scheduler available: True
[SUCCESS] Script files exist: True
[WARNING] Node.js installed: True
[WARNING] PM2 installed: True
[WARNING] n8n installed: True

[INFO] Installing PM2 Auto-Start task...
[SUCCESS] Auto-Start task installed successfully

[INFO] Installing PM2 Health Monitor task...
[SUCCESS] Health Monitor task installed successfully

[INFO] Testing installation...
[SUCCESS] Auto-Start task exists: True
[SUCCESS] Health Monitor task exists: True

=== Installation Completed Successfully ===
```

### Bước 4: Verification và Testing

#### 4.1 Verify Task Scheduler Tasks
```powershell
# Kiểm tra tasks đã được tạo
Get-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart"
Get-ScheduledTask -TaskName "StrangematicHub-PM2-HealthMonitor"

# Kiểm tra task details
Get-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart" | Get-ScheduledTaskInfo
```

#### 4.2 Manual Task Testing
```powershell
# Test Auto-Start task manually
Start-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart"

# Check task execution result
Get-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart" | Get-ScheduledTaskInfo

# Test Health Monitor task
Start-ScheduledTask -TaskName "StrangematicHub-PM2-HealthMonitor"
```

#### 4.3 Comprehensive System Test
```powershell
# Chạy comprehensive test suite
cd C:\Github\n8n-tp\scripts
.\test-pm2-autostart.ps1 -Detailed -ExportReport
```

### Bước 5: Configuration và Customization

#### 5.1 Custom Log Path
Nếu muốn thay đổi log directory:

```powershell
# Uninstall existing tasks
.\install-pm2-autostart.ps1 -Uninstall

# Reinstall with custom log path
.\install-pm2-autostart.ps1 -LogPath "D:\StrangematicHub\Logs"
```

#### 5.2 Custom Script Path
Nếu scripts nằm ở location khác:

```powershell
# Update XML template
$XmlPath = ".\StrangematicHub-AutoStart.xml"
$XmlContent = Get-Content $XmlPath -Raw
$XmlContent = $XmlContent -replace 'C:\\Github\\n8n-tp', 'D:\\YourCustomPath'
$XmlContent | Set-Content $XmlPath
```

#### 5.3 Environment Variables
Set environment variables cho n8n:

```powershell
# System-wide environment variables
[Environment]::SetEnvironmentVariable("N8N_HOST", "0.0.0.0", "Machine")
[Environment]::SetEnvironmentVariable("N8N_PORT", "5678", "Machine")
[Environment]::SetEnvironmentVariable("N8N_PROTOCOL", "http", "Machine")
[Environment]::SetEnvironmentVariable("WEBHOOK_URL", "http://strangematic.com", "Machine")
```

## Troubleshooting Common Issues

### Issue 1: Task Scheduler Access Denied

**Symptoms:**
```
ERROR: Access denied when creating scheduled task
```

**Solutions:**
1. **Run PowerShell as Administrator**
   ```powershell
   # Right-click PowerShell → "Run as Administrator"
   ```

2. **Check User Account Control (UAC)**
   ```powershell
   # Temporarily disable UAC hoặc add exception
   ```

3. **Verify Group Policy Settings**
   ```powershell
   # Check if Group Policy blocks task creation
   gpedit.msc → Computer Configuration → Windows Settings → Security Settings → Local Policies → User Rights Assignment
   ```

### Issue 2: PM2 Not Found

**Symptoms:**
```
PM2 executable not found
```

**Solutions:**
1. **Verify npm global installation**
   ```powershell
   npm list -g pm2
   npm install -g pm2 --force
   ```

2. **Check PATH environment variable**
   ```powershell
   $env:PATH -split ';' | Where-Object { $_ -like "*npm*" }
   
   # Add npm global path if missing
   $npmPath = npm config get prefix
   [Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$npmPath", "Machine")
   ```

3. **Manual PM2 path configuration**
   ```powershell
   # Edit StrangematicPM2Management.psm1
   # Update $script:PM2ExecutablePath manually
   ```

### Issue 3: n8n Startup Failures

**Symptoms:**
```
n8n application failed to start
Error 1033: Service did not respond
```

**Solutions:**
1. **Check n8n configuration**
   ```powershell
   # Test n8n manually
   n8n start --tunnel
   ```

2. **Database connectivity issues**
   ```powershell
   # Test PostgreSQL connection
   Test-NetConnection -ComputerName localhost -Port 5432
   
   # Check n8n database configuration
   $env:DB_TYPE = "postgresdb"
   $env:DB_POSTGRESDB_HOST = "localhost"
   $env:DB_POSTGRESDB_PORT = "5432"
   ```

3. **Port conflicts**
   ```powershell
   # Check if port 5678 is available
   netstat -an | findstr :5678
   
   # Use different port if needed
   $env:N8N_PORT = "5679"
   ```

### Issue 4: Health Monitor Not Working

**Symptoms:**
```
Health monitor task exists but not executing
```

**Solutions:**
1. **Check task trigger configuration**
   ```powershell
   Get-ScheduledTask -TaskName "StrangematicHub-PM2-HealthMonitor" | Select-Object -ExpandProperty Triggers
   ```

2. **Verify script execution policy**
   ```powershell
   # Test script execution manually
   PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File ".\pm2-health-monitor.ps1" -RunOnce
   ```

3. **Check log files**
   ```powershell
   # Review health monitor logs
   Get-Content "C:\ProgramData\StrangematicHub\Logs\pm2-health-monitor-*.log" -Tail 50
   ```

### Issue 5: Event Log Errors

**Symptoms:**
```
Event log source creation failed
```

**Solutions:**
1. **Manual event log source creation**
   ```powershell
   # Run as Administrator
   New-EventLog -LogName Application -Source "StrangematicHub"
   ```

2. **Registry permissions**
   ```powershell
   # Check registry permissions for HKLM\SYSTEM\CurrentControlSet\Services\EventLog\Application
   ```

## Advanced Configuration

### 1. Custom Retry Logic

Modify retry parameters trong `pm2-auto-startup.ps1`:

```powershell
# Custom parameters
$MaxRetries = 5                    # Increase retry attempts
$RetryDelaySeconds = 120          # Longer delay between retries
$PostgreSQLTimeoutSeconds = 180   # Longer PostgreSQL timeout
$NetworkTimeoutSeconds = 60       # Longer network timeout
```

### 2. Performance Tuning

#### 2.1 Task Scheduler Optimization
```xml
<!-- Trong StrangematicHub-AutoStart.xml -->
<Settings>
    <Priority>4</Priority>                    <!-- Higher priority -->
    <ExecutionTimeLimit>PT45M</ExecutionTimeLimit>  <!-- Longer timeout -->
    <RestartPolicy>
        <Interval>PT2M</Interval>            <!-- Faster restart -->
        <Count>5</Count>                     <!-- More restart attempts -->
    </RestartPolicy>
</Settings>
```

#### 2.2 Health Monitor Frequency
```powershell
# Modify health monitor interval
$CheckIntervalMinutes = 3          # More frequent checks
$AlertThreshold = 5               # Higher threshold before alerts
$AutoRecoveryMaxAttempts = 3      # More recovery attempts
```

### 3. Security Hardening

#### 3.1 Script Signing
```powershell
# Create self-signed certificate for script signing
$cert = New-SelfSignedCertificate -Subject "CN=StrangematicHub" -Type CodeSigning -CertStoreLocation Cert:\CurrentUser\My

# Sign scripts
Set-AuthenticodeSignature -FilePath ".\pm2-auto-startup.ps1" -Certificate $cert
Set-AuthenticodeSignature -FilePath ".\pm2-health-monitor.ps1" -Certificate $cert
```

#### 3.2 Restricted Execution Policy
```powershell
# Set restricted execution policy with signed script exception
Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope LocalMachine
```

### 4. Monitoring và Alerting

#### 4.1 Email Notifications
Thêm email notification vào health monitor:

```powershell
# Trong pm2-health-monitor.ps1
function Send-AlertEmail {
    param($Subject, $Body)
    
    $SmtpServer = "smtp.gmail.com"
    $SmtpPort = 587
    $Username = "alerts@strangematic.com"
    $Password = ConvertTo-SecureString "your-password" -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential($Username, $Password)
    
    Send-MailMessage -To "admin@strangematic.com" -From $Username -Subject $Subject -Body $Body -SmtpServer $SmtpServer -Port $SmtpPort -Credential $Credential -UseSsl
}
```

#### 4.2 Windows Event Log Integration
```powershell
# Enhanced event logging
function Write-CustomEventLog {
    param($EventId, $EntryType, $Message)
    
    Write-EventLog -LogName Application -Source "StrangematicHub" -EventId $EventId -EntryType $EntryType -Message $Message
}
```

## Verification Checklist

Sau khi hoàn thành installation, verify các items sau:

### ✅ Installation Verification

- [ ] **Task Scheduler Tasks Created**
  - [ ] StrangematicHub-PM2-AutoStart exists và enabled
  - [ ] StrangematicHub-PM2-HealthMonitor exists và enabled
  - [ ] Tasks run with SYSTEM privileges
  - [ ] Boot trigger configured với appropriate delay

- [ ] **Script Files Accessible**
  - [ ] All PowerShell scripts có correct permissions
  - [ ] Module imports successfully
  - [ ] No syntax errors trong scripts

- [ ] **Dependencies Available**
  - [ ] Node.js accessible từ SYSTEM account
  - [ ] PM2 accessible từ SYSTEM account  
  - [ ] n8n accessible từ SYSTEM account
  - [ ] All required paths trong environment variables

- [ ] **Logging Configuration**
  - [ ] Log directories created với appropriate permissions
  - [ ] Event log source "StrangematicHub" exists
  - [ ] Log rotation configured (nếu cần)

### ✅ Functional Verification

- [ ] **Manual Task Execution**
  - [ ] Auto-start task runs successfully manually
  - [ ] Health monitor task runs successfully manually
  - [ ] No errors trong task execution logs

- [ ] **PM2 Operations**
  - [ ] PM2 daemon starts successfully
  - [ ] n8n application starts under PM2
  - [ ] Health checks return positive results
  - [ ] Auto-recovery mechanisms work

- [ ] **System Integration**
  - [ ] Tasks survive system reboot
  - [ ] Services start before user login
  - [ ] No conflicts với other system services
  - [ ] Performance impact acceptable

## Rollback Procedures

Nếu cần rollback installation:

### 1. Automated Rollback
```powershell
# Sử dụng uninstall option
cd C:\Github\n8n-tp\scripts
.\install-pm2-autostart.ps1 -Uninstall
```

### 2. Manual Rollback
```powershell
# Remove scheduled tasks
Unregister-ScheduledTask -TaskName "StrangematicHub-PM2-AutoStart" -Confirm:$false
Unregister-ScheduledTask -TaskName "StrangematicHub-PM2-HealthMonitor" -Confirm:$false

# Remove event log source
Remove-EventLog -Source "StrangematicHub"

# Clean up directories (optional)
Remove-Item -Path "C:\ProgramData\StrangematicHub" -Recurse -Force
```

### 3. Registry Cleanup
```powershell
# Remove any registry entries (nếu có)
# Thường không cần thiết cho solution này
```

## Support và Maintenance

### Log Files Location
- **Installation logs**: `C:\ProgramData\StrangematicHub\Logs\pm2-autostart-install-*.log`
- **Auto-startup logs**: `C:\ProgramData\StrangematicHub\Logs\pm2-auto-startup-*.log`
- **Health monitor logs**: `C:\ProgramData\StrangematicHub\Logs\pm2-health-monitor-*.log`
- **Test reports**: `C:\ProgramData\StrangematicHub\Reports\PM2-AutoStart-Test-Report-*.html`

### Regular Maintenance Tasks
1. **Weekly**: Review log files cho errors hoặc warnings
2. **Monthly**: Run comprehensive test suite
3. **Quarterly**: Update dependencies (Node.js, PM2, n8n)
4. **Annually**: Review và update security configurations

### Getting Help
- **Documentation**: Xem `PM2-AutoStart-User-Guide.md` cho daily operations
- **Testing**: Sử dụng `test-pm2-autostart.ps1` cho diagnostics
- **Demo**: Chạy `demo-pm2-management.ps1` để explore features
- **Quick Reference**: Xem `QUICK-START-PM2-AUTOSTART.md` cho common tasks

---

**Lưu ý**: Tài liệu này được cập nhật thường xuyên. Kiểm tra version mới nhất trước khi thực hiện installation.