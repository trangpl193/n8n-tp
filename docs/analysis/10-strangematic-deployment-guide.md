# strangematic.com Deployment Guide - Live Implementation

**Ngày bắt đầu:** 28/07/2025
**Domain:** strangematic.com ✅ **ACQUIRED**
**Status:** Phase 1 Implementation In Progress

---

## 🚀 PHASE 1: FOUNDATION SETUP - Week 1-2

### **📋 Current Progress Checklist**

```yaml
✅ Domain Registration: strangematic.com acquired ($10/year)
🔄 DNS Configuration: In Progress
⏳ Cloudflare Tunnel: Awaiting DNS completion
⏳ Windows Setup: Awaiting tunnel configuration
⏳ PostgreSQL: Awaiting system preparation
⏳ n8n Deployment: Awaiting database setup
```

---

## 🌐 STEP 1: DNS CONFIGURATION - strangematic.com

### **A. Cloudflare Dashboard Setup**

**Login to Cloudflare Dashboard:**
1. Navigate to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Select **strangematic.com** domain
3. Go to **DNS > Records** section

### **B. DNS Records Configuration**

**Primary Domain Records:**
```dns
# Main A Record (pointing to Cloudflare)
Type: A
Name: strangematic.com (or @)
Content: 100.100.100.100  # Cloudflare proxy IP
Proxy: ✅ Proxied (Orange cloud active)
TTL: Auto

# CNAME Records for Subdomains
Type: CNAME
Name: app
Content: strangematic.com
Proxy: ✅ Proxied
TTL: Auto

Type: CNAME
Name: api
Content: strangematic.com
Proxy: ✅ Proxied
TTL: Auto

Type: CNAME
Name: status
Content: strangematic.com
Proxy: ✅ Proxied
TTL: Auto

Type: CNAME
Name: docs
Content: strangematic.com
Proxy: ✅ Proxied
TTL: Auto

Type: CNAME
Name: www
Content: strangematic.com
Proxy: ✅ Proxied
TTL: Auto
```

**Security & Email Records:**
```dns
# SPF Record (Email Security)
Type: TXT
Name: strangematic.com (or @)
Content: "v=spf1 -all"
TTL: Auto

# DMARC Record (Email Security)
Type: TXT
Name: _dmarc
Content: "v=DMARC1; p=reject; rua=mailto:dmarc-reports@strangematic.com"
TTL: Auto

# CAA Record (Certificate Authority Authorization)
Type: CAA
Name: strangematic.com (or @)
Content: 0 issue "letsencrypt.org"
TTL: Auto
```

### **C. SSL/TLS Configuration**

**Navigate to SSL/TLS > Overview:**
```yaml
Encryption Mode: Full (Strict)
- Ensures end-to-end encryption
- Validates origin server certificate
- Required for production security

Always Use HTTPS: ✅ Enabled
- Redirects all HTTP to HTTPS
- Essential for webhook security

HSTS (HTTP Strict Transport Security): ✅ Enabled
- Max Age: 31536000 (1 year)
- Include Subdomains: ✅ Yes
- Preload: ✅ Yes
```

### **D. Security Configuration**

**Navigate to Security > WAF:**
```yaml
Web Application Firewall: ✅ Enabled
Security Level: Medium
Bot Fight Mode: ✅ Enabled

Custom Rules:
- Block non-webhook traffic to /webhook/* paths
- Rate limit: 100 requests/minute per IP
- Challenge suspicious automation traffic
```

### **E. Performance Optimization**

**Navigate to Speed > Optimization:**
```yaml
Auto Minify:
- JavaScript: ✅ Enabled
- CSS: ✅ Enabled
- HTML: ✅ Enabled

Brotli Compression: ✅ Enabled
Early Hints: ✅ Enabled
Rocket Loader: ❌ Disabled (can break webhooks)
```

### **F. DNS Propagation Verification**

**Check DNS Propagation:**
```bash
# Windows Command Prompt
nslookup app.strangematic.com
nslookup api.strangematic.com
nslookup status.strangematic.com

# Expected Results:
# app.strangematic.com -> Cloudflare IP
# api.strangematic.com -> Cloudflare IP
# status.strangematic.com -> Cloudflare IP
```

