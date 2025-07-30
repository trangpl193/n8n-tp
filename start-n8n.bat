@echo off
cd /d C:\Github\n8n-tp

echo Loading environment variables...

set NODE_ENV=production
set N8N_EDITOR_BASE_URL=https://app.strangematic.com
set WEBHOOK_URL=https://api.strangematic.com
set N8N_HOST=app.strangematic.com
set N8N_PROTOCOL=https
set N8N_PORT=5678
set DB_TYPE=postgresdb
set DB_POSTGRESDB_HOST=localhost
set DB_POSTGRESDB_PORT=5432
set DB_POSTGRESDB_DATABASE=strangematic_n8n
set DB_POSTGRESDB_USER=strangematic_user
set DB_POSTGRESDB_PASSWORD=strangematic_2024_secure!
set N8N_SECURE_COOKIE=true
set N8N_LISTEN_ADDRESS=0.0.0.0
set N8N_PATH=/
set N8N_BASIC_AUTH_ACTIVE=false

echo Starting n8n on port 5678...
echo Database: %DB_POSTGRESDB_DATABASE%@%DB_POSTGRESDB_HOST%:%DB_POSTGRESDB_PORT%

node packages/cli/bin/n8n
pause
