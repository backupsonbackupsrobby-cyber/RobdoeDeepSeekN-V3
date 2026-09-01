# ==============================================================================
# ENTERPRISE SOVEREIGN MOE MASTER ORCHESTRATOR (PS 5.1 HARDENED)
# ==============================================================================
[CmdletBinding()]
param(
    [ValidateSet("run", "status", "logs", "crew")]
    [string]$Action = "run",
    
    [string]$RootDir = $PSScriptRoot
)

# 1. Fallback & Path Resolution
if (-not $RootDir -or -not (Test-Path $RootDir)) {
    $RootDir = "C:\RobdoeDeepSeekN-V3"
}

$InferenceDir = Join-Path $RootDir "inference"
$LogsDir      = Join-Path $RootDir "logs"
$LogFile      = Join-Path $LogsDir "enterprise_moe.log"

# Enforce Air-Gap Telemetry Lockdown across all invocations
$env:CREWAI_TELEMETRY_OPT_OUT = "true"
$env:OTEL_SDK_DISABLED        = "true"

switch ($Action) {
    "run" {
        Write-Host "==> [MASTER] Launching Enterprise MoE Kuramoto-Newton Daemon..." -ForegroundColor Cyan
        
        if (-not (Test-Path $LogsDir)) {
            New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
        }

        $DaemonScript = Join-Path $InferenceDir "enterprise_moe_daemon.py"
        if (-not (Test-Path $DaemonScript)) {
            Write-Host "[ERROR] Target daemon entry point missing: $DaemonScript" -ForegroundColor Red
            return
        }

        Push-Location $RootDir
        try {
            python $DaemonScript
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[ERROR] Daemon exited with non-zero status code: $LASTEXITCODE" -ForegroundColor Red
            }
        }
        finally {
            Pop-Location
        }
    }

    "crew" {
        Write-Host "==> [MASTER] Invoking Enterprise CrewAI Multi-Agent Orchestrator..." -ForegroundColor Cyan
        Push-Location $RootDir
        try {
            python ".\crew_git_orchestrator.py"
        }
        finally {
            Pop-Location
        }
    }

    "status" {
        Write-Host "==> [MASTER] Checking Enterprise Repository Matrix..." -ForegroundColor Cyan
        Push-Location $RootDir
        try {
            Write-Host "[+] Working Directory: $RootDir" -ForegroundColor Gray
            Write-Host "[+] Active Branch     : " -NoNewline -ForegroundColor Gray
            git branch --show-current
            Write-Host "`n[+] Git Status Summary:" -ForegroundColor Gray
            git status --short
        }
        finally {
            Pop-Location
        }
    }

    "logs" {
        Write-Host "==> [MASTER] Tailing Enterprise Engine Logs..." -ForegroundColor Cyan
        if (Test-Path $LogFile) {
            Get-Content -Path $LogFile -Tail 50 -Wait
        } else {
            Write-Host "[WARN] Log file not found at $LogFile. Execute daemon first." -ForegroundColor Yellow
        }
    }
}