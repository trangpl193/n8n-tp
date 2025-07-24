# 05. System Monitoring & Maintenance Guide

## 🎯 **Mục Tiêu**
Hướng dẫn thiết lập monitoring, maintenance, và troubleshooting cho n8n automation system trong production environment.

---

## 📋 **Prerequisites Checklist**

### **✅ System Ready:**
- [ ] **n8n stack deployed** và running stable
- [ ] **Workflows operational** và processing data
- [ ] **Basic monitoring** scripts installed
- [ ] **Backup strategy** implemented
- [ ] **SSH access** reliable và secure

---

## 📊 **Phase 1: Comprehensive Monitoring Setup**

### **System Health Dashboard**

#### **📈 Create Advanced Monitoring Script:**
```bash
cat > ~/n8n-deployment/advanced-monitor.sh << 'EOF'
#!/bin/bash

# Advanced n8n System Monitor
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
LOG_FILE="/home/n8nadmin/logs/system-health.log"
ALERT_FILE="/home/n8nadmin/logs/alerts.log"

# Create logs directory
mkdir -p /home/n8nadmin/logs

echo "=== ADVANCED n8n SYSTEM HEALTH CHECK ===" | tee -a $LOG_FILE
echo "Timestamp: $TIMESTAMP" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# System Information
echo "=== SYSTEM OVERVIEW ===" | tee -a $LOG_FILE
echo "Hostname: $(hostname)" | tee -a $LOG_FILE
echo "Uptime: $(uptime)" | tee -a $LOG_FILE
echo "Load Average: $(cat /proc/loadavg)" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Hardware Resources
echo "=== HARDWARE RESOURCES ===" | tee -a $LOG_FILE
echo "CPU Usage:" | tee -a $LOG_FILE
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | tee -a $LOG_FILE

echo "Memory Usage:" | tee -a $LOG_FILE
free -h | tee -a $LOG_FILE

echo "Disk Usage:" | tee -a $LOG_FILE
df -h | grep -E "(/$|/home)" | tee -a $LOG_FILE

echo "Network Interfaces:" | tee -a $LOG_FILE
ip addr show enp1s0 | grep "inet " | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Docker Services Status
echo "=== DOCKER SERVICES ===" | tee -a $LOG_FILE
if command -v docker &> /dev/null; then
    echo "Docker Status:" | tee -a $LOG_FILE
    sudo systemctl is-active docker | tee -a $LOG_FILE
    
    echo "Container Status:" | tee -a $LOG_FILE
    cd ~/n8n-deployment 2>/dev/null && docker compose ps | tee -a $LOG_FILE
    
    echo "Container Resource Usage:" | tee -a $LOG_FILE
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | tee -a $LOG_FILE
else
    echo "Docker not found or not accessible" | tee -a $LOG_FILE
fi
echo "" | tee -a $LOG_FILE

# n8n Application Health
echo "=== n8n APPLICATION HEALTH ===" | tee -a $LOG_FILE

# Check n8n API endpoint
N8N_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5678/healthz 2>/dev/null)
if [ "$N8N_HEALTH" = "200" ]; then
    echo "n8n API: HEALTHY (HTTP 200)" | tee -a $LOG_FILE
else
    echo "n8n API: UNHEALTHY (HTTP $N8N_HEALTH)" | tee -a $LOG_FILE
    echo "ALERT: n8n API health check failed" | tee -a $ALERT_FILE
fi

# Check PostgreSQL
PG_STATUS=$(docker exec n8n-postgres pg_isready -U n8n 2>/dev/null && echo "OK" || echo "FAILED")
echo "PostgreSQL: $PG_STATUS" | tee -a $LOG_FILE
if [ "$PG_STATUS" = "FAILED" ]; then
    echo "ALERT: PostgreSQL connection failed" | tee -a $ALERT_FILE
fi

# Check Redis
REDIS_STATUS=$(docker exec n8n-redis redis-cli ping 2>/dev/null | grep -q "PONG" && echo "OK" || echo "FAILED")
echo "Redis: $REDIS_STATUS" | tee -a $LOG_FILE
if [ "$REDIS_STATUS" = "FAILED" ]; then
    echo "ALERT: Redis connection failed" | tee -a $ALERT_FILE
fi

# Database Size și Connection Info
echo "=== DATABASE METRICS ===" | tee -a $LOG_FILE
DB_SIZE=$(docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT pg_size_pretty(pg_database_size('n8n'));" -t 2>/dev/null | xargs)
echo "Database Size: $DB_SIZE" | tee -a $LOG_FILE

DB_CONNECTIONS=$(docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT count(*) FROM pg_stat_activity WHERE datname='n8n';" -t 2>/dev/null | xargs)
echo "Active Connections: $DB_CONNECTIONS" | tee -a $LOG_FILE

# Workflow Execution Stats (last 24h)
EXEC_COUNT=$(docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT COUNT(*) FROM execution_entity WHERE \"startedAt\" > NOW() - INTERVAL '24 hours';" -t 2>/dev/null | xargs)
echo "Executions (24h): $EXEC_COUNT" | tee -a $LOG_FILE

FAILED_EXEC=$(docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT COUNT(*) FROM execution_entity WHERE \"startedAt\" > NOW() - INTERVAL '24 hours' AND finished = false;" -t 2>/dev/null | xargs)
echo "Failed Executions (24h): $FAILED_EXEC" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Performance Thresholds và Alerts
echo "=== PERFORMANCE ALERTS ===" | tee -a $LOG_FILE

# CPU Alert (threshold: 80%)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    echo "ALERT: High CPU usage: $CPU_USAGE%" | tee -a $ALERT_FILE
fi

# Memory Alert (threshold: 90%)
MEMORY_PERCENT=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
if (( $(echo "$MEMORY_PERCENT > 90" | bc -l) )); then
    echo "ALERT: High memory usage: $MEMORY_PERCENT%" | tee -a $ALERT_FILE
fi

# Disk Alert (threshold: 85%)
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 85 ]; then
    echo "ALERT: High disk usage: $DISK_USAGE%" | tee -a $ALERT_FILE
fi

# Load Average Alert (threshold: 4.0 for 2-core system)
LOAD_1MIN=$(cat /proc/loadavg | awk '{print $1}')
if (( $(echo "$LOAD_1MIN > 4.0" | bc -l) )); then
    echo "ALERT: High load average: $LOAD_1MIN" | tee -a $ALERT_FILE
fi

echo "Monitoring completed at $(date)" | tee -a $LOG_FILE
echo "========================================" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
EOF

chmod +x ~/n8n-deployment/advanced-monitor.sh
```

