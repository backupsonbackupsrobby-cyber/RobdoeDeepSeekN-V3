[CmdletBinding()]
param(
    [string]$RootDir = "C:\RobdoeDeepSeekN-V3",
    [string]$TagName = "v2026.09.01-rotational-core"
)

$ErrorActionPreference = "Continue"
Push-Location $RootDir

try {
    # 1. Create tag locally
    Write-Host "[+] Creating tag '$TagName'..." -ForegroundColor Cyan
    git tag -f -a $TagName -m "Immutable 0.052Hz Rotational Release Tag: $TagName"

    # 2. Push to origin (your fork)
    Write-Host "[+] Pushing tag to origin..." -ForegroundColor Cyan
    git push origin $TagName --force

    # 3. Push to upstream (if write access is granted)
    if ((git remote) -contains "upstream") {
        Write-Host "[+] Pushing tag to upstream..." -ForegroundColor Cyan
        git push upstream $TagName --force
    }
    Write-Host "[✓] Multi-remote tag push completed." -ForegroundColor Green
}
finally {
    Pop-Location
}
