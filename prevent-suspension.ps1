# Prevent Windows from suspending background tasks
try {
    # Set power policy to prevent background app suspension
    powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_BACKGROUND_APPS_POLICY BackgroundAppPolicy 0
    powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_BACKGROUND_APPS_POLICY BackgroundAppPolicy 0
    powercfg /SETACTIVE SCHEME_CURRENT
    Write-Host "Background app suspension disabled" -ForegroundColor Green
} catch {
    Write-Host "Could not modify power policy: " -ForegroundColor Yellow
}
