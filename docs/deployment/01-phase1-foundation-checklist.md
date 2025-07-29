# Phase 1: Foundation Setup Checklist

**Timeline:** Tuần 1-2 (14 ngày)  
**Target:** Windows 11 Pro + strangematic.com + Cloudflare Tunnel  
**Hardware:** Dell OptiPlex 3060 (i5-8500T, 16GB RAM, 636GB storage)

---

## 🌐 WEEK 1: DOMAIN & INFRASTRUCTURE

### **Day 1: Domain Configuration (30-60 phút)**

**🌍 Cloudflare Dashboard Setup:**
- [ ] Login to https://dash.cloudflare.com
- [ ] Verify strangematic.com domain access ✅ **ACQUIRED**
- [ ] Navigate to DNS > Records section

**📋 DNS Records Creation:**
```dns
Required Records:
□ A Record: @ → 100.100.100.100 (Proxied ✅)
□ CNAME: app → strangematic.com (Proxied ✅)  
□ CNAME: api → strangematic.com (Proxied ✅)
□ CNAME: status → strangematic.com (Proxied ✅)
□ CNAME: docs → strangematic.com (Proxied ✅)
□ CNAME: www → strangematic.com (Proxied ✅)
```

**🔒 Security Configuration:**
- [ ] SSL/TLS → Full (Strict) mode
- [ ] Always Use HTTPS: ✅ Enabled
- [ ] HSTS: ✅ Enabled (1 year, include subdomains)
- [ ] Security Level: Medium
- [ ] Bot Fight Mode: ✅ Enabled  
- [ ] WAF: ✅ Enabled với OWASP rules

**✅ Day 1 Verification:**
```bash
# Windows Command Prompt Testing
nslookup app.strangematic.com
nslookup api.strangematic.com
nslookup status.strangematic.com

# Expected: All resolve to Cloudflare IPs
# SSL Test: https://www.ssllabs.com/ssltest/
# Target: A+ grade rating
```

---

### **Day 2: Cloudflare Tunnel Setup (45-90 phút)**

