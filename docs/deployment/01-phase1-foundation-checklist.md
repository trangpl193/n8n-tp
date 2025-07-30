# Phase 1: Foundation Setup Checklist

**Timeline:** Tuần 1-2 (15 ngày bao gồm Day 0)
**Target:** Windows 11 Pro + strangematic.com + Cloudflare Tunnel
**Hardware:** Dell OptiPlex 3060 (i5-8500T, 16GB RAM, 636GB storage)

---

## 🌐 WEEK 1: WINDOWS INSTALLATION & INFRASTRUCTURE

### **Day 0: Windows 11 Pro Installation & Setup (2-4 giờ)**

**💻 Windows 11 Pro ISO Download:**
```yaml
Official Microsoft Downloads:
□ Windows 11 Pro (64-bit): https://www.microsoft.com/en-us/software-download/windows11
□ Media Creation Tool: https://go.microsoft.com/fwlink/?linkid=2156292
□ Alternative: Windows 11 22H2 ISO (Latest): https://www.microsoft.com/software-download/windows11

Dell OptiPlex 3060 Specific:
□ Dell Support Drivers: https://www.dell.com/support/home/en-us/product-support/product/optiplex-3060-desktop
□ Intel UHD Graphics 630 Driver: https://www.intel.com/content/www/us/en/support/products/graphics.html
□ Intel Wireless-AC 9560 Driver: Included trong Windows 11
```

**🔧 BIOS/UEFI Configuration:**
```yaml
Dell OptiPlex 3060 BIOS Settings:
□ Boot Mode: UEFI (not Legacy)
□ Secure Boot: Enabled
□ Fast Boot: Disabled (for troubleshooting)
□ Network Boot: Disabled (security)
□ USB Boot: Enabled (for installation)
□ Intel VT (Virtualization): Enabled
□ TPM 2.0: Enabled (required cho Windows 11)

Boot Priority:
□ 1st: USB Drive (cho installation)
□ 2nd: Internal SSD (C: drive)
□ 3rd: Network Boot (disabled)
```

**💾 Installation Media Preparation:**
```yaml
USB Installation Drive (8GB+):
□ Download Windows 11 Pro ISO file
□ Create bootable USB với Media Creation Tool
□ OR use Rufus: https://rufus.ie/en/ (alternative tool)
□ Verify USB boot functionality

Installation Requirements:
□ Product Key: Windows 11 Pro license
□ Internet connection: For activation
□ Backup: Any existing data (if needed)
□ Time allocation: 2-4 hours total
```

**🚀 Windows 11 Pro Installation Steps:**
```yaml
Fresh Installation Process:
□ Boot from USB installation media
□ Language: English (hoặc Vietnamese theo preference)
□ Edition: Windows 11 Pro (NOT Home)
□ License: Enter product key (or skip cho now)
□ Installation Type: Custom (Advanced) - Clean install
□ Drive Configuration:
  - Delete all partitions (clean slate)
  - Create new partition on full drive
  - Format: NTFS
□ Complete installation: 30-60 minutes

Initial Setup (OOBE):
□ Region: Vietnam (or your region)
□ Keyboard: Vietnamese (or English US)
□ Network: Connect to Wi-Fi/Ethernet
□ Account Type: Local Account (NOT Microsoft Account)
□ Username: Administrator (or your preference)
□ Password: Strong password cho remote access
□ Privacy Settings: Disable all telemetry options
□ Microsoft Services: Decline all optional services
```

**⚙️ Essential Windows Configuration:**
```yaml
System Configuration:
□ Windows Update: Install all critical updates
□ Windows Defender: Configure real-time protection
□ User Account Control (UAC): Set to default level
□ Remote Desktop: Enable (Control Panel > System)
□ File Explorer: Show hidden files và extensions
□ Power Options: High Performance plan
□ Network Profile: Set to Private (cho local network)

Critical Settings:
□ Computer Name: WINDOWS-PC (or your preference)
□ Workgroup: WORKGROUP (default)
□ Time Zone: Asia/Ho_Chi_Minh (or your timezone)
□ Date/Time: Automatic synchronization
□ Language Pack: Vietnamese support (if needed)
□ Regional Format: Vietnamese (or your preference)
```