#### **🔔 Alert Notification System:**
```bash
cat > ~/n8n-deployment/alert-handler.sh << 'EOF'
#!/bin/bash

ALERT_FILE="/home/n8nadmin/logs/alerts.log"
LAST_ALERT_FILE="/home/n8nadmin/logs/last-alert-time"

# Check for new alerts
if [ -f "$ALERT_FILE" ]; then
    # Get last alert time
    LAST_ALERT_TIME=0
    if [ -f "$LAST_ALERT_FILE" ]; then
        LAST_ALERT_TIME=$(cat $LAST_ALERT_FILE)
    fi
    
    # Check for new alerts since last check
    CURRENT_TIME=$(date +%s)
    NEW_ALERTS=$(find $ALERT_FILE -newermt "@$LAST_ALERT_TIME" 2>/dev/null | wc -l)
    
    if [ $NEW_ALERTS -gt 0 ]; then
        # Process alerts
        echo "Processing $NEW_ALERTS new alerts..."
        
        # Send to n8n webhook for email notification
        RECENT_ALERTS=$(tail -10 $ALERT_FILE)
        curl -X POST http://localhost:5678/webhook/system-alert \
             -H "Content-Type: application/json" \
             -d "{\"alerts\": \"$RECENT_ALERTS\", \"timestamp\": \"$(date)\"}" \
             2>/dev/null
        
        # Update last alert time
        echo $CURRENT_TIME > $LAST_ALERT_FILE
    fi
fi
EOF

chmod +x ~/n8n-deployment/alert-handler.sh
```

### **Cron Job Setup**

#### **📅 Automated Monitoring Schedule:**
```bash
# Setup comprehensive monitoring schedule
(crontab -l 2>/dev/null; cat << 'EOF'
# n8n System Monitoring
*/5 * * * * cd ~/n8n-deployment && ./advanced-monitor.sh >/dev/null 2>&1
*/10 * * * * cd ~/n8n-deployment && ./alert-handler.sh >/dev/null 2>&1
0 2 * * * cd ~/n8n-deployment && ./backup-n8n.sh >> ~/logs/backup.log 2>&1
0 6 * * * find /home/n8nadmin/logs -name "*.log" -mtime +7 -delete
0 */6 * * * docker system prune -f >/dev/null 2>&1
EOF
) | crontab -

# Verify cron jobs
crontab -l
```

---

