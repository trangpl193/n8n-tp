# 02. Headless Ubuntu Server Setup Guide

## 🎯 **Mục Tiêu**
Hướng dẫn chi tiết setup Ubuntu Server 22.04 LTS trên Dell Optiplex 3050 Mini trong chế độ headless (không màn hình, bàn phím, chuột).

---

## 📋 **Checklist Chuẩn Bị**

### **🔧 Thiết Bị Cần Thiết:**
- [ ] **Dell Optiplex 3050 Mini** đã upgrade RAM 32GB
- [ ] **Monitor, keyboard, mouse tạm thời** cho initial setup
- [ ] **Ethernet cable** Cat5e/Cat6
- [ ] **UPS backup** (recommended)
- [ ] **Ubuntu Server 22.04 LTS ISO** trên USB drive
- [ ] **Computer khác trong network** để test SSH

### **🌐 Network Information Cần Có:**
- [ ] **Router IP:** _______________
- [ ] **Available IP range:** _______________  
- [ ] **DNS servers:** _______________
- [ ] **Planned static IP cho Dell Mini:** _______________

---

## 🚀 **Phase 1: Initial Installation**

### **Step 1: Ubuntu Server Installation**

#### **📀 Boot từ USB:**
```bash
# Preparation:
1. Download Ubuntu Server 22.04 LTS ISO
2. Create bootable USB drive using Rufus/Balena Etcher
3. Connect temporary monitor, keyboard, mouse
4. Boot Dell Mini từ USB drive
```

#### **⚙️ Installation Configuration:**
```bash
Installation Options:
✅ Language: English
✅ Keyboard: US English (or preferred layout)
✅ Network: Configure static IP
   - Interface: Ethernet (enp1s0)
   - IP: 192.168.1.100/24 (adjust for your network)
   - Gateway: 192.168.1.1
   - DNS: 8.8.8.8, 8.8.4.4
✅ Proxy: None
✅ Mirror: Default Ubuntu mirror
✅ Storage: Use entire disk (guided setup)
✅ Profile setup:
   - Name: n8n-admin
   - Username: n8nadmin  
   - Password: Strong password (document safely)
✅ SSH Setup: ✅ Install OpenSSH server
✅ Featured server snaps: None (skip)
```

#### **🔐 Security During Installation:**
```bash
# SSH server configuration:
✅ Import SSH identity: No (we'll configure manually)
✅ Allow password authentication over SSH: Yes (temporary)

# Important: Change this after key-based auth setup
```

### **Step 2: Post-Installation System Configuration**

#### **📦 Essential Package Installation:**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y \
    htop \
    ncdu \
    vim \
    git \
    curl \
    wget \
    unzip \
    tree \
    fail2ban \
    ufw \
    net-tools

# Install Docker prerequisites
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release
```

#### **🔒 Firewall Configuration:**
```bash
# Configure UFW firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 5678/tcp  # n8n port
sudo ufw --force enable

# Verify firewall status
sudo ufw status verbose
```

#### **📊 System Monitoring Setup:**
```bash
# Install htop configuration
echo 'alias ll="ls -alF"' >> ~/.bashrc
echo 'alias la="ls -A"' >> ~/.bashrc
echo 'alias l="ls -CF"' >> ~/.bashrc

# Create system monitoring script
cat > ~/system-monitor.sh << 'EOF'
#!/bin/bash
echo "=== System Status ==="
echo "Uptime: $(uptime)"
echo "Memory: $(free -h)"
echo "Disk: $(df -h /)"
echo "CPU: $(cat /proc/loadavg)"
echo "Network: $(ip addr show enp1s0 | grep inet)"
EOF

chmod +x ~/system-monitor.sh
```

---

## 🔐 **Phase 2: SSH Security Hardening**

### **Step 1: SSH Key Pair Generation**

#### **🔑 On Your Main Computer:**
```bash
# Windows (PowerShell):
ssh-keygen -t rsa -b 4096 -C "n8n-automation-dell-mini"
# Save to: C:\Users\YourName\.ssh\n8n_automation_rsa

# Linux/Mac:
ssh-keygen -t rsa -b 4096 -C "n8n-automation-dell-mini"
# Save to: ~/.ssh/n8n_automation_rsa
```

#### **📤 Copy Public Key to Dell Mini:**
```bash
# From main computer:
ssh-copy-id -i ~/.ssh/n8n_automation_rsa.pub n8nadmin@192.168.1.100