**📦 AI-to-AI Dependencies Installation Strategy:**

## **🎯 PRIORITY 1: SYSTEM DEPENDENCIES (AI Agent Install Order)**

```yaml
Core Runtime Environment:
□ Node.js LTS 18.18.2: https://nodejs.org/en/download/
  - Installation: Global system với PATH environment
  - Verification: node --version && npm --version
  - Location: C:\Program Files\nodejs\
  - AI Command: winget install OpenJS.NodeJS.LTS

□ Git for Windows 2.42.0+: https://git-scm.com/download/win
  - Installation: System-wide với credential manager
  - Configuration: git config --global core.autocrlf true
  - Location: C:\Program Files\Git\
  - AI Command: winget install Git.Git

Database System:
✅ PostgreSQL 17.5: https://www.postgresql.org/download/windows/
  - Installation: Windows service với auto-start ✅ COMPLETED
  - Service: postgresql-x64-17 RUNNING ✅
  - Configuration: Port 5432, locale English_United States ✅
  - Location: C:\Program Files\PostgreSQL\17\ ✅
  - Status: Manual installation completed successfully
  - Security: Create dedicated user 'strangematic_user' ⏳ PENDING PASSWORD SETUP

  🔧 PostgreSQL Password Setup (Required):
  - Installation Note: Installer không có password field ✅ CONFIRMED
  - Default Status: postgres user requires password authentication ✅ VERIFIED
  - pgAdmin 4 Tool: C:\Program Files\PostgreSQL\17\pgAdmin 4\runtime\pgAdmin4.exe ✅ AVAILABLE
  - Recommended Method: pgAdmin GUI approach ✅ DOCUMENTED
  - Target Password: strangematic_postgres_2024 ⏳ PENDING USER ACTION

  📋 pgAdmin 4 Quick Guide:
  - Tool Type: Web-based PostgreSQL management interface
  - Access: Start Menu → pgAdmin 4 → Opens in browser
  - Password Setup: PostgreSQL 17 → Login/Group Roles → postgres → Properties → Definition
  - Alternative: Manual script approach available (postgres-password-reset.ps1)

Process Management:
□ PM2 5.3.0 Global: npm install -g pm2 pm2-windows-service
  - Installation: Global npm package với Windows service
  - Configuration: pm2-service-install command
  - Service Name: PM2
  - AI Command: Automated post Node.js installation
```

## **🎯 PRIORITY 2: DEVELOPMENT TOOLS (AI Agent Install Order)**

```yaml
Code Editor & Tools:
□ Visual Studio Code 1.83+: https://code.visualstudio.com/
  - Installation: User installer với extensions support
  - Extensions: TypeScript, ESLint, GitLens, n8n workflow
  - AI Command: winget install Microsoft.VisualStudioCode

□ Google Chrome Latest: https://www.google.com/chrome/
  - Installation: System installer cho browser testing
  - Purpose: n8n web interface access và development
  - AI Command: winget install Google.Chrome

on: Side-by-side với Windows PowerShell
  - AI Command: winget install Microsoft.PowerShell

□ CPU-Z 2.06: https://www.cpuid.com/softwares/cpu-z.html
  - Installation: Hardware monitoring tool
  - Purpose: Dell OptiPlex 3060 resource monitoring
  - AI Command: winget install CPUID.CPU-Z
```

## **🎯 PRIORITY 3: NETWORK & SECURITY (AI Agent Install Order)**

```yaml
Tunnel & Remote Access:
□ Cloudflared Latest: https://github.com/cloudflare/cloudflared/releases
  - Installation: Manual download cloudflared-windows-amd64.exe
  - Location: C:\cloudflared\cloudflared.exe
  - Configuration: Windows service với tunnel config
  - AI Command: Direct download + service installation

□ UltraViewer Latest: https://www.ultraviewer.net/en/download
  - Installation: Portable executable (no installer)
  - Location: C:\automation\remote-access\UltraViewer.exe
  - Configuration: Auto-start với Windows, secure password
  - AI Command: Direct download + startup configuration

Security Components:
□ Windows Defender: Built-in (configuration only)
  - Configuration: Real-time protection enabled
  - Exclusions: Add C:\automation\ folder
  - AI Command: PowerShell configuration scripts

□ Windows Firewall: Built-in (rule configuration)
  - Rules: Allow ports 5678, 8080, 3389
  - Profile: Private network configuration
  - AI Command: netsh firewall configuration
```

