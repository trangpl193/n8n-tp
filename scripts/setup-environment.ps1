# =================================================================
# Initial Environment Setup Script
# =================================================================

Write-Host "🛠️ Setting up n8n Environment - strangematic.com Hub" -ForegroundColor Magenta
Write-Host "=================================================" -ForegroundColor Magenta

# Change to repository directory
Set-Location "D:\Github\n8n-tp"

# Create necessary directories
Write-Host "📁 Creating directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "logs" | Out-Null
New-Item -ItemType Directory -Force -Path "C:\n8n-data" | Out-Null
New-Item -ItemType Directory -Force -Path "C:\n8n-dev-data" | Out-Null

# Create .env files from templates
Write-Host "⚙️ Setting up environment files..." -ForegroundColor Yellow

if (-not (Test-Path "./environments/.env.production")) {
    Write-Host "📝 Creating .env.production from template..." -ForegroundColor Yellow
    Copy-Item "./environments/env-production-template.txt" "./environments/.env.production"
    Write-Host "⚠️ IMPORTANT: Edit ./environments/.env.production với your actual configuration!" -ForegroundColor Red
}

if (-not (Test-Path "./environments/.env.development")) {
    Write-Host "📝 Creating .env.development from template..." -ForegroundColor Yellow
    Copy-Item "./environments/env-development-template.txt" "./environments/.env.development"
    Write-Host "⚠️ IMPORTANT: Edit ./environments/.env.development với your actual configuration!" -ForegroundColor Red
}

# Install global dependencies
Write-Host "📦 Installing global dependencies..." -ForegroundColor Yellow
npm install -g pm2 pnpm
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install global dependencies" -ForegroundColor Red
    exit 1
}

# Install project dependencies
Write-Host "📦 Installing project dependencies..." -ForegroundColor Yellow
pnpm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install project dependencies" -ForegroundColor Red
    exit 1
}

# Build project
Write-Host "🔨 Building project..." -ForegroundColor Yellow
pnpm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}

# Setup PM2 startup
Write-Host "🔧 Setting up PM2 startup..." -ForegroundColor Yellow
pm2 startup
pm2 save

Write-Host "✅ Environment setup completed!" -ForegroundColor Green
Write-Host "" -ForegroundColor White
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Edit ./environments/.env.production với your production settings" -ForegroundColor White
Write-Host "2. Edit ./environments/.env.development với your development settings" -ForegroundColor White
Write-Host "3. Setup PostgreSQL databases:" -ForegroundColor White
Write-Host "   - strangematic_n8n_prod (production)" -ForegroundColor White
Write-Host "   - strangematic_n8n_dev (development)" -ForegroundColor White
Write-Host "4. Run: .\scripts\deploy-production.ps1 để start production" -ForegroundColor White
Write-Host "5. Run: .\scripts\switch-development.ps1 để start development" -ForegroundColor White