## 🛠️ **Phase 2: Maintenance Procedures**

### **Daily Maintenance Tasks**

#### **📋 Daily Health Check Script:**
```bash
cat > ~/n8n-deployment/daily-maintenance.sh << 'EOF'
#!/bin/bash

echo "=== DAILY n8n MAINTENANCE REPORT ===" | tee ~/logs/daily-maintenance-$(date +%Y%m%d).log
echo "Date: $(date)" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
echo ""

# 1. System Health Summary
echo "1. SYSTEM HEALTH SUMMARY" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
~/n8n-deployment/advanced-monitor.sh | grep -E "(HEALTHY|UNHEALTHY|OK|FAILED)" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
echo ""

# 2. Workflow Performance Summary
echo "2. WORKFLOW PERFORMANCE (24h)" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
TOTAL_EXEC=$(docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT COUNT(*) FROM execution_entity WHERE \"startedAt\" > NOW() - INTERVAL '24 hours';" -t | xargs)
SUCCESS_EXEC=$(docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT COUNT(*) FROM execution_entity WHERE \"startedAt\" > NOW() - INTERVAL '24 hours' AND finished = true;" -t | xargs)
FAILED_EXEC=$(docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT COUNT(*) FROM execution_entity WHERE \"startedAt\" > NOW() - INTERVAL '24 hours' AND finished = false;" -t | xargs)

echo "Total Executions: $TOTAL_EXEC" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
echo "Successful: $SUCCESS_EXEC" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
echo "Failed: $FAILED_EXEC" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log

if [ $TOTAL_EXEC -gt 0 ]; then
    SUCCESS_RATE=$(echo "scale=2; $SUCCESS_EXEC * 100 / $TOTAL_EXEC" | bc)
    echo "Success Rate: $SUCCESS_RATE%" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
fi
echo ""

# 3. Storage Cleanup
echo "3. STORAGE CLEANUP" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
BEFORE_CLEANUP=$(df -h / | tail -1 | awk '{print $5}')

# Clean old execution data (older than 30 days)
CLEANED_EXEC=$(docker exec n8n-postgres psql -U n8n -d n8n -c "DELETE FROM execution_entity WHERE \"startedAt\" < NOW() - INTERVAL '30 days'; SELECT ROW_COUNT();" -t | tail -1 | xargs)

# Clean Docker system
docker system prune -f >/dev/null 2>&1

AFTER_CLEANUP=$(df -h / | tail -1 | awk '{print $5}')
echo "Disk usage before cleanup: $BEFORE_CLEANUP" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
echo "Disk usage after cleanup: $AFTER_CLEANUP" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
echo "Cleaned old executions: $CLEANED_EXEC" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
echo ""

# 4. Security Updates Check
echo "4. SECURITY UPDATES" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
SECURITY_UPDATES=$(apt list --upgradable 2>/dev/null | grep -c security)
echo "Available security updates: $SECURITY_UPDATES" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log

if [ $SECURITY_UPDATES -gt 0 ]; then
    echo "Security updates available - consider applying during maintenance window" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
fi
echo ""

# 5. Backup Verification
echo "5. BACKUP VERIFICATION" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
LATEST_BACKUP=$(ls -t ~/backups/postgres_*.sql.gz 2>/dev/null | head -1)
if [ -n "$LATEST_BACKUP" ]; then
    BACKUP_SIZE=$(ls -lh "$LATEST_BACKUP" | awk '{print $5}')
    BACKUP_DATE=$(ls -l "$LATEST_BACKUP" | awk '{print $6, $7, $8}')
    echo "Latest backup: $LATEST_BACKUP" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
    echo "Backup size: $BACKUP_SIZE" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
    echo "Backup date: $BACKUP_DATE" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
else
    echo "WARNING: No recent backups found!" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
fi

echo "=== MAINTENANCE COMPLETED ===" | tee -a ~/logs/daily-maintenance-$(date +%Y%m%d).log
EOF

chmod +x ~/n8n-deployment/daily-maintenance.sh
```

### **Weekly Maintenance Tasks**