**Online Verification Tools:**
- [whatsmydns.net](https://whatsmydns.net) - Global DNS propagation
- [dnschecker.org](https://dnschecker.org) - Multi-location testing
- [Cloudflare Analytics](https://dash.cloudflare.com) - Real-time traffic

---

## 🚇 STEP 2: CLOUDFLARE TUNNEL SETUP

### **A. Download Cloudflared**

**Windows Installation:**
1. Download from [Cloudflare GitHub](https://github.com/cloudflare/cloudflared/releases)
2. Choose: `cloudflared-windows-amd64.exe`
3. Create directory: `C:\cloudflared\`
4. Rename executable to: `cloudflared.exe`
5. Add to Windows PATH environment variable

### **B. Tunnel Authentication**

**Command Prompt (Run as Administrator):**
```powershell
# Change to cloudflared directory
cd C:\cloudflared

# Login to Cloudflare (opens browser)
cloudflared tunnel login

# This creates cert.pem file in C:\Users\%USERNAME%\.cloudflared\
# Copy cert.pem to C:\cloudflared\ for easier management
```

### **C. Create Tunnel**

```powershell
# Create tunnel named 'automation-hub-prod'
cloudflared tunnel create automation-hub-prod

# This creates:
# - Tunnel UUID (save this)
# - JSON credential file
# Copy credential file to C:\cloudflared\
```

### **D. Configure Tunnel Routes**

**Create file: `C:\cloudflared\config.yml`**
```yaml
tunnel: automation-hub-prod
credentials-file: C:\cloudflared\cert.pem

ingress:
  # Main n8n interface
  - hostname: app.strangematic.com
    service: http://localhost:5678

  # API webhooks với header forwarding
  - hostname: api.strangematic.com
    service: http://localhost:5678
    originRequest:
      httpHostHeader: api.strangematic.com

  # Status monitoring
  - hostname: status.strangematic.com
    service: http://localhost:8080

  # Catch-all rule (required)
  - service: http_status:404
```

### **E. DNS Route Assignment**

```powershell
# Assign routes to tunnel
cloudflared tunnel route dns automation-hub-prod app.strangematic.com
cloudflared tunnel route dns automation-hub-prod api.strangematic.com
cloudflared tunnel route dns automation-hub-prod status.strangematic.com
```

### **F. Test Tunnel Connection**

```powershell
# Test tunnel (temporary)
cloudflared tunnel run automation-hub-prod

# Expected output:
# - Connection established
# - No errors in logs
# - Tunnel shows as "Healthy" in Cloudflare dashboard
```

---

## 🖥️ STEP 3: WINDOWS HEADLESS CONFIGURATION

### **A. Automatic Login Setup**

**Registry Configuration (Run as Administrator):**
```powershell
# Enable automatic login
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d "YourUsername" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d "YourPassword" /f
```

### **B. Power Management**

**Power Options Configuration:**
```yaml
Power Plan: High Performance
Sleep: Never
Hard disk turn off: Never
USB selective suspend: Disabled
Network adapter power saving: Disabled

Fast Startup: ✅ Enabled (for faster reboots)
Hibernate: ❌ Disabled (saves disk space)
```

**Command Line Configuration:**
```powershell
# Set high performance power plan
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Disable sleep
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
```

### **C. Windows Service Optimization**

**Disable Unnecessary Services:**
```yaml
Services to Disable:
- Windows Search (if not needed)
- Print Spooler (if no printer)
- Fax service
- Windows Media Player Network Sharing

Services to Keep Enabled:
- Windows Update
- Windows Defender
- Network services
- Remote Desktop services
```

### **D. Firewall Configuration**

**Windows Defender Firewall:**
```yaml
Inbound Rules (Allow):
- Remote Desktop (Port 3389)
- n8n Application (Port 5678)
- Status Monitor (Port 8080)

Outbound Rules:
- UltraViewer: Allow all HTTPS connections
- Monitor for webhook traffic

---

## 👁️ STEP 4: ULTRAVIEWER SETUP

### **A. UltraViewer Installation**

**Download & Setup:**
1. Download từ [UltraViewer Official](https://www.ultraviewer.net/en/download)
2. No installation required: Portable executable (~6MB)
3. Save to: C:\automation\remote-access\UltraViewer.exe
4. Run và configure unattended access

### **B. Initial Configuration**

**UltraViewer Basic Settings:**
```yaml
Connection Settings:
- Unique ID: [Generated automatically - note down]
- Access Password: [Set secure password]
- Connection Type: P2P cloud-routed

Security Settings:
- Auto Accept: ❌ Disabled (security)
- Unattended Access: ✅ Enabled
- File Transfer: ✅ Enabled
- Chat Window: ✅ Enabled (F1 hotkey)

Performance Settings:
- Display Quality: Balanced (not highest)
- Remove Wallpaper: ✅ Yes (performance)
- Block Remote Input: ❌ No (needed for control)
```

### **C. Windows Auto-Start Setup**

```powershell
# Create scheduled task cho auto-start (Run as Administrator)
$TaskName = "UltraViewerAutoStart"
$TaskPath = "C:\automation\remote-access\UltraViewer.exe"

# Create scheduled task
$Action = New-ScheduledTaskAction -Execute $TaskPath
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal

# Verify task created
Get-ScheduledTask -TaskName $TaskName
```

### **D. Test Remote Access**

**Connection Test:**
1. Từ another computer hoặc mobile device
2. Download UltraViewer viewer
3. Enter ID: [Your computer's unique ID]
4. Enter password: [Your set password]
5. Verify desktop display và control

---

## 📊 STEP 5: MONITORING SETUP

### **A. Basic Health Monitoring**

**Create: `C:\automation\monitoring\health-check.ps1`**
```powershell
# Updated health check script với UltraViewer monitoring
$services = @("cloudflared")
$ports = @(5678, 8080)
$processes = @("UltraViewer")

# Check UltraViewer process
$ultraviewerProcess = Get-Process -Name "UltraViewer" -ErrorAction SilentlyContinue
if ($ultraviewerProcess) {
    Write-Output "UltraViewer: RUNNING (PID: $($ultraviewerProcess.Id))"
} else {
    Write-Output "UltraViewer: NOT RUNNING - RESTARTING"
    Start-Process "C:\automation\remote-access\UltraViewer.exe" -WindowStyle Hidden
}

# Check cloudflared service
foreach ($service in $services) {
    $status = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($status.Status -eq "Running") {
        Write-Output "$service: OK"
    } else {
        Write-Output "$service: FAILED"
    }
}

# Check required ports
foreach ($port in $ports) {
    $connection = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
    if ($connection.TcpTestSucceeded) {
        Write-Output "Port $port: OK"
    } else {
        Write-Output "Port $port: FAILED"
    }
}

# Check internet connectivity
$internetTest = Test-NetConnection -ComputerName "8.8.8.8" -Port 443 -WarningAction SilentlyContinue
if ($internetTest.TcpTestSucceeded) {
    Write-Output "Internet Connectivity: OK"
} else {
    Write-Output "Internet Connectivity: FAILED"
}
```

### **B. Automated Health Checks**

**Task Scheduler Setup:**
```yaml
Task Name: StrangematicHealthCheck
Trigger: Every 15 minutes
Action: PowerShell script execution
User: System account
Priority: Normal
```

---

## ✅ PHASE 1 COMPLETION VERIFICATION

### **Verification Checklist:**

```yaml
✅ DNS Records:
   - All subdomains resolve correctly
   - SSL certificates active (A+ grade)
   - Global propagation confirmed

✅ Cloudflare Tunnel:
   - Tunnel shows "Healthy" in dashboard
   - All hostname routes configured
   - Traffic routing working

✅ Windows Headless:
   - Automatic login configured
   - Power management optimized
   - UltraViewer accessible remotely

✅ Remote Access:
   - UltraViewer connection successful
   - Desktop control responsive
   - File transfer functional
   - Auto-start với Windows boot verified

✅ Application Platform:
   - n8n installed và running
   - Database connection established
   - All services auto-start
   - Basic monitoring active
```

### **Next Phase Preparation:**

**Ready for Phase 2 when:**
- All infrastructure stable for 24+ hours
- Remote access tested và confirmed
- Cloudflare tunnel fully operational
- Windows running reliably headless

**Estimated Timeline:** 3-5 days for complete Phase 1 setup

---

## 🚨 TROUBLESHOOTING COMMON ISSUES

### **DNS Issues:**
```yaml
Problem: Subdomains not resolving
Solution:
  - Check DNS propagation time (up to 48 hours)
  - Verify CNAME record configuration
  - Clear local DNS cache: ipconfig /flushdns

Problem: SSL certificate errors
Solution:
  - Ensure "Full (Strict)" SSL mode in Cloudflare
  - Verify proxy status (orange cloud) enabled
  - Wait for certificate provisioning
```

### **Tunnel Issues:**
```yaml
Problem: Tunnel disconnects frequently
Solution:
  - Check internet connection stability
  - Verify firewall not blocking cloudflared
  - Review tunnel logs in Cloudflare dashboard

Problem: 502 Bad Gateway errors
Solution:
  - Ensure target service (n8n) is running
  - Check localhost port accessibility
  - Verify ingress rules configuration
```

### **Remote Access Issues:**
```yaml
Problem: VNC connection refused
Solution:
  - Verify UltraVNC service running
  - Check Windows Firewall rules
  - Confirm port 5900 not blocked

Problem: Poor VNC performance
Solution:
  - Disable desktop effects
  - Reduce color depth
  - Enable compression in VNC settings
```

---

*Live deployment guide - Updated in real-time during implementation*
*Next Update: After Phase 1 completion*