**🚇 Tunnel Installation:**
- [ ] Download cloudflared-windows-amd64.exe từ [GitHub](https://github.com/cloudflare/cloudflared/releases)
- [ ] Create directory: `C:\cloudflared\`
- [ ] Rename executable to: `cloudflared.exe`
- [ ] Add `C:\cloudflared\` to Windows PATH environment

**🔑 Tunnel Authentication:**
```powershell
# PowerShell as Administrator
cd C:\cloudflared

# Browser-based authentication
cloudflared tunnel login

# Create production tunnel
cloudflared tunnel create automation-hub-prod

# 📝 IMPORTANT: Save tunnel UUID displayed!
```

**⚙️ Tunnel Configuration:**
```yaml
# Create C:\cloudflared\config.yml
tunnel: automation-hub-prod
credentials-file: C:\cloudflared\cert.pem

ingress:
  - hostname: app.strangematic.com
    service: http://localhost:5678
  - hostname: api.strangematic.com  
    service: http://localhost:5678
    originRequest:
      httpHostHeader: api.strangematic.com
  - hostname: status.strangematic.com
    service: http://localhost:8080
  - service: http_status:404
```

**🌐 DNS Route Assignment:**
```powershell
cloudflared tunnel route dns automation-hub-prod app.strangematic.com
cloudflared tunnel route dns automation-hub-prod api.strangematic.com
cloudflared tunnel route dns automation-hub-prod status.strangematic.com
```

**✅ Day 2 Verification:**
```powershell
# Test tunnel connection
cloudflared tunnel run automation-hub-prod

# Should show: "Healthy" status in Cloudflare dashboard
# Check: Tunnel tab in Cloudflare dashboard
```

---

### **Day 3-4: Windows Headless Configuration (2-3 giờ)**

**🖥️ Automatic Login Setup:**
```powershell
# Run as Administrator
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d "YOUR_USERNAME" /f  
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d "YOUR_PASSWORD" /f
```

**⚡ Power Management Optimization:**
```powershell
# High performance power plan
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Disable sleep và hibernate
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0

# Disable USB selective suspend
powercfg /change usb-selective-suspend-setting 0
```

**🔥 Windows Firewall Configuration:**
```yaml
Inbound Rules (Allow):
□ VNC Server: Port 5900 (UltraVNC)
□ Remote Desktop: Port 3389 (RDP backup)  
□ n8n Application: Port 5678 (main app)
□ Status Monitor: Port 8080 (health checks)
□ HTTP: Port 80 (tunnel routing)
□ HTTPS: Port 443 (tunnel routing)

Outbound Rules (Review):
□ Cloudflare Tunnel: Allow all HTTPS
□ API Calls: Allow HTTPS to YEScale, OpenAI, etc.
□ Windows Updates: Allow as needed
```

**✅ Day 3-4 Verification:**
- [ ] System boots automatically without login prompt
- [ ] Power settings prevent sleep/hibernate  
- [ ] Firewall rules configured correctly
- [ ] System stable cho 24/7 operation

---

### **Day 5-6: Remote Access Setup (1-2 giờ)**

**👁️ UltraVNC Server Installation:**
- [ ] Download từ https://www.uvnc.com/downloads/ultravnc.html
- [ ] Install: UltraVNC Server + Viewer
- [ ] Configuration:
  - VNC Password: [Secure password - document securely]
  - MS Logon Authentication: ✅ Enabled
  - Install as Service: ✅ Yes
  - Auto-start with Windows: ✅ Yes

**🌐 UltraVNC Network Settings:**
```yaml
Configuration:
- HTTP Port: 5800
- VNC Port: 5900 (Main)
- Auto Accept: ❌ Disabled (security)
- View Only: ❌ Disabled (full control needed)
- Remove Wallpaper: ✅ Enabled (performance)
- Disable Effects: ✅ Enabled (performance)
```

**🔄 Remote Desktop Protocol (RDP) Backup:**
```powershell
# Enable RDP as backup remote access
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0

# Enable RDP through firewall
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

**✅ Day 5-6 Verification:**
```yaml
Remote Access Tests:
□ VNC connection từ local network successful
□ VNC performance acceptable (smooth cursor/typing)
□ RDP connection working as backup
□ Both methods auto-start với Windows boot
□ Security: Connections require authentication
```

---

### **Day 7: Week 1 Integration Testing (2-3 giờ)**

**🔄 End-to-End Testing:**
```yaml
Network Stack Verification:
□ DNS propagation complete globally (24-48 hours)
□ All subdomains resolve correctly
□ SSL certificates active (A+ grade)
□ Cloudflare Tunnel: "Healthy" status
□ Remote access: VNC + RDP both working
□ Windows: Headless operation stable
```

**📊 Performance Baseline:**
```powershell
# System resource monitoring script
# Create C:\automation\monitoring\baseline-check.ps1

# Test basic system performance
$cpu = Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average
$memory = Get-WmiObject Win32_OperatingSystem
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"

Write-Host "CPU Average: $($cpu.Average)%"
Write-Host "Memory Available: $([math]::Round($memory.FreePhysicalMemory/1MB,2)) GB"
Write-Host "Disk Free C: $([math]::Round($disk[0].FreeSpace/1GB,2)) GB"

# Network connectivity test
Test-NetConnection app.strangematic.com -Port 443
Test-NetConnection api.strangematic.com -Port 443
```

**✅ Week 1 Completion Criteria:**
```yaml
Infrastructure Status:
✅ Domain: All subdomains resolve globally  
✅ Security: A+ SSL rating achieved
✅ Tunnel: Healthy status 24/7 operation
✅ Remote: VNC + RDP access reliable
✅ System: Headless operation verified
✅ Performance: Baseline metrics documented
```

---

## 🚀 WEEK 2: APPLICATION STACK

### **Day 8-9: Software Installation (3-4 giờ)**

**📦 Node.js Installation:**
- [ ] Download LTS version từ https://nodejs.org/en/download
- [ ] Install với default settings  
- [ ] Verify installation: `node --version && npm --version`
- [ ] Configure npm global directory (optional)

**🗄️ PostgreSQL Installation:**
```yaml
Installation Steps:
□ Download PostgreSQL 14+ từ official website
□ Install với following settings:
  - Username: postgres
  - Password: [Secure password - document]
  - Port: 5432 (default)
  - Locale: Default
  - Data Directory: C:\PostgreSQL\14\data

□ Verify installation: PostgreSQL service running
□ Test connection: pgAdmin or command line
```

**🔧 PM2 Windows Service Setup:**
```powershell
# Global PM2 installation
npm install -g pm2
npm install -g pm2-windows-service

# Setup PM2 as Windows Service
pm2-service-install

# Verify PM2 service
pm2 list
```

**✅ Day 8-9 Verification:**
- [ ] Node.js: Version 18+ LTS installed
- [ ] PostgreSQL: Service running, connections accepted
- [ ] PM2: Windows service active, auto-start enabled

---

### **Day 10-11: n8n Source Code Setup (4-6 giờ)**

**📂 Repository Clone:**
```powershell
# Create automation directory
mkdir C:\automation
cd C:\automation

# Clone n8n source code
git clone https://github.com/n8n-io/n8n.git
cd n8n

# Install dependencies (this takes time!)
npm install

# Build project
npm run build
```

**🗄️ Database Configuration:**
```sql
-- PostgreSQL database setup
-- Connect to PostgreSQL as postgres user

CREATE DATABASE strangematic_n8n;
CREATE USER strangematic_user WITH PASSWORD 'secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE strangematic_n8n TO strangematic_user;

-- Test connection
\c strangematic_n8n strangematic_user
```

**⚙️ Environment Configuration:**
```yaml
# Create C:\automation\n8n\.env.production
DOMAIN_NAME=strangematic.com
N8N_EDITOR_BASE_URL=https://app.strangematic.com
WEBHOOK_URL=https://api.strangematic.com
N8N_HOST=app.strangematic.com
N8N_PROTOCOL=https
N8N_PORT=5678

# Database
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=localhost
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=strangematic_n8n
DB_POSTGRESDB_USER=strangematic_user
DB_POSTGRESDB_PASSWORD=secure_password_here

# YEScale API Configuration
YESCALE_BASE_URL=https://yescale.bogia.app
YESCALE_API_KEY=your_yescale_access_key
YESCALE_ENABLE_FALLBACK=true

# Security
N8N_SECURE_COOKIE=true
N8N_JWT_SECRET=your_jwt_secret_here
N8N_ENCRYPTION_KEY=your_encryption_key_here
```

**✅ Day 10-11 Verification:**
```powershell
# Test n8n build
cd C:\automation\n8n
npm run build

# Should complete without errors
# Database connection test
npm run start

# Should start successfully và connect to database
```

---

### **Day 12-13: Production Service Setup (2-3 giờ)**

**🔄 PM2 Ecosystem Configuration:**
```javascript
// Create C:\automation\n8n\ecosystem.config.js
module.exports = {
  apps: [{
    name: 'strangematic-hub',
    script: './packages/cli/bin/n8n',
    cwd: 'C:/automation/n8n',
    env: {
      NODE_ENV: 'production',
      N8N_EDITOR_BASE_URL: 'https://app.strangematic.com',
      WEBHOOK_URL: 'https://api.strangematic.com'
    },
    log_file: 'C:/automation/logs/strangematic.log',
    error_file: 'C:/automation/logs/strangematic-error.log',
    out_file: 'C:/automation/logs/strangematic-out.log',
    max_memory_restart: '2G',
    watch: false,
    autorestart: true,
    restart_delay: 5000
  }]
};
```

**🚀 Service Deployment:**
```powershell
# Create logs directory
mkdir C:\automation\logs

# Start n8n với PM2
cd C:\automation\n8n
pm2 start ecosystem.config.js

# Enable startup on Windows boot
pm2 startup
pm2 save

# Verify service status
pm2 status
pm2 logs strangematic-hub
```

**🚇 Cloudflared Windows Service:**
```powershell
# Install cloudflared as Windows service
cloudflared service install

# Start tunnel service
net start cloudflared

# Verify tunnel service status
sc query cloudflared
```

**✅ Day 12-13 Verification:**
```yaml
Service Status:
□ PM2: strangematic-hub running stable
□ Cloudflared: Windows service active
□ PostgreSQL: Database service healthy
□ n8n: Accessible at localhost:5678
□ Auto-start: All services boot với Windows
```

---

### **Day 14: Phase 1 Final Testing (2-4 giờ)**

**🌐 End-to-End Domain Testing:**
```yaml
External Access Tests:
□ https://app.strangematic.com → n8n interface loads
□ SSL certificate: A+ grade rating maintained
□ Response time: <3 seconds từ global locations
□ Tunnel health: "Healthy" in Cloudflare dashboard
□ DNS resolution: All subdomains working globally
```

**🔄 System Stability Testing:**
```powershell
# 4-hour stability test
# Restart Windows và monitor:

# 1. Services auto-start
Get-Service | Where-String {$_.Name -like "*cloudflared*" -or $_.Name -like "*postgresql*"}
pm2 status

# 2. Network connectivity
Test-NetConnection app.strangematic.com -Port 443
Test-NetConnection api.strangematic.com -Port 443

# 3. n8n application health
curl https://app.strangematic.com
```

**📊 Performance Benchmarking:**
```yaml
Baseline Metrics:
□ System boot time: <2 minutes to full operation
□ n8n startup time: <30 seconds
□ Memory usage: <4GB (25% of 16GB)
□ CPU idle usage: <10%
□ Disk usage: <100GB used of 636GB total
□ Network latency: <200ms global response
```

**✅ Phase 1 Completion Criteria:**
```yaml
Infrastructure Ready:
✅ Domain: strangematic.com fully operational
✅ Security: Enterprise-grade Cloudflare protection
✅ Access: Remote management 24/7 capable
✅ Platform: n8n source code deployed successfully
✅ Services: All auto-start, production-ready
✅ Monitoring: Basic health checks functional

Success Rate Target: >98% uptime trong testing period
```

---

## 📋 TROUBLESHOOTING COMMON ISSUES

### **🚨 DNS Issues:**
```yaml
Problem: Subdomains not resolving
Solution:
  1. Wait 24-48 hours cho global propagation
  2. Check Cloudflare DNS records configuration
  3. Verify proxy status (orange cloud) enabled
  4. Test với different DNS servers (8.8.8.8, 1.1.1.1)
```

### **🚨 Tunnel Connection Issues:**
```yaml
Problem: Tunnel shows "Unhealthy" status
Solution:
  1. Check internet connectivity stability
  2. Verify cloudflared Windows service running
  3. Review tunnel logs: C:\cloudflared\
  4. Restart tunnel service: net restart cloudflared
```

### **🚨 n8n Database Connection:**
```yaml
Problem: n8n cannot connect to PostgreSQL
Solution:
  1. Verify PostgreSQL service running
  2. Check database credentials in .env.production
  3. Test connection manually với psql
  4. Review PostgreSQL logs for authentication errors
```

### **🚨 Remote Access Problems:**
```yaml
Problem: VNC connection refused
Solution:
  1. Check UltraVNC service status
  2. Verify Windows firewall rules
  3. Test local connection first (localhost:5900)
  4. Review VNC server configuration
```

---

## 🎯 NEXT PHASE PREPARATION

**Phase 2 Prerequisites:**
- ✅ Phase 1 infrastructure stable >48 hours
- ✅ YEScale API account setup completed
- ✅ Bot tokens obtained (Telegram, Discord)
- ✅ Figma API access configured

**Performance Optimization:**
- Resource monitoring scripts implemented
- Automated backup strategy configured  
- Security audit và penetration testing scheduled
- Documentation updates với actual production values

---

*Phase 1 Checklist designed cho Windows headless automation hub với enterprise-grade reliability và security standards*

**Estimated Completion:** 14 days  
**Success Criteria:** >98% uptime, <3s response times, full remote accessibility