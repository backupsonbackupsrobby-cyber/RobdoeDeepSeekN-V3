# Standalone Fork Sync Launcher
if (Test-Path ".\sync_enterprise_fork.ps1") {
    .\sync_enterprise_fork.ps1
} else {
    Write-Host "[!] sync_enterprise_fork.ps1 not found in current directory." -ForegroundColor Red
}
