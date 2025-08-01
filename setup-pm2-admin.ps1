# PM2 Admin Setup Script
# Chạy script này với quyền Administrator

Write-Host "PM2 Admin Setup - StrangematicHub" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "Script cần chạy với quyền Administrator!" -ForegroundColor Red
    Write-Host "Khởi động lại PowerShell với quyền Admin:" -ForegroundColor Yellow
    Write-Host "   1. Nhấn Win + X" -ForegroundColor White
    Write-Host "   2. Chọn Windows PowerShell (Admin)" -ForegroundColor White
    Write-Host "   3. Chạy lại script này" -ForegroundColor White
    exit 1
}

Write-Host "Đang chạy với quyền Administrator" -ForegroundColor Green

# Reset PM2 completely
Write-Host "`nCleaning PM2 cache and processes..." -ForegroundColor Yellow

try {
    # Kill all node processes
    Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "Stopped all node processes" -ForegroundColor Green
}
catch {
    Write-Host "Some node processes could not be stopped (may be protected)" -ForegroundColor Yellow
}

try {
    # Remove PM2 directories
    $pm2Dirs = @(
        "$env:USERPROFILE\.pm2",
        "$env:APPDATA\pm2",
        "$env:LOCALAPPDATA\pm2"
    )
    
    foreach ($dir in $pm2Dirs) {
        if (Test-Path $dir) {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Removed PM2 directory: $dir" -ForegroundColor Green
        }
    }
}
catch {
    Write-Host "Some PM2 directories could not be removed: $_" -ForegroundColor Yellow
}

# Clear n8n cache and temporary files
Write-Host "`nCleaning n8n cache..." -ForegroundColor Yellow

try {
    $n8nDirs = @(
        "$env:USERPROFILE\.n8n",
        "$env:LOCALAPPDATA\n8n",
        "$env:APPDATA\n8n"
    )
    
    foreach ($dir in $n8nDirs) {
        if (Test-Path $dir) {
            Remove-Item -Path "$dir\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Cleaned n8n cache: $dir" -ForegroundColor Green
        }
    }
}
catch {
    Write-Host "Some n8n cache could not be cleaned: $_" -ForegroundColor Yellow
}

Write-Host "`nStarting PM2 with admin privileges..." -ForegroundColor Yellow

# Test PM2
try {
    pm2 status
    Write-Host "PM2 is running successfully!" -ForegroundColor Green
}
catch {
    Write-Host "PM2 still has issues: $_" -ForegroundColor Red
    Write-Host "Try reinstalling PM2: npm install -g pm2" -ForegroundColor Yellow
}

Write-Host "`nSetup completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run: pm2 start ecosystem-stable.config.js --env production" -ForegroundColor White
Write-Host "2. Run: pm2 save" -ForegroundColor White
Write-Host "3. Test domain: https://app.strangematic.com" -ForegroundColor White
