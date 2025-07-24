# 03. Docker & n8n Stack Deployment

## 🎯 **Mục Tiêu**
Triển khai Docker environment và n8n automation stack trên Ubuntu Server với PostgreSQL, Redis, và monitoring.

---

## 📋 **Prerequisites Checklist**

### **✅ System Requirements:**
- [ ] **Ubuntu Server 22.04 LTS** running headless
- [ ] **SSH access** configured và tested
- [ ] **32GB RAM** installed và recognized
- [ ] **Static IP** configured và stable
- [ ] **Firewall** configured (ports 22, 5678 open)

### **🔧 Before Starting:**
```bash
# Verify system readiness
ssh -i ~/.ssh/n8n_automation_rsa n8nadmin@192.168.1.100

# Check system resources
free -h  # Should show ~32GB RAM
df -h    # Should show adequate disk space
uptime   # Verify system stability
```

---

## 🐳 **Phase 1: Docker Installation**

### **Step 1: Docker Engine Setup**

#### **📦 Install Docker:**
```bash
# Remove old Docker versions (if any)
sudo apt-get remove docker docker-engine docker.io containerd runc

# Update package index
sudo apt-get update

# Install dependencies
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
```

#### **⚙️ Docker Configuration:**
```bash
# Logout and login to apply group changes
exit
ssh -i ~/.ssh/n8n_automation_rsa n8nadmin@192.168.1.100

# Verify Docker installation
docker --version
docker compose version

# Test Docker
docker run hello-world
```

#### **🔧 Docker Daemon Optimization:**
```bash
# Create Docker daemon configuration
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
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
    }
  },
  "storage-driver": "overlay2",
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5
}
EOF

# Restart Docker
sudo systemctl restart docker
sudo systemctl enable docker

# Verify configuration
docker system info
```

---

## 🗄️ **Phase 2: Database Setup (PostgreSQL)**

### **Step 1: PostgreSQL Container Deployment**

#### **📁 Create Project Structure:**
```bash
# Create n8n project directory
mkdir -p ~/n8n-deployment
cd ~/n8n-deployment

# Create data directories
mkdir -p data/postgres
mkdir -p data/redis
mkdir -p data/n8n
mkdir -p logs
mkdir -p backups

# Set proper permissions
sudo chown -R 1000:1000 data/n8n
sudo chown -R 999:999 data/postgres
sudo chown -R 999:999 data/redis
```

#### **🐘 PostgreSQL Configuration:**
```bash
# Create PostgreSQL environment file
cat > .env.postgres << 'EOF'
# PostgreSQL Configuration
POSTGRES_DB=n8n
POSTGRES_USER=n8n
POSTGRES_PASSWORD=n8n_secure_password_2024
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# Performance tuning for 32GB RAM system
POSTGRES_SHARED_BUFFERS=8GB
POSTGRES_EFFECTIVE_CACHE_SIZE=24GB
POSTGRES_WORK_MEM=512MB
POSTGRES_MAINTENANCE_WORK_MEM=2GB
POSTGRES_MAX_CONNECTIONS=100
EOF

# Create PostgreSQL custom configuration
cat > postgres-custom.conf << 'EOF'
# PostgreSQL Custom Configuration for 32GB RAM
shared_buffers = 8GB
effective_cache_size = 24GB
work_mem = 512MB
maintenance_work_mem = 2GB
max_connections = 100
wal_buffers = 64MB
checkpoint_completion_target = 0.9
random_page_cost = 1.1
effective_io_concurrency = 200
max_worker_processes = 8
max_parallel_workers_per_gather = 4
max_parallel_workers = 8
EOF
```

### **Step 2: Redis Configuration**

#### **🔄 Redis Setup:**
```bash
# Create Redis configuration
cat > redis.conf << 'EOF'
# Redis Configuration for n8n Queue
save 900 1
save 300 10
save 60 10000
maxmemory 2gb
maxmemory-policy allkeys-lru
timeout 300
tcp-keepalive 300
tcp-backlog 511
databases 16
EOF
```

