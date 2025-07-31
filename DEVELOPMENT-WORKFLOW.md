# 🔄 SAFE DEVELOPMENT WORKFLOW GUIDE

## 1. SETUP DEVELOPMENT ENVIRONMENT

### **Database Separation**
```sql
-- Create development database
CREATE DATABASE strangematic_n8n_dev;
CREATE USER strangematic_dev WITH PASSWORD 'dev_password_secure';
GRANT ALL PRIVILEGES ON DATABASE strangematic_n8n_dev TO strangematic_dev;
```

### **Development PM2 Config**
```javascript
// ecosystem-development.config.js (tạo mới)
module.exports = {
  apps: [{
    name: 'strangematic-dev',
    script: './packages/cli/bin/n8n',
    cwd: 'C:/Github/n8n-tp',
    env: {
      NODE_ENV: 'development',
      N8N_PORT: 5679,  // Port khác với production (5678)
      DB_TYPE: 'postgresdb',
      DB_POSTGRESDB_HOST: 'localhost',
      DB_POSTGRESDB_PORT: 5432,
      DB_POSTGRESDB_DATABASE: 'strangematic_n8n_dev',  // Dev database
      DB_POSTGRESDB_USER: 'strangematic_dev',
      DB_POSTGRESDB_PASSWORD: 'dev_password_secure',
      N8N_BASIC_AUTH_ACTIVE: 'false'
    },
    max_memory_restart: '1G',
    watch: true,  // Auto-reload on file changes
    ignore_watch: ['node_modules', 'logs', '.git']
  }]
};
```

## 2. FEATURE DEVELOPMENT PROCESS

### **Step 1: Create Feature Branch**
```powershell
# Bắt đầu feature mới
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name

# Verify clean state
git status
```

### **Step 2: Development Testing**
```powershell
# Start development environment
pm2 start ecosystem-development.config.js

# Development URL: http://localhost:5679
# Production vẫn chạy: https://app.strangematic.com (port 5678)
```

### **Step 3: Testing & Integration**
```powershell
# Test thoroughly in development
# Build để kiểm tra compilation
pnpm run build

# Integration testing
git checkout develop
git merge feature/your-feature-name
pm2 restart strangematic-dev  # Test in integration environment
```

### **Step 4: Production Deployment**
```powershell
# Chỉ sau khi test kỹ trong dev
git checkout main
git merge develop

# Build production
pnpm run build

# Deploy with zero-downtime
pm2 reload strangematic-hub  # Graceful restart
```

## 3. ENVIRONMENT ISOLATION

### **Port Separation**
- Production: `5678` (https://app.strangematic.com)
- Development: `5679` (http://localhost:5679)

### **Database Separation**
- Production: `strangematic_n8n` 
- Development: `strangematic_n8n_dev`

### **Process Separation**
- Production: `strangematic-hub` (PM2 ID: 1)
- Development: `strangematic-dev` (PM2 new ID)

## 4. TESTING WORKFLOW

### **Before Production Merge**
```powershell
# Required checks
✅ Development environment tests pass
✅ Build successful: pnpm run build  
✅ Database migrations work
✅ No breaking changes to API
✅ Workflows in development work correctly
```

---
*Safe development workflow đảm bảo production không bị ảnh hưởng*