## **🎯 PRIORITY 4: PROJECT DEPENDENCIES (AI Agent Install Order)**

```yaml
Source Code Deployment:
✅ n8n Source Repository: https://github.com/n8n-io/n8n.git ✅ **COMPLETED**
  - Location: C:\Github\n8n-tp\ ✅ **COMPLETED**
  - Installation: git clone + pnpm install ✅ **COMPLETED**
  - Build: pnpm run build (production ready) ✅ **COMPLETED**
  - Git Workflow: Single repository với branch strategy ✅ **DOCUMENTED**
  - Rules: .cursor/rules/git-workflow-strategy.mdc ✅ **CREATED**
  - AI Command: Automated git clone + dependency installation ✅ **COMPLETED**

Database Configuration:
□ PostgreSQL Database: strangematic_n8n
  - Database: CREATE DATABASE strangematic_n8n
  - User: strangematic_user với full privileges
  - Connection: localhost:5432 với SSL preferred
  - AI Command: SQL scripts execution

Environment Setup:
□ Production Environment: .env.production file
  - Configuration: Domain, database, API keys
  - Location: C:\automation\n8n\.env.production
  - Security: Encrypted credential storage
  - AI Command: Template-based generation

PM2 Ecosystem:
□ Application Service: ecosystem.config.js
  - Configuration: Production service với auto-restart
  - Logging: Structured logs với rotation
  - Monitoring: Memory limits và health checks
  - AI Command: Service configuration + startup
```

## **🎯 AI AGENT EXECUTION PRIORITIES**

```yaml
Installation Sequence:
1. PRIORITY 1: Core runtime (Node.js, Git, PostgreSQL, PM2)
   - Dependency chain: Node.js → PM2 global installation
   - Database setup: PostgreSQL service + user creation
   - Time estimate: 30-45 minutes

2. PRIORITY 2: Development tools (VSCode, Chrome, utilities)
   - Independent installations, can run parallel
   - Configuration: Extensions + settings
   - Time estimate: 15-20 minutes

3. PRIORITY 3: Network tools (Cloudflared, UltraViewer)
   - Manual downloads + service configuration
   - Security setup: Tunnel authentication
   - Time estimate: 20-30 minutes

4. PRIORITY 4: Project deployment (n8n source, database, services)
   - Source code: Clone + build + configuration
   - Service setup: PM2 ecosystem + auto-start
   - Time estimate: 45-60 minutes

Resource Monitoring:
- CPU usage: Monitor during npm install (can spike to 80%+)
- Memory usage: Track PostgreSQL + Node.js processes
- Disk space: Verify 50GB+ available cho dependencies
- Network: Stable connection cho large downloads (n8n source ~500MB)
```

## **🔧 AI VERIFICATION COMMANDS**

```powershell
# System Dependencies Verification
node --version          # Should return v18.18.2+
npm --version           # Should return 9.8.1+
git --version           # Should return 2.42.0+
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" --version  # Should return 17.5+
pm2 --version           # Should return 5.3.0+

# Service Status Verification
Get-Service postgresql* # Should show "Running"
Get-Service PM2         # Should show "Running"
pm2 status              # Should show empty process list initially

# PostgreSQL Connection Verification
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres -h localhost -p 5432 -c "SELECT version();"
# Should prompt for password và return PostgreSQL version

# Network Tools Verification
cloudflared version     # Should show current version
Test-Path "C:\automation\remote-access\UltraViewer.exe" # Should return True

# Project Dependencies Verification
Test-Path "C:\automation\n8n\package.json"             # Should return True
Test-Path "C:\automation\n8n\.env.production"          # Should return True

# Database Setup Verification (After password setup)
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres -h localhost -p 5432 -c "\l"
# Should list databases including strangematic_n8n (after setup)
```