---

## 🔄 **Phase 3: n8n Stack Deployment**

### **Step 1: Docker Compose Configuration**

#### **📜 Create Docker Compose File:**
```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: n8n-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=n8n
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=n8n_secure_password_2024
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
      - ./postgres-custom.conf:/etc/postgresql/postgresql.conf
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n -d n8n"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - n8n-network

  redis:
    image: redis:7-alpine
    container_name: n8n-redis
    restart: unless-stopped
    volumes:
      - ./data/redis:/data
      - ./redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - n8n-network

  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n-app
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      # Database
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=n8n_secure_password_2024
      - DB_POSTGRESDB_POOL_SIZE=20
      
      # Queue
      - QUEUE_BULL_REDIS_HOST=redis
      - QUEUE_BULL_REDIS_PORT=6379
      - EXECUTIONS_MODE=queue
      - EXECUTIONS_PROCESS=main
      
      # Security
      - N8N_ENCRYPTION_KEY=generate_secure_32_char_encryption_key
      
      # Performance
      - N8N_LOG_LEVEL=info
      - N8N_LOG_OUTPUT=console
      - WEBHOOK_URL=http://192.168.1.100:5678/
      
      # Features
      - N8N_METRICS=true
      - N8N_DIAGNOSTICS_ENABLED=false
      
    volumes:
      - ./data/n8n:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - n8n-network

  nginx:
    image: nginx:alpine
    container_name: n8n-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - n8n
    networks:
      - n8n-network

networks:
  n8n-network:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
  n8n_data:
EOF
```

### **Step 2: Nginx Reverse Proxy Configuration**

#### **🌐 Nginx Setup:**
```bash
# Create Nginx configuration
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream n8n {
        server n8n:5678;
    }

    server {
        listen 80;
        server_name 192.168.1.100;

        # Redirect HTTP to HTTPS (optional)
        # return 301 https://$server_name$request_uri;

        location / {
            proxy_pass http://n8n;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            
            # Increase timeouts for long-running workflows
            proxy_connect_timeout 300s;
            proxy_send_timeout 300s;
            proxy_read_timeout 300s;
        }
    }
}
EOF
```

### **Step 3: Security Configuration**

#### **🔐 Generate Encryption Key:**
```bash
# Generate secure encryption key for n8n
openssl rand -hex 32 > n8n_encryption_key.txt

# Update docker-compose.yml with actual key
ENCRYPTION_KEY=$(cat n8n_encryption_key.txt)
sed -i "s/generate_secure_32_char_encryption_key/$ENCRYPTION_KEY/" docker-compose.yml

echo "Encryption key generated and configured"
```

#### **🛡️ Additional Security:**
```bash
# Create startup script with environment validation
cat > start-n8n.sh << 'EOF'
#!/bin/bash

echo "Starting n8n automation stack..."

# Verify environment
if [ ! -f ".env.postgres" ]; then
    echo "Error: .env.postgres file not found"
    exit 1
fi

if [ ! -f "docker-compose.yml" ]; then
    echo "Error: docker-compose.yml file not found"
    exit 1
fi

# Check system resources
MEMORY=$(free -g | awk '/^Mem:/{print $2}')
if [ $MEMORY -lt 30 ]; then
    echo "Warning: Less than 30GB RAM available. Current: ${MEMORY}GB"
fi

# Start services
docker compose up -d

# Wait for services to be healthy
echo "Waiting for services to start..."
sleep 30

# Check service health
docker compose ps
docker compose logs --tail=20

echo "n8n stack started successfully!"
echo "Access n8n at: http://192.168.1.100:5678"
EOF

chmod +x start-n8n.sh
```

---

## 🚀 **Phase 4: Stack Deployment**

### **Step 1: Initial Deployment**

