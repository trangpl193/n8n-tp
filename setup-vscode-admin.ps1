# PowerShell Admin Profile Setup for VS Code
# This script will help setup admin terminal in VS Code

Write-Host "Setting up VS Code PowerShell Admin Profile..." -ForegroundColor Cyan

# Create VS Code settings directory if not exists
$vscodeSettingsPath = "$env:APPDATA\Code\User"
if (-not (Test-Path $vscodeSettingsPath)) {
    New-Item -Path $vscodeSettingsPath -ItemType Directory -Force
}

# VS Code settings.json configuration
$settingsPath = "$vscodeSettingsPath\settings.json"

# Read existing settings or create new
$settings = @{}
if (Test-Path $settingsPath) {
    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable
    }
    catch {
        Write-Host "Creating new settings.json..." -ForegroundColor Yellow
        $settings = @{}
    }
}

# Add terminal profiles
if (-not $settings.ContainsKey("terminal.integrated.profiles.windows")) {
    $settings["terminal.integrated.profiles.windows"] = @{}
}

# Add PowerShell Admin profile
$settings["terminal.integrated.profiles.windows"]["PowerShell Admin"] = @{
    "path" = "powershell.exe"
    "args" = @("-NoExit", "-Command", "& {Start-Process powershell -ArgumentList '-NoExit','-NoProfile','-Command','Set-Location ''${workspaceFolder}''' -Verb RunAs}")
}

# Add Command Prompt Admin profile
$settings["terminal.integrated.profiles.windows"]["Command Prompt Admin"] = @{
    "path" = "cmd.exe"
    "args" = @("/k", "powershell", "-Command", "Start-Process cmd -ArgumentList '/k cd /d ${workspaceFolder}' -Verb RunAs")
}

# Set default terminal to PowerShell Admin
$settings["terminal.integrated.defaultProfile.windows"] = "PowerShell Admin"

# Save settings
$settingsJson = $settings | ConvertTo-Json -Depth 10
Set-Content -Path $settingsPath -Value $settingsJson -Encoding UTF8

Write-Host "VS Code settings updated!" -ForegroundColor Green
Write-Host "Restart VS Code to apply changes." -ForegroundColor Yellow