#### **📅 Weekly Deep Maintenance:**
```bash
cat > ~/n8n-deployment/weekly-maintenance.sh << 'EOF'
#!/bin/bash

echo "=== WEEKLY n8n DEEP MAINTENANCE ===" | tee ~/logs/weekly-maintenance-$(date +%Y%m%d).log
echo "Date: $(date)" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log

# 1. Database Optimization
echo "1. DATABASE OPTIMIZATION" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log
echo "Running database vacuum và analyze..." | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log

docker exec n8n-postgres psql -U n8n -d n8n -c "VACUUM ANALYZE;" 2>&1 | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log

# Database statistics
DB_SIZE=$(docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT pg_size_pretty(pg_database_size('n8n'));" -t | xargs)
TABLE_COUNT=$(docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" -t | xargs)

echo "Database size after optimization: $DB_SIZE" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log
echo "Number of tables: $TABLE_COUNT" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log

# 2. System Updates Check
echo "2. SYSTEM UPDATES CHECK" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log
sudo apt update >/dev/null 2>&1
AVAILABLE_UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
echo "Available system updates: $AVAILABLE_UPDATES" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log

# 3. Docker Images Update Check
echo "3. DOCKER IMAGES CHECK" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log
cd ~/n8n-deployment
CURRENT_N8N=$(docker images | grep n8n | awk '{print $2}' | head -1)
echo "Current n8n version: $CURRENT_N8N" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log

# 4. Performance Analysis
echo "4. PERFORMANCE ANALYSIS (7 days)" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log

# Workflow execution statistics
TOTAL_EXEC_WEEK=$(docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT COUNT(*) FROM execution_entity WHERE \"startedAt\" > NOW() - INTERVAL '7 days';" -t | xargs)
AVG_EXEC_TIME=$(docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT AVG(EXTRACT(EPOCH FROM (\"stoppedAt\" - \"startedAt\"))) FROM execution_entity WHERE \"startedAt\" > NOW() - INTERVAL '7 days' AND \"stoppedAt\" IS NOT NULL;" -t | xargs)

echo "Total executions (7 days): $TOTAL_EXEC_WEEK" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log
echo "Average execution time: ${AVG_EXEC_TIME}s" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log

# Top workflows by execution count
echo "Top workflows by execution count:" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log
docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT workflow_id, COUNT(*) as executions FROM execution_entity WHERE \"startedAt\" > NOW() - INTERVAL '7 days' GROUP BY workflow_id ORDER BY executions DESC LIMIT 5;" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log

# 5. Security Audit
echo "5. SECURITY AUDIT" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log

# Check for failed login attempts
FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l)
echo "Failed SSH login attempts: $FAILED_LOGINS" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log

# Check firewall status
UFW_STATUS=$(sudo ufw status | grep -c "Status: active")
echo "Firewall active: $UFW_STATUS" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log

# Check for suspicious processes
SUSPICIOUS_PROCS=$(ps aux | grep -E "(crypto|miner|bot)" | grep -v grep | wc -l)
echo "Suspicious processes: $SUSPICIOUS_PROCS" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log

echo "=== WEEKLY MAINTENANCE COMPLETED ===" | tee -a ~/logs/weekly-maintenance-$(date +%Y%m%d).log
EOF

chmod +x ~/n8n-deployment/weekly-maintenance.sh

# Schedule weekly maintenance
(crontab -l 2>/dev/null; echo "0 3 * * 0 ~/n8n-deployment/weekly-maintenance.sh >/dev/null 2>&1") | crontab -
```

---

## 🚨 **Phase 3: Incident Response & Troubleshooting**

### **Emergency Response Procedures**

