# n8n Startup Script for strangematic.com
# Load environment variables from .env file

# Set basic required vars first
$env:NODE_ENV = "production"
$env:N8N_PORT = "5678"
$env:N8N_LISTEN_ADDRESS = "0.0.0.0"
$env:N8N_HOST = "0.0.0.0"
$env:N8N_PROTOCOL = "http"
$env:N8N_EDITOR_BASE_URL = "https://app.strangematic.com"
$env:WEBHOOK_URL = "https://api.strangematic.com"
$env:N8N_PATH = "/"
$env:N8N_BASIC_AUTH_ACTIVE = "false"

# PostgreSQL Configuration - using corrected password
$env:DB_TYPE = "postgresdb"
$env:DB_POSTGRESDB_HOST = "localhost"
$env:DB_POSTGRESDB_PORT = "5432"
$env:DB_POSTGRESDB_DATABASE = "strangematic_n8n"
$env:DB_POSTGRESDB_USER = "strangematic_user"
$env:DB_POSTGRESDB_PASSWORD = "postgres123"

Write-Host "Using PostgreSQL database: $env:DB_POSTGRESDB_DATABASE"

# Navigate to n8n directory
Set-Location "C:\Github\n8n-tp"

# Start n8n
Write-Host "Starting n8n on port 5678..."
node packages/cli/bin/n8n
