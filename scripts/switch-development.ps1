# =================================================================
# Development Environment Switch Script
# =================================================================

Write-Host "🔧 Switching to Development Environment" -ForegroundColor Blue
Write-Host "=====================================" -ForegroundColor Blue

# Change to repository directory
Set-Location "D:\Github\n8n-tp"

# Check current git status
Write-Host "📋 Checking Git Status..." -ForegroundColor Yellow
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "⚠️ Git working directory has uncommitted changes:" -ForegroundColor Yellow
    Write-Host $gitStatus
    $response = Read-Host "Continue anyway? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "❌ Operation cancelled" -ForegroundColor Red
        exit 1
    }
}

# Switch to develop branch
Write-Host "🔄 Switching to develop branch..." -ForegroundColor Yellow
git checkout develop
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to checkout develop branch" -ForegroundColor Red
    exit 1
}

# Pull latest changes
Write-Host "⬇️ Pulling latest changes..." -ForegroundColor Yellow
git pull origin develop
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

# Stop existing development service
Write-Host "⏹️ Stopping existing development service..." -ForegroundColor Yellow
pm2 stop strangematic-dev 2>$null

# Start development service
Write-Host "▶️ Starting development service..." -ForegroundColor Yellow
pm2 start ./environments/ecosystem.development.config.js
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start development service" -ForegroundColor Red
    exit 1
}

# Save PM2 configuration
pm2 save

# Check service status
Write-Host "📊 Service Status:" -ForegroundColor Yellow
pm2 status

Write-Host "✅ Development environment ready!" -ForegroundColor Green
Write-Host "🌐 Access: http://localhost:5679" -ForegroundColor Cyan
Write-Host "🔗 Webhooks: http://localhost:5679" -ForegroundColor Cyan
Write-Host "📝 Logs: pm2 logs strangematic-dev" -ForegroundColor Cyan
