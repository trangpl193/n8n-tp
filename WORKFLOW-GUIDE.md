# 🚀 n8n Git Workflow Guide - strangematic.com Hub

> **Comprehensive guide cho new git workflow với environment management và automated deployment**

## 📋 Overview

Hệ thống đã được refactor hoàn toàn từ single production branch (`n8n-development-new-device`) thành professional git workflow với:

- ✅ **Protected main branch** (production-ready code)
- ✅ **Integration develop branch** (testing và development)
- ✅ **Environment separation** (production vs development configs)
- ✅ **Automated deployment scripts** (PowerShell automation)
- ✅ **Backup protection** (`production-backup-2025-07-30-1627`)

---

## 🏗️ Architecture Overview

```
📦 D:/Github/n8n-tp/
├── 🌿 main branch              # Production (protected)
├── 🌿 develop branch           # Integration testing
├── 📁 environments/            # Environment configurations
│   ├── .env.production         # Production settings
│   ├── .env.development        # Development settings
│   ├── ecosystem.production.config.js
│   └── ecosystem.development.config.js
├── 📁 scripts/                 # Automation scripts
│   ├── setup-environment.ps1   # Initial setup
│   ├── deploy-production.ps1   # Production deployment
│   ├── switch-development.ps1  # Development mode
│   └── cleanup-branches.ps1    # Branch maintenance
└── 📁 logs/                   # Application logs
```

---

## 🛠️ Initial Setup

### 1️⃣ Environment Configuration

```powershell
# 1. Copy template files thành actual .env files
Copy-Item "environments/env-production-template.txt" "environments/.env.production"
Copy-Item "environments/env-development-template.txt" "environments/.env.development"

# 2. Edit environment files với your actual configurations
notepad environments/.env.production
notepad environments/.env.development
```

### 2️⃣ Database Setup

**Production Database:**
```sql
CREATE DATABASE strangematic_n8n_prod;
CREATE USER strangematic_user WITH PASSWORD 'your_secure_production_password';
GRANT ALL PRIVILEGES ON DATABASE strangematic_n8n_prod TO strangematic_user;
```

**Development Database:**
```sql
CREATE DATABASE strangematic_n8n_dev;
GRANT ALL PRIVILEGES ON DATABASE strangematic_n8n_dev TO strangematic_user;
```

### 3️⃣ Run Initial Setup

```powershell
.\scripts\setup-environment.ps1
```

---

## 🔄 Daily Workflow Patterns

### 🎯 Production Deployment

**Máy tính chính (Dell OptiPlex 3060):**
```powershell
# Deploy to production - strangematic.com
.\scripts\deploy-production.ps1

# Access points sau khi deploy:
# 🌐 Main Interface: https://app.strangematic.com
# 🔗 Webhooks: https://api.strangematic.com
# 📊 Health: pm2 status
```

### 🔧 Development Mode

**Máy tính development (bất kỳ máy nào):**
```powershell
# Switch to development mode
.\scripts\switch-development.ps1

# Access points trong development:
# 🌐 Local Interface: http://localhost:5679
# 🔗 Local Webhooks: http://localhost:5679
# 📝 Debug Logs: pm2 logs strangematic-dev
```

---

## 🌿 Git Branch Management

### Branch Strategy
```
main branch (protected)
├── 🟢 Always production-ready
├── 🚫 No direct commits allowed
├── 🔒 Only merge từ develop branch
└── 🚀 Auto-deploy when updated

develop branch (integration)
├── 🔄 Base cho all new features
├── 🧪 Testing ground cho integrations
├── 🔀 Merge destination cho feature branches
└── 📦 Source cho production deployments

feature/* branches
├── 🆕 New feature development
├── 🌱 Branched từ develop
├── 🔀 Merged back to develop
└── 🗑️ Deleted sau khi merge

backup branches
├── 🛡️ production-backup-2025-07-30-1627
├── 💾 Safe restore point
└── 🚫 Never delete
```

### Common Git Commands

**Start new feature:**
```powershell
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name

# Work on your feature...
git add .
git commit -m "feat: your feature description"
git push origin feature/your-feature-name

# Merge to develop
git checkout develop
git merge feature/your-feature-name
git push origin develop
```

**Deploy to production:**
```powershell
git checkout main
git merge develop
git push origin main
.\scripts\deploy-production.ps1
```

---

## 🖥️ Multi-Machine Configuration

### Dell OptiPlex 3060 (Production Machine)

**Configuration:**
```bash
# Primary role: Production automation hub
DOMAIN: strangematic.com
PORT: 5678 (production)
DATABASE: strangematic_n8n_prod
RESOURCES: 8GB RAM allocation, 4 CPU cores
```

**Workflow:**
```powershell
# Daily production operations
git checkout main
.\scripts\deploy-production.ps1

# Monitor production
pm2 logs strangematic-prod
pm2 monit
```

### Development Machines (Các máy khác)

**Configuration:**
```bash
# Primary role: Feature development và testing
DOMAIN: localhost
PORT: 5679 (development)
DATABASE: strangematic_n8n_dev  
RESOURCES: Conservative allocation
```

**Workflow:**
```powershell
# Development work
git checkout develop
.\scripts\switch-development.ps1

# Feature development
git checkout -b feature/new-automation
# ... develop ...
git push origin feature/new-automation
```

---

## 🔧 Environment Variables Guide

### Critical Settings to Update