# Alternative method if ssh-copy-id not available:
scp ~/.ssh/n8n_automation_rsa.pub n8nadmin@192.168.1.100:~/temp_key.pub

# Then on Dell Mini:
mkdir -p ~/.ssh
cat ~/temp_key.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
rm ~/temp_key.pub
```

### **Step 2: SSH Configuration Hardening**

#### **🛡️ Secure SSH Configuration:**
```bash
# Edit SSH config on Dell Mini
sudo vim /etc/ssh/sshd_config

# Apply these settings:
Port 22
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers n8nadmin

# Restart SSH service
sudo systemctl restart ssh
```

#### **✅ Test SSH Key Authentication:**
```bash
# From main computer (test passwordless login):
ssh -i ~/.ssh/n8n_automation_rsa n8nadmin@192.168.1.100

# Should login without password prompt
# If successful, you can now go headless!
```

---

## 📱 **Phase 3: Remote Management Setup**

### **Step 1: Additional Security Measures**

#### **🚫 Fail2ban Configuration:**
```bash
# Configure fail2ban for SSH protection
sudo vim /etc/fail2ban/jail.local

# Add content:
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600

# Start fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

#### **🔄 Automatic Updates:**
```bash
# Configure unattended upgrades
sudo vim /etc/apt/apt.conf.d/50unattended-upgrades

# Enable automatic security updates:
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};

# Enable automatic upgrades
sudo vim /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

### **Step 2: System Monitoring & Alerting**

#### **📊 Resource Monitoring Script:**
```bash
# Create comprehensive monitoring script
cat > ~/monitor-n8n-system.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/n8n-system-monitor.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# System metrics
UPTIME=$(uptime | awk '{print $3,$4}' | sed 's/,//')
LOAD=$(cat /proc/loadavg | awk '{print $1,$2,$3}')
MEMORY=$(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')
DISK=$(df / | tail -1 | awk '{print $5}')

# Log to file
echo "$DATE - Uptime: $UPTIME, Load: $LOAD, Memory: $MEMORY, Disk: $DISK" >> $LOG_FILE

# Alert conditions
LOAD_THRESHOLD=2.0
MEMORY_THRESHOLD=80
DISK_THRESHOLD=80

CURRENT_LOAD=$(echo $LOAD | awk '{print $1}')
CURRENT_MEMORY=$(echo $MEMORY | sed 's/%//')
CURRENT_DISK=$(echo $DISK | sed 's/%//')

# Check thresholds và alert (implement email/notification as needed)
if (( $(echo "$CURRENT_LOAD > $LOAD_THRESHOLD" | bc -l) )); then
    echo "HIGH LOAD ALERT: $CURRENT_LOAD" >> $LOG_FILE
fi
EOF

chmod +x ~/monitor-n8n-system.sh

# Setup cron job for monitoring
(crontab -l 2>/dev/null; echo "*/5 * * * * ~/monitor-n8n-system.sh") | crontab -
```

---

## 🔧 **Phase 4: Headless Deployment**

### **Step 1: Physical Relocation**

#### **📦 Preparation Checklist:**
- [ ] **Disconnect temporary peripherals** (monitor, keyboard, mouse)
- [ ] **Verify SSH access** works perfectly từ main computer
- [ ] **Document connection details:**
  ```
  SSH Connection:
  Host: 192.168.1.100
  User: n8nadmin
  Key: ~/.ssh/n8n_automation_rsa
  Command: ssh -i ~/.ssh/n8n_automation_rsa n8nadmin@192.168.1.100
  ```

#### **🏠 Physical Setup:**
```bash
# At final location:
1. Connect ethernet cable to router/switch
2. Connect power adapter
3. Connect UPS (if available)
4. Verify network connectivity (LED indicators)
```

### **Step 2: Remote Verification**

#### **✅ Connection Test:**
```bash
# From main computer:
ssh -i ~/.ssh/n8n_automation_rsa n8nadmin@192.168.1.100

# Once connected, verify system:
~/system-monitor.sh
sudo systemctl status ssh
sudo ufw status
ip addr show enp1s0
```

#### **🔍 System Health Check:**
```bash
# Comprehensive system check
echo "=== DELL MINI HEALTH CHECK ===" > ~/health-check.log
echo "Date: $(date)" >> ~/health-check.log
echo "Hostname: $(hostname)" >> ~/health-check.log
echo "Kernel: $(uname -r)" >> ~/health-check.log
echo "Ubuntu: $(lsb_release -d)" >> ~/health-check.log
echo "" >> ~/health-check.log

echo "=== HARDWARE ===" >> ~/health-check.log
echo "CPU: $(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)" >> ~/health-check.log
echo "Memory: $(free -h | grep 'Mem:' | awk '{print $2}')" >> ~/health-check.log
echo "Disk: $(df -h / | tail -1 | awk '{print $2}')" >> ~/health-check.log
echo "" >> ~/health-check.log

echo "=== NETWORK ===" >> ~/health-check.log
echo "IP: $(ip addr show enp1s0 | grep 'inet ' | awk '{print $2}')" >> ~/health-check.log
echo "Gateway: $(ip route | grep default | awk '{print $3}')" >> ~/health-check.log
echo "DNS: $(cat /etc/resolv.conf | grep nameserver)" >> ~/health-check.log

cat ~/health-check.log
```

---

## 📚 **Phase 5: Remote Management Best Practices**

### **🛠️ Daily Operations Commands:**

#### **System Monitoring:**
```bash
# Quick system check
ssh -i ~/.ssh/n8n_automation_rsa n8nadmin@192.168.1.100 "~/system-monitor.sh"

# Detailed monitoring
ssh -i ~/.ssh/n8n_automation_rsa n8nadmin@192.168.1.100 "htop"

# Log monitoring
ssh -i ~/.ssh/n8n_automation_rsa n8nadmin@192.168.1.100 "tail -f /var/log/n8n-system-monitor.log"
```

#### **File Transfer:**
```bash
# Upload files to Dell Mini
scp -i ~/.ssh/n8n_automation_rsa localfile.txt n8nadmin@192.168.1.100:~/

# Download files from Dell Mini  
scp -i ~/.ssh/n8n_automation_rsa n8nadmin@192.168.1.100:~/remotefile.txt ./

# Sync directories
rsync -avz -e "ssh -i ~/.ssh/n8n_automation_rsa" ./local-dir/ n8nadmin@192.168.1.100:~/remote-dir/
```

#### **System Maintenance:**
```bash
# Update system remotely
ssh -i ~/.ssh/n8n_automation_rsa n8nadmin@192.168.1.100 "sudo apt update && sudo apt upgrade -y"

# Restart system if needed
ssh -i ~/.ssh/n8n_automation_rsa n8nadmin@192.168.1.100 "sudo reboot"

# Check system after restart
sleep 60 && ssh -i ~/.ssh/n8n_automation_rsa n8nadmin@192.168.1.100 "~/system-monitor.sh"
```

---

## ✅ **Success Criteria**

### **Phase Completion Checklist:**
- [ ] **Ubuntu Server 22.04 LTS installed** với all updates
- [ ] **SSH key authentication working** from main computer
- [ ] **Static IP configured** và stable network connection
- [ ] **Firewall configured** với appropriate ports open
- [ ] **Fail2ban protection** active against brute force
- [ ] **System monitoring** scripts operational
- [ ] **Headless operation verified** - no peripherals needed
- [ ] **Remote management tested** - SSH, file transfer, monitoring

### **📊 Performance Baselines:**
- **Boot time:** <60 seconds to SSH availability
- **SSH response:** <1 second connection time
- **System load:** <0.5 average under idle conditions
- **Memory usage:** <2GB used với base system
- **Network latency:** <5ms to gateway

---

## 🔄 **Troubleshooting Guide**

### **Common Issues:**

#### **SSH Connection Problems:**
```bash
# Debug SSH connection
ssh -v -i ~/.ssh/n8n_automation_rsa n8nadmin@192.168.1.100

# Check SSH service on Dell Mini (if you have console access)
sudo systemctl status ssh
sudo journalctl -u ssh
```

#### **Network Connectivity Issues:**
```bash
# Check network interface
ip addr show enp1s0
ip route

# Test connectivity
ping 8.8.8.8
nslookup google.com
```

#### **System Performance Issues:**
```bash
# Check resource usage
htop
iostat
free -h
df -h
```

---

## 📞 **Next Steps**
Once headless setup is complete:
1. ✅ **Proceed to**: `03-docker-n8n-deployment.md`
2. 📋 **Prerequisites met**: SSH access, Ubuntu Server ready
3. 🎯 **Ready for**: Docker và n8n installation

---

*Tài liệu này provide step-by-step guide cho headless Ubuntu Server deployment. Follow carefully để ensure secure và stable foundation cho n8n automation system.* 