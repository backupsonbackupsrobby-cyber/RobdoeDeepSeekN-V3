# ==============================================================================
# POWERSHELL 5.1 CHRONOGRAPHIC TIMEPIECE & ESCAPEMENT ENGINE
# Pure .NET System.Diagnostics.Stopwatch & High-Resolution Ticks
# ==============================================================================
$ErrorActionPreference = "Stop"

# Master Balance Wheel Escapement (0.05208333 Hz = 19.20s full sweep)
$targetFreqHz = 0.05208333
$periodSec    = 1.0 / $targetFreqHz

Write-Host "================================================================================" -ForegroundColor DarkYellow
Write-Host "  MASTER CHRONOGRAPH ESCAPEMENT ENGINE (PS 5.1 NATIVE)" -ForegroundColor Yellow
Write-Host "  Oscillator Freq: $targetFreqHz Hz | Full Dial Period: $([math]::Round($periodSec, 4))s" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor DarkYellow

# Start High-Precision Hardware Chronograph Counter
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$nodes = @("time.google.com", "8.8.8.8", "8.8.4.4", "google.com")
$ping  = New-Object System.Net.NetworkInformation.Ping

Write-Host "`n[CHRONO SWEEP IN PROGRESS...]" -ForegroundColor Cyan

foreach ($node in $nodes) {
    $startMarkMs = $sw.Elapsed.TotalMilliseconds
    
    try {
        $reply = $ping.Send($node, 1000)
        $rtt = if ($reply -and $reply.Status -eq "Success") { $reply.RoundtripTime } else { 100.0 }
    } catch {
        $rtt = 150.0
    }
    
    $endMarkMs = $sw.Elapsed.TotalMilliseconds

    # Chronographic Dial Sweep Angle (0° to 360°) and Radians Phase
    $elapsedSec   = $sw.Elapsed.TotalSeconds
    $phaseRad     = (2.0 * [Math]::PI * ($elapsedSec % $periodSec) / $periodSec)
    $phaseDegrees = ($phaseRad * 180.0 / [Math]::PI)

    # Balance wheel pulse coupling derived from network tick latency
    $pulseOffsetRad = (($rtt % 1000.0) / 1000.0) * 2.0 * [Math]::PI
    $syncedPhaseRad = ($phaseRad + $pulseOffsetRad) % (2.0 * [Math]::PI)

    $line = [string]::Format(
        "{0,-18} | Escapement Mark: {1,7:F2}ms | RTT Pulse: {2,4:F0}ms | Hand Pos: {3,6:F1}° | Phase: {4,6:F4} rad",
        $node, $endMarkMs, $rtt, $phaseDegrees, $syncedPhaseRad
    )
    Write-Host $line -ForegroundColor Green
}

$sw.Stop()
Write-Host "`n================================================================================" -ForegroundColor DarkYellow
Write-Host "  CHRONOGRAPH SWEEP COMPLETE | Total Elapsed: $([math]::Round($sw.Elapsed.TotalMilliseconds, 3)) ms" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor DarkYellow