**📁 environments/.env.production:**
```bash
# 🔐 Security (CRITICAL - MUST CHANGE)
DB_POSTGRESDB_PASSWORD=your_actual_production_password
N8N_JWT_SECRET=generate_256_char_secret_here
N8N_ENCRYPTION_KEY=generate_encryption_key_here

# 🤖 API Keys (Cost optimization)
YESCALE_API_KEY=your_yescale_production_key
OPENAI_API_KEY=your_openai_fallback_key
CLAUDE_API_KEY=your_claude_fallback_key

# 💰 Cost Controls
MAX_DAILY_COST_USD=50
MAX_WORKFLOW_COST_USD=5
```

**📁 environments/.env.development:**
```bash
# 🔐 Security (Development - less critical)
DB_POSTGRESDB_PASSWORD=simple_dev_password
N8N_JWT_SECRET=dev_jwt_secret
N8N_ENCRYPTION_KEY=dev_encryption_key

# 🤖 API Keys (Development - limited usage)
YESCALE_API_KEY=your_yescale_dev_key
OPENAI_API_KEY=limited_dev_openai_key

# 💰 Cost Controls (Stricter cho development)
MAX_DAILY_COST_USD=10
MAX_WORKFLOW_COST_USD=1
```

---

## 🚀 Deployment Procedures

### Production Deployment Checklist

```markdown
✅ [ ] Git working directory clean
✅ [ ] All changes committed to develop
✅ [ ] Development testing completed
✅ [ ] Environment variables updated
✅ [ ] Database migrations prepared
✅ [ ] Backup verified available
✅ [ ] Cloudflare Tunnel operational
✅ [ ] Resource monitoring ready
```

**Deploy command:**
```powershell
.\scripts\deploy-production.ps1
```

### Development Setup Checklist

```markdown
✅ [ ] Local database running
✅ [ ] Development environment configured
✅ [ ] Port 5679 available
✅ [ ] Development API keys set
✅ [ ] Cost limits configured
✅ [ ] Debug logging enabled
```

**Setup command:**
```powershell
.\scripts\switch-development.ps1
```

---

## 📊 Monitoring & Maintenance

### Production Monitoring

```powershell
# Service status
pm2 status

# Live monitoring
pm2 monit

# View logs
pm2 logs strangematic-prod

# Restart if needed
pm2 restart strangematic-prod
```

### Development Monitoring

```powershell
# Development service status
pm2 logs strangematic-dev

# Resource usage
pm2 show strangematic-dev

# Stop development
pm2 stop strangematic-dev
```

---

## 🆘 Troubleshooting

### Common Issues

**❌ Build failures:**
```powershell
# Clean và rebuild
pnpm clean
pnpm install
pnpm run build
```

**❌ Database connection issues:**
```powershell
# Check PostgreSQL service
Get-Service postgresql*

# Verify database exists
psql -U strangematic_user -d strangematic_n8n_prod -c "\l"
```

**❌ Port conflicts:**
```powershell
# Check port usage
netstat -an | findstr "5678"
netstat -an | findstr "5679"

# Kill process if needed
taskkill /F /PID <process_id>
```

**❌ PM2 service issues:**
```powershell
# Restart PM2
pm2 kill
pm2 resurrect

# Reset PM2 configuration
pm2 delete all
pm2 start environments/ecosystem.production.config.js
```

### Emergency Recovery

**🚨 Restore từ backup:**
```powershell
# Switch to backup branch
git checkout production-backup-2025-07-30-1627
git checkout -b emergency-restore
# Deploy emergency restore...
```

**🚨 Database restore:**
```sql
-- Backup current database first
pg_dump strangematic_n8n_prod > backup_before_restore.sql

-- Restore từ backup
psql strangematic_n8n_prod < your_backup_file.sql
```

---

## 💡 Best Practices

### Development Best Practices

- ✅ **Always work on feature branches** (never develop directly on main/develop)
- ✅ **Test thoroughly in development** trước khi merge to develop
- ✅ **Use descriptive commit messages** (`feat:`, `fix:`, `docs:`, etc.)
- ✅ **Keep commits atomic** (one logical change per commit)
- ✅ **Pull latest changes** trước khi start new features

### Production Best Practices

- ✅ **Monitor resource usage** (CPU/RAM limits cho Dell OptiPlex 3060)
- ✅ **Regular backups** của database và configurations
- ✅ **Test deployment** trong development environment first
- ✅ **Monitor costs** (YEScale API usage và fallback APIs)
- ✅ **Health checks** (PM2 monitoring, Cloudflare Tunnel status)

### Security Best Practices

- ✅ **Never commit .env files** (use templates only)
- ✅ **Use strong passwords** cho production database
- ✅ **Rotate API keys** regularly
- ✅ **Monitor access logs** cho unusual activity
- ✅ **Keep dependencies updated** với security patches

---

## 📞 Quick Reference

### Essential Commands

```powershell
# Production deployment
.\scripts\deploy-production.ps1

# Development switch
.\scripts\switch-development.ps1

# Git status check
git status
git branch -a

# Service management
pm2 status
pm2 logs strangematic-prod
pm2 restart strangematic-prod

# Environment check
cat environments/.env.production | grep -v PASSWORD
```

### Important URLs

- 🌐 **Production:** https://app.strangematic.com
- 🔗 **Production Webhooks:** https://api.strangematic.com
- 🔧 **Development:** http://localhost:5679
- 📊 **PM2 Monitoring:** `pm2 monit`

---

## 🎯 Next Steps

1. **Setup environment files** với your actual configurations
2. **Test development workflow** với simple feature
3. **Deploy to production** và verify functionality
4. **Monitor performance** và adjust resource allocation
5. **Setup regular backup schedule** cho data protection

---

**🚀 Enjoy your new professional n8n workflow system!**

*Optimized cho Dell OptiPlex 3060 với enterprise-grade development practices cho strangematic.com automation hub.*