#### **🆘 Critical Incident Handling:**
```bash
cat > ~/n8n-deployment/emergency-response.sh << 'EOF'
#!/bin/bash

INCIDENT_TYPE=$1
INCIDENT_LOG="/home/n8nadmin/logs/incidents.log"

if [ -z "$INCIDENT_TYPE" ]; then
    echo "Usage: $0 [service_down|performance_degraded|security_breach|data_corruption]"
    exit 1
fi

echo "=== EMERGENCY RESPONSE ACTIVATED ===" | tee -a $INCIDENT_LOG
echo "Incident Type: $INCIDENT_TYPE" | tee -a $INCIDENT_LOG
echo "Timestamp: $(date)" | tee -a $INCIDENT_LOG
echo "" | tee -a $INCIDENT_LOG

case $INCIDENT_TYPE in
    "service_down")
        echo "RESPONSE: Service Down Emergency" | tee -a $INCIDENT_LOG
        
        # Check service status
        echo "Checking service status..." | tee -a $INCIDENT_LOG
        cd ~/n8n-deployment
        docker compose ps | tee -a $INCIDENT_LOG
        
        # Attempt service restart
        echo "Attempting service restart..." | tee -a $INCIDENT_LOG
        docker compose restart
        
        # Wait và verify
        sleep 30
        curl -f http://localhost:5678/healthz && echo "n8n restored" || echo "n8n still down" | tee -a $INCIDENT_LOG
        ;;
        
    "performance_degraded")
        echo "RESPONSE: Performance Degradation" | tee -a $INCIDENT_LOG
        
        # Resource analysis
        echo "System resources:" | tee -a $INCIDENT_LOG
        free -h | tee -a $INCIDENT_LOG
        df -h | tee -a $INCIDENT_LOG
        
        # Active workflows
        echo "Active workflows:" | tee -a $INCIDENT_LOG
        docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT workflow_id, COUNT(*) FROM execution_entity WHERE \"startedAt\" > NOW() - INTERVAL '1 hour' AND \"stoppedAt\" IS NULL GROUP BY workflow_id;" | tee -a $INCIDENT_LOG
        ;;
        
    "security_breach")
        echo "RESPONSE: Security Breach" | tee -a $INCIDENT_LOG
        
        # Lock down access
        echo "Implementing security lockdown..." | tee -a $INCIDENT_LOG
        sudo ufw deny ssh
        
        # Document current connections
        echo "Active connections:" | tee -a $INCIDENT_LOG
        ss -tulpn | tee -a $INCIDENT_LOG
        
        echo "SSH access disabled. Manual intervention required." | tee -a $INCIDENT_LOG
        ;;
        
    "data_corruption")
        echo "RESPONSE: Data Corruption Emergency" | tee -a $INCIDENT_LOG
        
        # Stop services immediately
        echo "Stopping services to prevent further corruption..." | tee -a $INCIDENT_LOG
        cd ~/n8n-deployment
        docker compose stop
        
        # Initiate emergency backup
        echo "Creating emergency backup..." | tee -a $INCIDENT_LOG
        docker run --rm -v n8n-deployment_postgres_data:/backup-source -v ~/emergency-backup:/backup ubuntu tar czf /backup/emergency-$(date +%Y%m%d_%H%M%S).tar.gz /backup-source
        
        echo "Services stopped. Emergency backup created. Manual recovery required." | tee -a $INCIDENT_LOG
        ;;
esac

echo "=== EMERGENCY RESPONSE COMPLETED ===" | tee -a $INCIDENT_LOG
echo "" | tee -a $INCIDENT_LOG
EOF

chmod +x ~/n8n-deployment/emergency-response.sh
```

### **Diagnostic Tools**

