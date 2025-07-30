# =================================================================
# Git Branches Cleanup Script
# =================================================================

Write-Host "🧹 Cleaning up old Git branches" -ForegroundColor DarkYellow
Write-Host "===============================" -ForegroundColor DarkYellow

# Change to repository directory
Set-Location "D:\Github\n8n-tp"

# List current branches
Write-Host "📋 Current branches:" -ForegroundColor Yellow
git branch -a

Write-Host ""
Write-Host "🗑️ Branches to be deleted (old/unused):" -ForegroundColor Red

# List of old branches to delete (customize này based on your needs)
$branchesToDelete = @(
    "analysis-phase-completed",
    "analysis/n8n-project-assessment", 
    "workflow-development-branch",
    "n8n-development-new-device"  # Original production branch (now backed up)
)

foreach ($branch in $branchesToDelete) {
    Write-Host "  - $branch" -ForegroundColor Red
}

Write-Host ""
$confirm = Read-Host "⚠️ Delete these branches? This action cannot be undone. (y/N)"

if ($confirm -eq "y" -or $confirm -eq "Y") {
    # Switch to main branch first
    Write-Host "🔄 Switching to main branch..." -ForegroundColor Yellow
    git checkout main
    
    # Delete local branches
    Write-Host "🗑️ Deleting local branches..." -ForegroundColor Yellow
    foreach ($branch in $branchesToDelete) {
        Write-Host "Deleting local branch: $branch" -ForegroundColor DarkYellow
        git branch -D $branch 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Deleted local: $branch" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Branch not found locally: $branch" -ForegroundColor Yellow
        }
    }
    
    # Delete remote branches (ask for confirmation)
    Write-Host ""
    $confirmRemote = Read-Host "🌐 Also delete remote branches? (y/N)"
    
    if ($confirmRemote -eq "y" -or $confirmRemote -eq "Y") {
        Write-Host "🗑️ Deleting remote branches..." -ForegroundColor Yellow
        foreach ($branch in $branchesToDelete) {
            Write-Host "Deleting remote branch: origin/$branch" -ForegroundColor DarkYellow
            git push origin --delete $branch 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Deleted remote: origin/$branch" -ForegroundColor Green
            } else {
                Write-Host "⚠️ Branch not found on remote: $branch" -ForegroundColor Yellow
            }
        }
    }
    
    # Cleanup tracking branches
    Write-Host "🧹 Cleaning up tracking branches..." -ForegroundColor Yellow
    git remote prune origin
    
    Write-Host "✅ Branch cleanup completed!" -ForegroundColor Green
} else {
    Write-Host "❌ Branch cleanup cancelled" -ForegroundColor Red
}

Write-Host ""
Write-Host "📋 Remaining branches:" -ForegroundColor Yellow
git branch -a