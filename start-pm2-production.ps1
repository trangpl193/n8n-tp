# PM2 Start Script with Domain Configuration
# Requires Administrative Privileges

Write-Host "Starting PM2 with Strangematic Domain Configuration..." -ForegroundColor Green

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "❌ Script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "🔄 Restarting with admin privileges..." -ForegroundColor Yellow
    
    # Restart script as admin
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptPath`"" -Verb RunAs
    exit
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green

# Set environment variables for the session
$env:NODE_ENV = "production"
$env:N8N_EDITOR_BASE_URL = "https://app.strangematic.com"
$env:WEBHOOK_URL = "https://api.strangematic.com"
$env:N8N_HOST = "app.strangematic.com"
$env:N8N_PROTOCOL = "https"
$env:N8N_PORT = "5678"
$env:DB_TYPE = "postgresdb"
$env:DB_POSTGRESDB_HOST = "localhost"
$env:DB_POSTGRESDB_PORT = "5432"
$env:DB_POSTGRESDB_DATABASE = "strangematic_n8n"
$env:DB_POSTGRESDB_USER = "strangematic_user"
$env:DB_POSTGRESDB_PASSWORD = "postgres123"

Write-Host "Environment configured for domain: app.strangematic.com" -ForegroundColor Cyan

# Try to kill existing PM2 daemon
try {
    pm2 kill
    Write-Host "Killed existing PM2 daemon" -ForegroundColor Yellow
} catch {
    Write-Host "No existing PM2 daemon found" -ForegroundColor Yellow
}

# Start with ecosystem config
try {
    pm2 start ecosystem-stable.config.js --env production
    Write-Host "Started n8n with PM2 ecosystem config" -ForegroundColor Green
    pm2 status
} catch {
    Write-Host "PM2 failed, starting n8n directly..." -ForegroundColor Yellow
    Set-Location "packages\cli\bin"
    .\n8n start
}
