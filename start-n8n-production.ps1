# Start n8n with Production Environment Variables
# Load environment variables from .env.production

Write-Host "Loading environment variables from .env.production..." -ForegroundColor Green

# Read .env.production file and set environment variables
Get-Content .env.production | ForEach-Object {
    if ($_ -match "^([^#].*)=(.*)$") {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Item -Path "env:$name" -Value $value
        Write-Host "Set $name" -ForegroundColor Yellow
    }
}

Write-Host "Starting n8n with production configuration..." -ForegroundColor Green
Write-Host "Domain: https://app.strangematic.com" -ForegroundColor Cyan
Write-Host "Webhook URL: https://api.strangematic.com" -ForegroundColor Cyan

# Change to the correct directory and start n8n
Set-Location "packages\cli\bin"
.\n8n start
