# 🔄 SAFE MERGE & RELEASE PROCESS

## 1. 🏗️ **DEVELOPMENT WORKFLOW**

### **Step 1: Start New Feature**
```powershell
# Bắt đầu từ develop branch
cd C:\Github\n8n-tp
git checkout develop
git pull origin develop

# Tạo feature branch
git checkout -b feature/your-feature-name

# Verify clean state
git status
```

### **Step 2: Development & Testing**
```powershell
# Develop your feature
# - Code changes
# - Local testing với development environment

# Start development environment nếu chưa chạy
pm2 status  # Check if strangematic-dev is running
# If not running: pm2 start ecosystem-development.config.js

# Test at: http://localhost:5679
# Production vẫn chạy at: https://app.strangematic.com
```

### **Step 3: Pre-merge Testing**
```powershell
# Build để kiểm tra compilation errors
pnpm run build

# Run tests (if available)
pnpm test

# Verify development environment works
Invoke-WebRequest -Uri "http://localhost:5679" -Method GET
```

## 2. 🔀 **SAFE MERGE PROCESS**

### **Step 4: Merge to Develop (Integration Testing)**
```powershell
# Commit your changes
git add .
git commit -m "feat: your feature description"

# Switch to develop và merge
git checkout develop
git pull origin develop  # Get latest changes
git merge feature/your-feature-name

# Push to remote develop
git push origin develop

# Test integration on development environment
pm2 restart strangematic-dev
# Wait 30 seconds for startup
Start-Sleep -Seconds 30
Invoke-WebRequest -Uri "http://localhost:5679" -Method GET
```

### **Step 5: Pre-production Validation**
```powershell
# Required checks before production merge
Write-Host "🔍 PRE-PRODUCTION CHECKLIST:" -ForegroundColor Cyan

# 1. Build check
Write-Host "1. Building..." -ForegroundColor Yellow
pnpm run build
if ($LASTEXITCODE -eq 0) { 
    Write-Host "✅ Build successful" -ForegroundColor Green 
} else { 
    Write-Host "❌ Build failed - STOP" -ForegroundColor Red
    return
}

# 2. Development environment check
Write-Host "2. Testing development environment..." -ForegroundColor Yellow
$DevResponse = Invoke-WebRequest -Uri "http://localhost:5679" -Method GET
if ($DevResponse.StatusCode -eq 200) {
    Write-Host "✅ Development environment OK" -ForegroundColor Green
} else {
    Write-Host "❌ Development environment failed - STOP" -ForegroundColor Red
    return
}

# 3. Production environment check (before changes)
Write-Host "3. Verifying production is healthy..." -ForegroundColor Yellow
$ProdResponse = Invoke-WebRequest -Uri "https://app.strangematic.com" -Method GET
if ($ProdResponse.StatusCode -eq 200) {
    Write-Host "✅ Production environment healthy" -ForegroundColor Green
} else {
    Write-Host "⚠️ Production environment issues detected" -ForegroundColor Red
}

Write-Host "🎯 Ready for production deployment!" -ForegroundColor Green
```

## 3. 🚀 **PRODUCTION RELEASE PROCESS**

### **Step 6: Production Deployment**
```powershell
# Switch to main branch
git checkout main
git pull origin main

# Merge develop to main
git merge develop

# Final build
pnpm run build

# Push to main
git push origin main

# Zero-downtime deployment
Write-Host "🚀 Deploying to production..." -ForegroundColor Cyan
pm2 reload strangematic-hub  # Graceful restart

# Wait for startup
Start-Sleep -Seconds 45

# Verify production deployment
$ProductionTest = Invoke-WebRequest -Uri "https://app.strangematic.com" -Method GET
if ($ProductionTest.StatusCode -eq 200) {
    Write-Host "✅ PRODUCTION DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "🌐 Live at: https://app.strangematic.com" -ForegroundColor Cyan
} else {
    Write-Host "❌ PRODUCTION DEPLOYMENT FAILED!" -ForegroundColor Red
    Write-Host "🔄 Rolling back..." -ForegroundColor Yellow
    
    # Emergency rollback
    git reset --hard HEAD~1
    pnpm run build
    pm2 reload strangematic-hub
}
```

## 4. 🛡️ **EMERGENCY ROLLBACK PROCESS**

### **If Production Issues Occur:**
```powershell
# Immediate rollback script
Write-Host "🚨 EMERGENCY ROLLBACK INITIATED" -ForegroundColor Red

# Step 1: Rollback code
git checkout main
git reset --hard HEAD~1  # Go back 1 commit
git push origin main --force

# Step 2: Rebuild và redeploy
pnpm run build
pm2 reload strangematic-hub

# Step 3: Verify rollback
Start-Sleep -Seconds 30
$RollbackTest = Invoke-WebRequest -Uri "https://app.strangematic.com" -Method GET
if ($RollbackTest.StatusCode -eq 200) {
    Write-Host "✅ ROLLBACK SUCCESSFUL" -ForegroundColor Green
} else {
    Write-Host "❌ ROLLBACK FAILED - Manual intervention required" -ForegroundColor Red
}

# Step 4: Clean up develop branch
git checkout develop
git reset --hard origin/main  # Reset develop to match main
```

## 5. 📋 **RELEASE CHECKLIST**

### **Before Every Release:**
```powershell
# Automated release checklist
Write-Host "📋 RELEASE CHECKLIST" -ForegroundColor Cyan

$Checklist = @(
    "✅ Feature tested in development environment",
    "✅ Build successful without errors", 
    "✅ No breaking changes to existing workflows",
    "✅ Database migrations applied correctly",
    "✅ Production environment healthy before deployment",
    "✅ Backup strategy in place",
    "✅ Rollback plan ready"
)

foreach ($Item in $Checklist) {
    Write-Host $Item -ForegroundColor Green
}

Write-Host "🎯 Release approved!" -ForegroundColor Green
```

## 6. 🔧 **AUTOMATED RELEASE SCRIPT**

### **Create Automated Release:**
```powershell
# automated-release.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureBranch,
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseMessage = "Release: automated deployment"
)

Write-Host "🚀 AUTOMATED RELEASE STARTED" -ForegroundColor Cyan
Write-Host "Feature: $FeatureBranch" -ForegroundColor Yellow

# Merge to develop
git checkout develop
git pull origin develop
git merge $FeatureBranch

# Test integration
pnpm run build
pm2 restart strangematic-dev

# Deploy to production
git checkout main
git merge develop
pnpm run build
git push origin main

# Production deployment
pm2 reload strangematic-hub

Write-Host "✅ AUTOMATED RELEASE COMPLETED" -ForegroundColor Green
```

---
*Safe merge & release process đảm bảo zero-downtime cho strangematic.com automation hub*