**🔍 Dell OptiPlex 3060 Driver Installation:**
```yaml
Hardware Drivers:
□ Dell Command Update: https://www.dell.com/support/kbdoc/en-us/000177325
□ Intel Chipset Drivers: Usually auto-detected
□ Intel UHD Graphics 630: Windows Update hoặc Intel website
□ Intel Wireless-AC 9560: Windows Update (automatic)
□ Audio Drivers: Realtek (Windows Update)
□ Ethernet Driver: Intel (Windows Update)

Dell-Specific Tools:
□ Dell SupportAssist: https://www.dell.com/support/contents/en-us/category/product-support/self-support-knowledgebase/software-and-downloads/supportassist
□ Dell BIOS Updates: Through Dell Command Update
□ Hardware Diagnostics: Built into BIOS (F12 on boot)
```

**✅ Day 0 Verification:**
```yaml
System Health Check:
□ Windows 11 Pro activated successfully
□ All hardware detected correctly
□ Internet connectivity working (Wi-Fi + Ethernet)
□ Remote Desktop accessible từ local network
□ Windows Updates completed
□ Essential software installed và functional
□ System performance: Normal boot time, responsive UI
□ Storage: ~100GB used of 512GB C: drive
□ Memory: 4GB+ available of 16GB total

Hardware Verification:
□ CPU: Intel i5-8500T showing 6 cores
□ RAM: 16GB DDR4 detected
□ Storage: Both C: (512GB) và E: (124GB) accessible
□ Graphics: Intel UHD 630 working
□ Network: Wi-Fi 751 Mbps + Ethernet available
□ Audio: Working for remote access

Security Verification:
□ Windows Defender: Active protection
□ Firewall: Enabled với default rules
□ Remote access: Secure authentication enabled
□ User accounts: Local admin account functional
□ BIOS: Secure Boot và TPM 2.0 active
```

---

### **Day 1: Domain Configuration (30-60 phút)** ✅ **COMPLETED**

**🌍 Cloudflare Dashboard Setup:**
- [x] Login to https://dash.cloudflare.com ✅ **COMPLETED**
- [x] Verify strangematic.com domain access ✅ **ACQUIRED**
- [x] Navigate to DNS > Records section ✅ **COMPLETED**

**📋 DNS Records Creation:**
```dns
Required Records:
✅ A Record: @ → 100.100.100.100 (Proxied ✅) **COMPLETED**
✅ CNAME: app → strangematic.com (Proxied ✅) **COMPLETED**
✅ CNAME: api → strangematic.com (Proxied ✅) **COMPLETED**
✅ CNAME: status → strangematic.com (Proxied ✅) **COMPLETED**
✅ CNAME: docs → strangematic.com (Proxied ✅) **COMPLETED**
✅ CNAME: www → strangematic.com (Proxied ✅) **COMPLETED**
```

**🔒 Security Configuration:**
- [x] SSL/TLS → Full (Strict) mode ✅ **COMPLETED**
- [x] Always Use HTTPS: ✅ Enabled **COMPLETED**
- [x] HSTS: ✅ Enabled (1 year, include subdomains) **COMPLETED**
- [x] Security Level: Medium ✅ **COMPLETED**
- [x] Bot Fight Mode: ✅ Enabled **COMPLETED**
- [x] WAF: ✅ Enabled với OWASP rules **COMPLETED**
- [x] SSL Test Result: **B Grade** ✅ **COMPLETED**

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

### **Day 2: Cloudflare Tunnel Setup (45-90 phút)** ✅ **COMPLETED**