#### **🔍 System Diagnostic Script:**
```bash
cat > ~/n8n-deployment/system-diagnostic.sh << 'EOF'
#!/bin/bash

DIAGNOSTIC_LOG="/home/n8nadmin/logs/diagnostic-$(date +%Y%m%d_%H%M%S).log"

echo "=== COMPREHENSIVE SYSTEM DIAGNOSTIC ===" | tee $DIAGNOSTIC_LOG
echo "Generated: $(date)" | tee -a $DIAGNOSTIC_LOG
echo "" | tee -a $DIAGNOSTIC_LOG

# 1. System Environment
echo "1. SYSTEM ENVIRONMENT" | tee -a $DIAGNOSTIC_LOG
echo "OS: $(lsb_release -d | cut -f2)" | tee -a $DIAGNOSTIC_LOG
echo "Kernel: $(uname -r)" | tee -a $DIAGNOSTIC_LOG
echo "Architecture: $(uname -m)" | tee -a $DIAGNOSTIC_LOG
echo "Hostname: $(hostname)" | tee -a $DIAGNOSTIC_LOG
echo "Uptime: $(uptime)" | tee -a $DIAGNOSTIC_LOG
echo "" | tee -a $DIAGNOSTIC_LOG

# 2. Hardware Information
echo "2. HARDWARE DETAILS" | tee -a $DIAGNOSTIC_LOG
echo "CPU Info:" | tee -a $DIAGNOSTIC_LOG
lscpu | grep -E "(Model name|CPU\(s\)|Thread|MHz)" | tee -a $DIAGNOSTIC_LOG

echo "Memory Info:" | tee -a $DIAGNOSTIC_LOG
free -h | tee -a $DIAGNOSTIC_LOG
echo "" | tee -a $DIAGNOSTIC_LOG

# 3. Network Configuration
echo "3. NETWORK CONFIGURATION" | tee -a $DIAGNOSTIC_LOG
echo "Network Interfaces:" | tee -a $DIAGNOSTIC_LOG
ip addr show | tee -a $DIAGNOSTIC_LOG

echo "Routing Table:" | tee -a $DIAGNOSTIC_LOG
ip route | tee -a $DIAGNOSTIC_LOG

echo "DNS Configuration:" | tee -a $DIAGNOSTIC_LOG
cat /etc/resolv.conf | tee -a $DIAGNOSTIC_LOG

echo "Active Network Connections:" | tee -a $DIAGNOSTIC_LOG
ss -tulpn | grep -E "(5678|5432|6379)" | tee -a $DIAGNOSTIC_LOG
echo "" | tee -a $DIAGNOSTIC_LOG

# 4. Docker Environment
echo "4. DOCKER ENVIRONMENT" | tee -a $DIAGNOSTIC_LOG
echo "Docker Version:" | tee -a $DIAGNOSTIC_LOG
docker --version | tee -a $DIAGNOSTIC_LOG

echo "Docker Compose Version:" | tee -a $DIAGNOSTIC_LOG
docker compose version | tee -a $DIAGNOSTIC_LOG

echo "Docker System Info:" | tee -a $DIAGNOSTIC_LOG
docker system df | tee -a $DIAGNOSTIC_LOG

echo "Container Status:" | tee -a $DIAGNOSTIC_LOG
cd ~/n8n-deployment 2>/dev/null && docker compose ps | tee -a $DIAGNOSTIC_LOG

echo "Container Logs (last 20 lines each):" | tee -a $DIAGNOSTIC_LOG
echo "--- n8n logs ---" | tee -a $DIAGNOSTIC_LOG
docker compose logs --tail=20 n8n 2>/dev/null | tee -a $DIAGNOSTIC_LOG
echo "--- postgres logs ---" | tee -a $DIAGNOSTIC_LOG  
docker compose logs --tail=20 postgres 2>/dev/null | tee -a $DIAGNOSTIC_LOG
echo "--- redis logs ---" | tee -a $DIAGNOSTIC_LOG
docker compose logs --tail=20 redis 2>/dev/null | tee -a $DIAGNOSTIC_LOG
echo "" | tee -a $DIAGNOSTIC_LOG

# 5. Database Status
echo "5. DATABASE STATUS" | tee -a $DIAGNOSTIC_LOG
DB_CONNECTION=$(docker exec n8n-postgres pg_isready -U n8n 2>/dev/null && echo "OK" || echo "FAILED")
echo "PostgreSQL Connection: $DB_CONNECTION" | tee -a $DIAGNOSTIC_LOG

if [ "$DB_CONNECTION" = "OK" ]; then
    echo "Database Size:" | tee -a $DIAGNOSTIC_LOG
    docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT pg_size_pretty(pg_database_size('n8n'));" | tee -a $DIAGNOSTIC_LOG
    
    echo "Table Count:" | tee -a $DIAGNOSTIC_LOG
    docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" | tee -a $DIAGNOSTIC_LOG
    
    echo "Recent Executions:" | tee -a $DIAGNOSTIC_LOG
    docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT COUNT(*) FROM execution_entity WHERE \"startedAt\" > NOW() - INTERVAL '24 hours';" | tee -a $DIAGNOSTIC_LOG
fi
echo "" | tee -a $DIAGNOSTIC_LOG

# 6. File System Analysis
echo "6. FILESYSTEM ANALYSIS" | tee -a $DIAGNOSTIC_LOG
echo "Disk Usage:" | tee -a $DIAGNOSTIC_LOG
df -h | tee -a $DIAGNOSTIC_LOG

echo "n8n Data Directory:" | tee -a $DIAGNOSTIC_LOG
du -sh ~/n8n-deployment/data/* 2>/dev/null | tee -a $DIAGNOSTIC_LOG

echo "Log Files:" | tee -a $DIAGNOSTIC_LOG
ls -la ~/logs/ 2>/dev/null | tee -a $DIAGNOSTIC_LOG

echo "Backup Files:" | tee -a $DIAGNOSTIC_LOG
ls -la ~/backups/ 2>/dev/null | tail -10 | tee -a $DIAGNOSTIC_LOG
echo "" | tee -a $DIAGNOSTIC_LOG

# 7. Security Status
echo "7. SECURITY STATUS" | tee -a $DIAGNOSTIC_LOG
echo "Firewall Status:" | tee -a $DIAGNOSTIC_LOG
sudo ufw status | tee -a $DIAGNOSTIC_LOG

echo "SSH Configuration:" | tee -a $DIAGNOSTIC_LOG
grep -E "(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication)" /etc/ssh/sshd_config | tee -a $DIAGNOSTIC_LOG

echo "Recent Authentication Logs:" | tee -a $DIAGNOSTIC_LOG
tail -10 /var/log/auth.log | tee -a $DIAGNOSTIC_LOG

echo "=== DIAGNOSTIC COMPLETED ===" | tee -a $DIAGNOSTIC_LOG
echo "Report saved to: $DIAGNOSTIC_LOG" | tee -a $DIAGNOSTIC_LOG
EOF

chmod +x ~/n8n-deployment/system-diagnostic.sh
```

