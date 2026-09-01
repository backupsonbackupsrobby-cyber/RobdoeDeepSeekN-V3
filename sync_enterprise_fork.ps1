[CmdletBinding()]
param(
    [string]$UpstreamUrl = "https://github.com/deepseek-ai/DeepSeek-V3",
    [string]$UpstreamBranch = "main",
    [string]$EnterpriseBranch = "main",
    [string]$RootDir = "C:\RobdoeDeepSeekN-V3"
)

$ErrorActionPreference = "Stop"
Write-Host "==> [FORK-GUARD] Executing Perpetual Absorption Sync Strategy..." -ForegroundColor Cyan

if (-not (Test-Path $RootDir)) {
    Write-Host "[FATAL] Workspace non-existent: $RootDir" -ForegroundColor Red
    exit 1
}

Push-Location $RootDir

try {
    # 1. Configure upstream remote
    $remotes = git remote
    if ($remotes -notcontains "upstream") {
        Write-Host "[+] Configuring upstream remote: $UpstreamUrl" -ForegroundColor Yellow
        git remote add upstream $UpstreamUrl
    }

    # 2. Preserve uncommitted local work (never delete or wipe uncommitted files)
    $dirty = git status --porcelain
    if ($dirty) {
        Write-Host "[+] Stashing uncommitted local work..." -ForegroundColor Yellow
        git stash push -m "perpetual-absorption-stash-$(Get-Date -Format 'yyyyMMdd-HHmmss')" --quiet
    }

    # 3. Fetch all upstream updates and tags
    Write-Host "[+] Fetching upstream tree ($UpstreamBranch)..." -ForegroundColor Cyan
    git fetch upstream $UpstreamBranch --tags --quiet

    # 4. Absorb upstream changes using '-X ours' strategy
    # Combines upstream updates while locking local code if conflicts occur.
    Write-Host "[+] Absorbing upstream deltas into $EnterpriseBranch..." -ForegroundColor Cyan
    git checkout $EnterpriseBranch --quiet
    
    $mergeResult = git merge "upstream/$UpstreamBranch" -X ours --no-ff -m "feat(enterprise): perpetual upstream absorption [$(Get-Date -Format 'yyyy-MM-dd')]" 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARN] Manual resolution required for binary/structural conflict. Preserving local tree..." -ForegroundColor Yellow
        git checkout --ours . 2>$null
        git add . 2>$null
        git commit -m "fix(merge): lock enterprise overrides" --quiet
        Write-Host "[✓] Conflicts locked to local enterprise version." -ForegroundColor Green
    } else {
        Write-Host "[✓] Upstream fully absorbed without collision." -ForegroundColor Green
    }

    # 5. Restore local working tree state
    if ($dirty) {
        Write-Host "[+] Restoring stashed local work..." -ForegroundColor Yellow
        git stash pop --quiet 2>$null
    }

    # 6. Replicate absorbed tree to origin with force-updated tags
    Write-Host "[+] Pushing absorbed state to origin/$EnterpriseBranch..." -ForegroundColor Cyan
    git push origin $EnterpriseBranch --quiet
    git push origin --tags --force --quiet
    Write-Host "[✓] Enterprise fork perpetually synced and absorbed!" -ForegroundColor Green
}
catch {
    Write-Host "[FATAL] Perpetual absorption failed: $_" -ForegroundColor Red
}
finally {
    Pop-Location
}