**🚇 Tunnel Installation:**
- [x] Download cloudflared-windows-amd64.exe từ [GitHub](https://github.com/cloudflare/cloudflared/releases) ✅ **COMPLETED**
- [x] Create directory: `C:\cloudflared\` ✅ **COMPLETED**
- [x] Rename executable to: `cloudflared.exe` ✅ **COMPLETED**
- [x] Version: cloudflared 2025.7.0 (68.5MB Windows x64) ✅ **VERIFIED**
- [x] Fixed platform compatibility issues ✅ **COMPLETED**

**🔑 Tunnel Authentication:**
```powershell
# PowerShell as Administrator
cd C:\cloudflared

# Browser-based authentication ✅ COMPLETED
cloudflared tunnel login

# Create production tunnel ✅ COMPLETED
cloudflared tunnel create automation-hub-prod
# Tunnel ID: 58d98946-68c4-4127-9dab-cb531f3ca47a

# Configuration file created ✅ COMPLETED
```
**Status**: Authentication ✅ **COMPLETED** - Tunnel created successfully
**Tunnel ID**: `58d98946-68c4-4127-9dab-cb531f3ca47a`
**Credentials**: `C:\Users\phaml\.cloudflared\58d98946-68c4-4127-9dab-cb531f3ca47a.json`

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
□ Remote Desktop: Port 3389 (RDP backup)
□ n8n Application: Port 5678 (main app)
□ Status Monitor: Port 8080 (health checks)
□ HTTP: Port 80 (tunnel routing)
□ HTTPS: Port 443 (tunnel routing)

Outbound Rules (Review):
□ UltraViewer: Allow all HTTPS connections
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

**👁️ UltraViewer Installation:**
- [ ] Download từ https://www.ultraviewer.net/en/download
- [ ] No installation required: Portable executable (~6MB)
- [ ] Configuration:
  - Save to: C:\automation\remote-access\UltraViewer.exe
  - Run và note unique ID (e.g., 123 456 789)
  - Set secure password cho unattended access
  - Enable "Start with Windows" option
  - Test local connection first

**🌐 UltraViewer Network Settings:**
```yaml
Configuration:
- Connection Type: P2P cloud-routed (no port forwarding needed)
- ID: [Generated unique ID - document securely]
- Password: [Secure password - document securely]
- Auto Accept: ❌ Disabled (security)
- Auto-start: ✅ Enabled (with Windows boot)
- File Transfer: ✅ Enabled
- Chat Window: ✅ Enabled (F1 hotkey)
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
□ UltraViewer connection từ external network successful
□ Connection performance acceptable (smooth cursor/typing)
□ RDP connection working as backup
□ UltraViewer auto-starts với Windows boot
□ Security: Connections require ID + password authentication
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

### **Day 10-11: n8n Source Code Setup (4-6 giờ)** ⏳ **IN PROGRESS**

**📂 Repository Clone:**
```powershell
# Create automation directory ✅ COMPLETED
mkdir C:\automation
cd C:\automation

# Clone n8n source code ✅ COMPLETED
git clone https://github.com/n8n-io/n8n.git
cd n8n

# Install dependencies (this takes time!) ✅ COMPLETED
pnpm install

# Build project ✅ COMPLETED (10m32s)
pnpm run build
```
**Status**: Source code ✅ **COMPLETED** - Built successfully với pnpm
**Location**: C:\Github\n8n-tp (working directory)
**Build Time**: 10 minutes 32 seconds on Dell OptiPlex 3060

**🗄️ Database Configuration:**
```sql
-- PostgreSQL database setup
-- STATUS: ⏳ PENDING postgres password setup via pgAdmin 4

-- Step 1: Set postgres password (REQUIRED FIRST!)
-- Method: pgAdmin 4 GUI (RECOMMENDED)
--   1. Start → pgAdmin 4 → Opens in browser
--   2. PostgreSQL 17 → Login/Group Roles → postgres
--   3. Right-click → Properties → Definition
--   4. Password: strangematic_postgres_2024
--   5. Save

-- Step 2: Run database setup script ⏳ READY
-- File: C:\Github\n8n-tp\database-setup.sql ✅ CREATED
-- Command: psql -U postgres -h localhost -p 5432 -f database-setup.sql

-- Script contents (ready to execute):
CREATE DATABASE strangematic_n8n;
CREATE USER strangematic_user WITH PASSWORD 'strangematic_2024_secure!';
GRANT ALL PRIVILEGES ON DATABASE strangematic_n8n TO strangematic_user;
ALTER USER strangematic_user CREATEDB;

-- Connect to new database và grant schema privileges
\c strangematic_n8n;
GRANT ALL ON SCHEMA public TO strangematic_user;
GRANT ALL ON ALL TABLES IN SCHEMA public TO strangematic_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO strangematic_user;

-- Verify setup
\l
\du
```
**Database Setup Status**: ⏳ **PENDING** - Waiting for postgres password setup

**⚙️ Environment Configuration:**
```yaml
# Environment files ✅ CREATED
# Template: C:\Github\n8n-tp\env-production-template.txt ✅ READY
# Active: C:\Github\n8n-tp\.env.production ✅ CREATED

# Configuration content:
DOMAIN_NAME=strangematic.com
N8N_EDITOR_BASE_URL=https://app.strangematic.com
WEBHOOK_URL=https://api.strangematic.com
N8N_HOST=app.strangematic.com
N8N_PROTOCOL=https
N8N_PORT=5678

# Database (configured for strangematic.com)
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=localhost
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=strangematic_n8n
DB_POSTGRESDB_USER=strangematic_user
DB_POSTGRESDB_PASSWORD=strangematic_2024_secure!

# YEScale API Configuration (cost optimization)
YESCALE_BASE_URL=https://yescale.bogia.app
YESCALE_API_KEY=your_yescale_access_key_here
YESCALE_ENABLE_FALLBACK=true

# Security (strangematic.com production)
N8N_SECURE_COOKIE=true
N8N_JWT_SECRET=strangematic_jwt_secret_2024_very_secure
N8N_ENCRYPTION_KEY=strangematic_encryption_key_2024_ultra_secure
```
**Environment Status**: ✅ **COMPLETED** - Files created với strangematic.com configuration

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
✅ Windows 11 Pro: Fresh installation completed successfully
✅ Drivers & Software: All essential software installed
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

### **🚨 Windows Installation Issues:**
```yaml
Problem: Installation hangs or fails
Solution:
  1. Verify BIOS settings (UEFI mode, Secure Boot)
  2. Check USB installation media integrity
  3. Test RAM với MemTest86+ (hardware issue)
  4. Update BIOS to latest version
  5. Try different USB port or USB drive
```

### **🚨 Driver Issues:**
```yaml
Problem: Hardware not detected properly
Solution:
  1. Run Windows Update to auto-install drivers
  2. Download Dell Command Update tool
  3. Install drivers directly từ Dell website
  4. Check Device Manager for unknown devices
  5. Reboot after each driver installation
```

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

### **🚨 PostgreSQL Password Setup Issues:**
```yaml
Problem: PostgreSQL installer không có password field hoặc postgres user không có password
Solution:
  ✅ RECOMMENDED Method - pgAdmin 4 GUI (User-Friendly):
     1. Launch: Start Menu → Search "pgAdmin" → pgAdmin 4
     2. Interface: Opens in web browser (web-based GUI)
     3. Connection: May auto-connect or ask for master password
     4. Navigation: PostgreSQL 17 → Login/Group Roles → postgres user
     5. Edit: Right-click postgres → Properties → Definition tab
     6. Password: Set to "strangematic_postgres_2024"
     7. Save: Click Save to apply changes
     8. Verify: Password is now set for postgres user

     Tool Location: C:\Program Files\PostgreSQL\17\pgAdmin 4\runtime\pgAdmin4.exe
     Interface Type: Web-based PostgreSQL administration tool
     Benefit: No command line knowledge required

  Alternative Method 1 - Command Line (Advanced):
     # Requires Administrator privileges
     # Run postgres-password-reset.ps1 script
     # Or manual pg_hba.conf modification

  Alternative Method 2 - Manual psql (If accessible):
     cd "C:\Program Files\PostgreSQL\17\bin"
     psql -U postgres
     ALTER USER postgres PASSWORD 'strangematic_postgres_2024';
     \q

  Verification Commands:
     psql -U postgres -h localhost -p 5432
     # Should prompt for password: strangematic_postgres_2024
```

### **🚨 n8n Database Connection:**
```yaml
Problem: n8n cannot connect to PostgreSQL
Solution:
  1. Verify PostgreSQL service running
  2. Check database credentials in .env.production
  3. Test connection manually với psql
  4. Review PostgreSQL logs for authentication errors
  5. Ensure postgres user has password set (see above section)
```

### **🚨 Remote Access Problems:**
```yaml
Problem: UltraViewer connection refused
Solution:
1. Check UltraViewer process running
2. Verify internet connectivity
3. Test with different network connection
4. Check UltraViewer ID và password
5. Use RDP backup access (Port 3389)
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

**Estimated Completion:** 15 ngày (bao gồm Day 0 Windows installation)
**Success Criteria:** >98% uptime, <3s response times, full remote accessibility, complete Windows setup