---

## 🔧 **Phase 4: Performance Optimization**

### **Database Optimization**

#### **📊 PostgreSQL Performance Tuning:**
```bash
cat > ~/n8n-deployment/optimize-database.sh << 'EOF'
#!/bin/bash

echo "=== DATABASE OPTIMIZATION ==="
echo "Starting PostgreSQL optimization..."

# Create optimized PostgreSQL configuration
cat > postgres-optimized.conf << 'EOL'
# PostgreSQL Optimization for n8n workload
# 32GB RAM system configuration

# Memory Settings
shared_buffers = 8GB
effective_cache_size = 24GB
work_mem = 512MB
maintenance_work_mem = 2GB

# Connection Settings
max_connections = 100
shared_preload_libraries = 'pg_stat_statements'

# WAL Settings
wal_buffers = 64MB
checkpoint_completion_target = 0.9
max_wal_size = 4GB
min_wal_size = 1GB

# Query Planner
random_page_cost = 1.1
effective_io_concurrency = 200
default_statistics_target = 100

# Worker Processes
max_worker_processes = 8
max_parallel_workers_per_gather = 4
max_parallel_workers = 8
max_parallel_maintenance_workers = 4

# Logging
log_statement = 'none'
log_min_duration_statement = 1000
log_checkpoints = on
log_lock_waits = on

# Autovacuum
autovacuum = on
autovacuum_max_workers = 6
autovacuum_naptime = 30s
autovacuum_vacuum_threshold = 500
autovacuum_analyze_threshold = 250

# Background Writer
bgwriter_delay = 100ms
bgwriter_lru_maxpages = 100
bgwriter_lru_multiplier = 2.0
EOL

# Backup current configuration
cp postgres-custom.conf postgres-custom.conf.backup

# Apply optimized configuration
cp postgres-optimized.conf postgres-custom.conf

echo "Optimized configuration applied. Restarting PostgreSQL..."

# Restart PostgreSQL to apply new configuration
docker compose restart postgres

# Wait for PostgreSQL to be ready
sleep 30

# Verify PostgreSQL is running
if docker exec n8n-postgres pg_isready -U n8n >/dev/null 2>&1; then
    echo "PostgreSQL restarted successfully with optimized configuration"
    
    # Create useful indexes for n8n
    echo "Creating performance indexes..."
    
    docker exec n8n-postgres psql -U n8n -d n8n << 'EOSQL'
-- Indexes for better n8n performance
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_execution_entity_started_at 
ON execution_entity("startedAt");

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_execution_entity_workflow_id 
ON execution_entity(workflow_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_execution_entity_finished_started 
ON execution_entity(finished, "startedAt");

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_execution_entity_status 
ON execution_entity("startedAt", finished) 
WHERE finished = false;

-- Update table statistics
ANALYZE execution_entity;
ANALYZE workflow_entity;
ANALYZE credentials_entity;

SELECT 'Database optimization completed' as status;
EOSQL

    echo "Database optimization completed successfully"
else
    echo "ERROR: PostgreSQL failed to restart. Restoring backup configuration..."
    cp postgres-custom.conf.backup postgres-custom.conf
    docker compose restart postgres
fi
EOF

chmod +x ~/n8n-deployment/optimize-database.sh
```

### **System Performance Tuning**