#### **🎬 Start the Stack:**
```bash
# Ensure we're in the correct directory
cd ~/n8n-deployment

# Start the stack
./start-n8n.sh

# Monitor startup process
docker compose logs -f n8n
```

#### **✅ Verify Deployment:**
```bash
# Check all services
docker compose ps

# Expected output: All services should be "running" và "healthy"
# postgres    running (healthy)
# redis       running (healthy)  
# n8n         running (healthy)
# nginx       running

# Check resource usage
docker stats --no-stream

# Test connectivity
curl -I http://192.168.1.100:5678
```

### **Step 2: n8n Initial Configuration**

#### **🌐 First Access:**
```bash
# Check n8n accessibility
curl http://192.168.1.100:5678/healthz

# From your main computer, open browser:
# http://192.168.1.100:5678

# You should see n8n setup screen
```

#### **👤 User Setup:**
```bash
# On first access, n8n will prompt for:
# - Admin email
# - Admin password
# - Instance name

# Recommended settings:
# Email: your-email@domain.com
# Password: Strong password (document securely)
# Instance name: Personal Automation Server
```

---

## 📊 **Phase 5: Monitoring Setup**

### **Step 1: Basic Monitoring**

#### **📈 Create Monitoring Script:**
```bash
cat > monitor-n8n-stack.sh << 'EOF'
#!/bin/bash

echo "=== n8n Stack Status ==="
echo "Date: $(date)"
echo ""

echo "=== Docker Services ==="
docker compose ps
echo ""

echo "=== Resource Usage ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
echo ""

echo "=== Service Health ==="
curl -s http://localhost:5678/healthz && echo "n8n: OK" || echo "n8n: ERROR"
docker exec n8n-postgres pg_isready -U n8n && echo "PostgreSQL: OK" || echo "PostgreSQL: ERROR"
docker exec n8n-redis redis-cli ping | grep -q PONG && echo "Redis: OK" || echo "Redis: ERROR"
echo ""

echo "=== Disk Usage ==="
df -h /home/n8nadmin/n8n-deployment
echo ""

echo "=== Recent Logs ==="
echo "n8n logs (last 5 lines):"
docker compose logs --tail=5 n8n
EOF

chmod +x monitor-n8n-stack.sh

# Add to cron for regular monitoring
(crontab -l 2>/dev/null; echo "*/15 * * * * cd ~/n8n-deployment && ./monitor-n8n-stack.sh >> ~/logs/n8n-monitor.log") | crontab -
```

### **Step 2: Performance Tuning**

#### **⚡ Optimize for 32GB RAM:**
```bash
# Update PostgreSQL configuration
cat >> postgres-custom.conf << 'EOF'

# Additional optimizations for n8n workload
shared_preload_libraries = 'pg_stat_statements'
log_statement = 'none'
log_min_duration_statement = 1000
track_activity_query_size = 2048
track_functions = none
track_counts = on
autovacuum = on
autovacuum_max_workers = 6
EOF

# Update n8n environment for better performance
cat >> docker-compose.yml << 'EOF'
      # Additional performance settings
      - NODE_OPTIONS=--max-old-space-size=8192
      - N8N_CONCURRENCY_PRODUCTION=10
      - N8N_AVAILABLE_BINARY_DATA_MODES=filesystem
EOF

# Restart stack to apply changes
docker compose down
docker compose up -d
```

---

## 🛠️ **Phase 6: Backup Strategy**

### **Step 1: Automated Backups**

