# strangematic.com Quick Deployment Guide

**Target:** Windows 11 Pro + n8n Source Code + Cloudflare Tunnel
**Timeline:** 3-5 ngày cho Phase 1 completion
**Hardware:** Dell OptiPlex 3060 (confirmed suitable)

---

## 🎯 USER REQUIREMENTS CHECKLIST

### **📋 Information You Need to Provide:**

**Domain & Network:**
- ✅ **Cloudflare Account:** Login email và password
- ✅ **Domain:** strangematic.com (confirmed acquired)
- ✅ **Router Access:** Để setup direct Ethernet connection
- ✅ **Windows User:** Username cho automatic login setup

**API Credentials (Phase 2):**
- 🔄 **YEScale API Key:** ⭐ **PRIMARY CHOICE** - Get từ https://yescale.bogia.app (40-80% cost savings)
- 🔄 **OpenAI API Key:** **FALLBACK** - Get từ https://platform.openai.com/api-keys  
- 🔄 **Figma Access Token:** Get từ https://help.figma.com/hc/en-us/articles/8085703771159
- 🔄 **Telegram Bot Token:** Create với @BotFather
- 🔄 **Discord Application:** Create tại https://discord.com/developers/applications

**Accounts Setup Required:**
- ✅ **Cloudflare:** Free account sufficient
- 🆕 **YEScale:** VND-based billing, 40-80% cost savings vs original providers
- 🔄 **OpenAI:** Fallback only - $10-20/month estimate (reduced usage)
- 🔄 **Google Cloud:** Free tier sufficient cho initial testing

---

## 🚀 PHASE 1: FOUNDATION (3-5 ngày)

### **Day 1: Domain & DNS Setup**

**🌐 Cloudflare Configuration (30 phút):**

1. **Login Cloudflare Dashboard:**
   ```
   URL: https://dash.cloudflare.com
   Domain: Select "strangematic.com"
   Navigate: DNS > Records
   ```

2. **Create DNS Records:**
   ```dns
   # Main A Record
   Type: A
   Name: @ (or strangematic.com)
   Content: 100.100.100.100
   Proxy: ✅ Orange Cloud (Proxied)

   # Subdomain CNAMEs
   app.strangematic.com → strangematic.com (Proxied ✅)
   api.strangematic.com → strangematic.com (Proxied ✅)
   status.strangematic.com → strangematic.com (Proxied ✅)
   docs.strangematic.com → strangematic.com (Proxied ✅)
   ```

3. **Security Settings:**
   ```yaml
   Navigate: SSL/TLS > Overview
   - Encryption Mode: Full (Strict)
   - Always Use HTTPS: ✅ Enabled
   - HSTS: ✅ Enabled (1 year)

   Navigate: Security > WAF
   - WAF: ✅ Enabled
   - Security Level: Medium
   - Bot Fight Mode: ✅ Enabled
   ```

**✅ Verification:** All subdomains resolve với A+ SSL rating

---

### **Day 2: Cloudflare Tunnel Setup**

**🚇 Tunnel Installation (45 phút):**

1. **Download Cloudflared:**
   ```powershell
   # Create directory
   mkdir C:\cloudflared

   # Download from: https://github.com/cloudflare/cloudflared/releases
   # File: cloudflared-windows-amd64.exe
   # Rename to: cloudflared.exe
   # Place in: C:\cloudflared\
   ```

2. **Add to Windows PATH:**
   ```
   Windows Search → "Environment Variables"
   System Properties → Environment Variables
   Path → Edit → New → C:\cloudflared
   ```

3. **Tunnel Authentication:**
   ```powershell
   # Open PowerShell as Administrator
   cd C:\cloudflared

   # Login (opens browser)
   cloudflared tunnel login

   # Create tunnel
   cloudflared tunnel create automation-hub-prod

   # Note: Save the tunnel UUID displayed
   ```