#### **⚡ System-Level Optimizations:**
```bash
cat > ~/n8n-deployment/optimize-system.sh << 'EOF'
#!/bin/bash

echo "=== SYSTEM PERFORMANCE OPTIMIZATION ==="

# 1. Kernel Parameters Optimization
echo "Optimizing kernel parameters..."

# Create sysctl configuration for n8n
sudo tee /etc/sysctl.d/99-n8n-optimization.conf > /dev/null << 'EOL'
# Network optimization
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr

# Memory management
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# File system
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288

# Process limits
kernel.pid_max = 4194304
EOL

# Apply sysctl changes
sudo sysctl -p /etc/sysctl.d/99-n8n-optimization.conf

# 2. Docker Daemon Optimization
echo "Optimizing Docker daemon..."

sudo tee /etc/docker/daemon.json > /dev/null << 'EOL'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "name": "nofile",
      "hard": 65536,
      "soft": 65536
    },
    "memlock": {
      "name": "memlock",
      "hard": 67108864,
      "soft": 67108864
    }
  },
  "storage-driver": "overlay2",
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "default-shm-size": "256M"
}
EOL

# Restart Docker with new configuration
sudo systemctl restart docker

# Wait for Docker to start
sleep 10

# 3. Node.js Optimization for n8n
echo "Optimizing n8n container configuration..."

# Update docker-compose.yml with performance settings
cd ~/n8n-deployment

# Backup current docker-compose.yml
cp docker-compose.yml docker-compose.yml.backup

# Add performance environment variables to n8n service
python3 << 'EOPY'
import yaml

# Read current docker-compose.yml
with open('docker-compose.yml', 'r') as file:
    compose = yaml.safe_load(file)

# Add performance environment variables
performance_env = [
    "NODE_OPTIONS=--max-old-space-size=8192 --max-semi-space-size=256",
    "N8N_CONCURRENCY_PRODUCTION=10",
    "N8N_AVAILABLE_BINARY_DATA_MODES=filesystem",
    "UV_THREADPOOL_SIZE=16"
]

# Merge with existing environment
if 'n8n' in compose['services']:
    existing_env = compose['services']['n8n'].get('environment', [])
    # Remove any existing NODE_OPTIONS
    existing_env = [env for env in existing_env if not env.startswith('NODE_OPTIONS')]
    compose['services']['n8n']['environment'] = existing_env + performance_env

# Write updated docker-compose.yml
with open('docker-compose.yml', 'w') as file:
    yaml.dump(compose, file, default_flow_style=False)

print("Docker Compose configuration updated")
EOPY

# 4. File System Optimization
echo "Optimizing file system..."

# Set proper permissions and ownership
sudo chown -R 1000:1000 data/n8n
sudo chown -R 999:999 data/postgres
sudo chown -R 999:999 data/redis

# Optimize directory permissions for better performance
find data/ -type d -exec chmod 755 {} \;
find data/ -type f -exec chmod 644 {} \;

# 5. Apply optimizations
echo "Restarting services with optimizations..."

# Restart the entire stack
docker compose down
docker compose up -d

# Wait for services to start
sleep 60

# Verify services are running
if curl -f http://localhost:5678/healthz >/dev/null 2>&1; then
    echo "System optimization completed successfully"
    echo "Services are running with optimized configuration"
else
    echo "Warning: Services may not have started correctly"
    echo "Check logs: docker compose logs"
fi

echo "=== OPTIMIZATION COMPLETED ==="
EOF

chmod +x ~/n8n-deployment/optimize-system.sh
```

---

## ✅ **Success Criteria**

### **📊 Monitoring Effectiveness:**
- [ ] **Automated monitoring** running every 5 minutes
- [ ] **Alert system** functioning với threshold detection
- [ ] **Daily maintenance** reports generated
- [ ] **Weekly deep analysis** completed
- [ ] **Emergency response** procedures tested

### **🎯 Performance Targets:**
- [ ] **System uptime:** >99.5%
- [ ] **n8n response time:** <1 second average
- [ ] **Database query time:** <100ms for common queries
- [ ] **Workflow execution:** 95% success rate
- [ ] **Resource utilization:** CPU <70%, Memory <80%

### **🔧 Maintenance Quality:**
- [ ] **Automated backups** successful daily
- [ ] **Log rotation** preventing disk space issues
- [ ] **Security updates** applied weekly
- [ ] **Performance optimization** measurable improvements
- [ ] **Incident response** procedures documented và tested

---

## 📞 **Next Steps & Advanced Topics**

### **Advanced Monitoring:**
1. 🔗 **Integration với external monitoring** (Grafana, Prometheus)
2. 📱 **Mobile alerts** setup via Slack/email webhooks
3. 📊 **Custom dashboards** cho business metrics
4. 🔍 **APM integration** cho detailed performance tracking

### **Scaling Preparation:**
1. 🔄 **Load testing** để identify bottlenecks
2. 📈 **Horizontal scaling** planning cho Phase 2
3. 🏗️ **Infrastructure as Code** (Terraform, Ansible)
4. 🔒 **Enhanced security** monitoring và compliance

---

*Tài liệu này provides comprehensive monitoring và maintenance framework. Regular execution của các scripts và procedures sẽ ensure stable, high-performance n8n automation system.* 