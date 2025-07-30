# =================================================================
# Production Deployment Script cho strangematic.com Hub
# =================================================================

Write-Host "🚀 Deploying to Production - strangematic.com Hub" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Change to repository directory
Set-Location "D:\Github\n8n-tp"

# Check current git status
Write-Host "📋 Checking Git Status..." -ForegroundColor Yellow
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "❌ Git working directory is not clean. Please commit changes first." -ForegroundColor Red
    Write-Host $gitStatus
    exit 1
}

# Switch to main branch
Write-Host "🔄 Switching to main branch..." -ForegroundColor Yellow
git checkout main
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to checkout main branch" -ForegroundColor Red
    exit 1
}

# Pull latest changes
Write-Host "⬇️ Pulling latest changes..." -ForegroundColor Yellow
git pull origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to pull latest changes" -ForegroundColor Red
    exit 1
}

# Install dependencies
Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
pnpm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    exit 1
}

# Build project
Write-Host "🔨 Building project..." -ForegroundColor Yellow
pnpm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}

# Stop existing production service
Write-Host "⏹️ Stopping existing production service..." -ForegroundColor Yellow
pm2 stop strangematic-prod 2>$null

# Start production service
Write-Host "▶️ Starting production service..." -ForegroundColor Yellow
pm2 start ./environments/ecosystem.production.config.js
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start production service" -ForegroundColor Red
    exit 1
}

# Save PM2 configuration
pm2 save

# Check service status
Write-Host "📊 Service Status:" -ForegroundColor Yellow
pm2 status

Write-Host "✅ Production deployment completed successfully!" -ForegroundColor Green
Write-Host "🌐 Access: https://app.strangematic.com" -ForegroundColor Cyan
Write-Host "🔗 Webhooks: https://api.strangematic.com" -ForegroundColor Cyan