4. **Configure Tunnel Routes:**
   ```yaml
   # Create file: C:\cloudflared\config.yml
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

5. **Assign DNS Routes:**
   ```powershell
   cloudflared tunnel route dns automation-hub-prod app.strangematic.com
   cloudflared tunnel route dns automation-hub-prod api.strangematic.com
   cloudflared tunnel route dns automation-hub-prod status.strangematic.com
   ```

**✅ Verification:** Test tunnel connection với `cloudflared tunnel run automation-hub-prod`

---

### **Day 3: Windows Headless Setup**

**🖥️ System Configuration (60 phút):**

1. **Automatic Login Setup:**
   ```powershell
   # Run as Administrator
   reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
   reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d "YOUR_USERNAME" /f
   reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d "YOUR_PASSWORD" /f
   ```

2. **Power Management:**
   ```powershell
   # High performance power plan
   powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

   # Disable sleep
   powercfg /change standby-timeout-ac 0
   powercfg /change standby-timeout-dc 0
   ```

3. **UltraVNC Installation:**
   ```
   Download: https://www.uvnc.com/downloads/ultravnc.html
   Install: UltraVNC Server + Viewer
   Configuration:
   - VNC Password: [Your secure password]
   - Install as Service: ✅ Yes
   - Auto-start: ✅ Yes
   ```

4. **Windows Firewall:**
   ```yaml
   Inbound Rules (Allow):
   - VNC Server: Port 5900
   - Remote Desktop: Port 3389
   - n8n Application: Port 5678
   - Status Monitor: Port 8080
   ```

**✅ Verification:** Test VNC connection từ another device on network

---

### **Day 4-5: Application Stack**

**📦 Software Installation (90 phút):**

1. **Node.js Installation:**
   ```
   Download: https://nodejs.org/en/download (LTS version)
   Install: Default settings
   Verify: node --version && npm --version
   ```

2. **PostgreSQL Installation:**
   ```
   Download: https://www.postgresql.org/download/windows/
   Version: PostgreSQL 14+
   Setup:
   - Username: postgres
   - Password: [secure password]
   - Port: 5432
   - Locale: Default
   ```

3. **PM2 Global Installation:**
   ```powershell
   npm install -g pm2-windows-service
   pm2-service-install
   ```

4. **n8n Source Code:**
   ```powershell
   # Clone repository
   git clone https://github.com/n8n-io/n8n.git
   cd n8n

   # Install dependencies
   npm install

   # Build project
   npm run build
   ```

**✅ Verification:** n8n builds successfully without errors

---

## 🔧 WORKFLOW TOOLS MANAGEMENT STRATEGY

### **🗂️ Organization Structure:**

```yaml
C:\automation\
├── n8n\                    # Main n8n installation
├── workflows\              # Custom workflow exports
├── nodes\                  # Custom node development
├── assets\                 # Design assets storage
├── logs\                   # System logs
├── backups\                # Database và configuration backups
└── monitoring\             # Health check scripts
```

### **📊 Management Tools:**

**Development:**
- **Code Editor:** Visual Studio Code với n8n extensions
- **Version Control:** Git cho workflow version management
- **Testing:** n8n built-in testing framework
- **Documentation:** Markdown files trong workflows/ directory

**Production:**
- **Process Manager:** PM2 cho service management
- **Monitoring:** Custom PowerShell scripts + YEScale usage tracking
- **Backups:** Automated PostgreSQL dumps
- **Logs:** Windows Event Log integration
- **Cost Control:** YEScale hybrid API routing với fallback logic

**API Configuration:**
```yaml
# Primary (YEScale) - Cost-optimized
YESCALE_BASE_URL=https://yescale.bogia.app
YESCALE_API_KEY=your_yescale_access_key
YESCALE_ENABLE_FALLBACK=true

# Fallback (Original Providers) - Premium features
OPENAI_API_KEY=your_openai_fallback_key
CLAUDE_API_KEY=your_claude_fallback_key
GOOGLE_AI_KEY=your_google_fallback_key

# Cost Control
MAX_DAILY_COST_USD=50
COST_ALERT_WEBHOOK=https://api.strangematic.com/webhook/cost-alert
```

**Workflow Lifecycle:**
```yaml
Development:
  1. Design workflow trong n8n interface
  2. Test với sample data
  3. Export workflow JSON
  4. Commit to Git repository

Production:
  1. Import workflow to production n8n
  2. Configure production API keys
  3. Test với real data
  4. Monitor performance và errors

Maintenance:
  1. Weekly performance review
  2. Monthly backup verification
  3. Quarterly optimization
  4. Workflow documentation updates
```

---

## 🎯 NEXT IMMEDIATE STEPS

### **Start Today:**

1. **Login to Cloudflare Dashboard**
   - Verify strangematic.com domain access
   - Begin DNS configuration

2. **Download Required Software**
   - Cloudflared Windows executable
   - UltraVNC installer
   - Node.js LTS installer

3. **Prepare Network**
   - Connect Dell OptiPlex 3060 via Ethernet
   - Ensure stable internet connection
   - Document router IP addresses

### **Expected Timeline:**
- **Day 1-2:** Domain và tunnel setup ✅
- **Day 3:** Windows headless configuration ✅
- **Day 4-5:** Application stack installation ✅
- **Week 2:** Bot integration và testing ✅

### **Success Criteria Phase 1:**
```yaml
✅ Domain Resolution: All subdomains resolve globally
✅ Tunnel Health: "Healthy" status trong Cloudflare dashboard
✅ Remote Access: VNC connection working reliably
✅ Services: All Windows services auto-start
✅ Database: PostgreSQL accepting connections
✅ n8n: Application builds và runs successfully
```

**Ready to Begin:** DNS configuration là first step - bạn có thể bắt đầu ngay!

---

*Updated: Real-time progress tracking*
*Next Update: After Phase 1 completion*