#### **💾 Database Backup Script:**
```bash
cat > backup-n8n.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/home/n8nadmin/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

echo "Starting n8n backup at $(date)"

# Create backup directory
mkdir -p $BACKUP_DIR

# Database backup
echo "Backing up PostgreSQL database..."
docker exec n8n-postgres pg_dump -U n8n n8n | gzip > $BACKUP_DIR/postgres_$DATE.sql.gz

# n8n data backup
echo "Backing up n8n data..."
tar -czf $BACKUP_DIR/n8n_data_$DATE.tar.gz -C ~/n8n-deployment/data/n8n .

# Configuration backup
echo "Backing up configuration..."
tar -czf $BACKUP_DIR/n8n_config_$DATE.tar.gz -C ~/n8n-deployment \
    docker-compose.yml nginx.conf postgres-custom.conf redis.conf .env.postgres

# Cleanup old backups
echo "Cleaning up old backups..."
find $BACKUP_DIR -type f -mtime +$RETENTION_DAYS -delete

echo "Backup completed at $(date)"
echo "Backup files created:"
ls -la $BACKUP_DIR/*$DATE*
EOF

chmod +x backup-n8n.sh

# Schedule daily backups
(crontab -l 2>/dev/null; echo "0 2 * * * ~/backup-n8n.sh >> ~/logs/backup.log 2>&1") | crontab -
```

### **Step 2: Restore Procedures**

#### **🔄 Create Restore Script:**
```bash
cat > restore-n8n.sh << 'EOF'
#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <backup_date>"
    echo "Example: $0 20240124_020000"
    exit 1
fi

BACKUP_DATE=$1
BACKUP_DIR="/home/n8nadmin/backups"

echo "Starting restore from backup date: $BACKUP_DATE"

# Stop services
cd ~/n8n-deployment
docker compose down

# Restore database
echo "Restoring PostgreSQL database..."
gunzip -c $BACKUP_DIR/postgres_$BACKUP_DATE.sql.gz | docker exec -i n8n-postgres psql -U n8n -d n8n

# Restore n8n data
echo "Restoring n8n data..."
rm -rf ~/n8n-deployment/data/n8n/*
tar -xzf $BACKUP_DIR/n8n_data_$BACKUP_DATE.tar.gz -C ~/n8n-deployment/data/n8n/

# Restore configuration (optional)
echo "Configuration files available in: $BACKUP_DIR/n8n_config_$BACKUP_DATE.tar.gz"

# Restart services
docker compose up -d

echo "Restore completed"
EOF

chmod +x restore-n8n.sh
```

---

## ✅ **Success Criteria**

### **🎯 Deployment Checklist:**
- [ ] **Docker và Docker Compose** installed và configured
- [ ] **PostgreSQL container** running và healthy
- [ ] **Redis container** running và healthy  
- [ ] **n8n container** running và accessible at http://192.168.1.100:5678
- [ ] **Nginx reverse proxy** configured và routing traffic
- [ ] **Monitoring scripts** installed và running
- [ ] **Backup strategy** implemented với automated daily backups
- [ ] **System performance** optimized cho 32GB RAM

### **📊 Performance Baselines:**
- **Container startup time:** <2 minutes for full stack
- **n8n response time:** <1 second for UI loading
- **Database query time:** <100ms for typical queries
- **Memory usage:** PostgreSQL ~8GB, n8n ~2GB, Redis ~1GB
- **Disk I/O:** <50% utilization during normal operations

---

## 🔄 **Troubleshooting Guide**

### **Common Issues:**

#### **Container Won't Start:**
```bash
# Check logs
docker compose logs [service_name]

# Check resource usage
docker system df
free -h

# Restart specific service
docker compose restart [service_name]
```

#### **Database Connection Issues:**
```bash
# Test database connectivity
docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT version();"

# Check PostgreSQL logs
docker compose logs postgres
```

#### **Performance Issues:**
```bash
# Monitor resource usage
docker stats
./monitor-n8n-stack.sh

# Check system performance
htop
iostat -x 1
```

---

## 📞 **Next Steps**
Once Docker stack is deployed successfully:
1. ✅ **Proceed to**: `04-workflow-development.md`
2. 📋 **Prerequisites met**: n8n accessible, database connected
3. 🎯 **Ready for**: First workflow creation và YESCALE.io integration

---

*Tài liệu này provides comprehensive Docker và n8n deployment guide. Follow all steps carefully để ensure stable và performant automation platform.* 