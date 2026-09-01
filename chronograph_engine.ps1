# ==============================================================================
# INTEGRATED CHRONOGRAPH, KURAMOTO ORDER PARAMETER & MARKOV-MERKLE ENGINE
# ==============================================================================
$ErrorActionPreference = "Stop"
Push-Location "C:\RobdoeDeepSeekN-V3"

$hosts = @("time.google.com", "8.8.8.8", "8.8.4.4", "google.com", "1.1.1.1", "9.9.9.9")
$N = $hosts.Count
$baseFreq = 0.05208333
$periodSec = 1.0 / $baseFreq
$K = 3.5

# SHA256 Node Hashing Function for Merkle Root
function Get-NodeHash ([string]$inputStr) {
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    $bytes  = [System.Text.Encoding]::UTF8.GetBytes($inputStr)
    $hash   = $hasher.ComputeHash($bytes)
    return [System.BitConverter]::ToString($hash).Replace("-", "").Substring(0, 16)
}

Write-Host "=== [ROBDOE CHRONOGRAPH & MARKOV-MERKLE ENGINE INITIALIZED] ===" -ForegroundColor Green
Write-Host "[+] Phase Lock      : 0.052 Hz Harmonic Sync (~50.2 Arcsec/ms)" -ForegroundColor Cyan
Write-Host "[+] Active Nodes    : 6-Cylinder HCCI Dinventory OHK Matrix" -ForegroundColor Yellow
Write-Host "[+] Dynamic Markov  : P([1/0] -> [0/1]) Qi Phase Coupling" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor DarkCyan
Write-Host "  MASTER CHRONOGRAPH & KURAMOTO ORDER PARAMETER (R) ENGINE" -ForegroundColor Cyan
Write-Host "  Oscillator Freq: $baseFreq Hz | Sweep Period: $([math]::Round($periodSec, 2))s" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor DarkCyan

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$ping = New-Object System.Net.NetworkInformation.Ping
$phases = New-Object double[] $N
$latencies = New-Object double[] $N

# 1. Asynchronous Network Socket Latency Sampling
for ($i = 0; $i -lt $N; $i++) {
    try {
        $reply = $ping.Send($hosts[$i], 1200)
        $rtt = if ($reply -and $reply.Status -eq "Success") { [double]$reply.RoundtripTime } else { 80.0 }
        if ($rtt -le 0) { $rtt = 1.0 }
    } catch {
        $rtt = 120.0
    }
    $latencies[$i] = $rtt
    $phases[$i] = (($rtt % 360.0) * [Math]::PI / 180.0)
}

# 2. Chronograph Sweep, Kuramoto Coupling & Markov State Matrix
$newPhases = New-Object double[] $N
$sumCos = 0.0
$sumSin = 0.0

Write-Host "`n--- LIVE NODE ESCAPEMENT & PHASE MATRIX ---" -ForegroundColor Yellow

for ($i = 0; $i -lt $N; $i++) {
    $interaction = 0.0
    for ($j = 0; $j -lt $N; $j++) {
        $interaction += [Math]::Sin($phases[$j] - $phases[$i])
    }
    $dTheta = $baseFreq + ($latencies[$i] / 1000.0) + ($K / $N) * $interaction
    $newPhases[$i] = ($phases[$i] + $dTheta * 0.1) % (2.0 * [Math]::PI)
    
    $sumCos += [Math]::Cos($newPhases[$i])
    $sumSin += [Math]::Sin($newPhases[$i])

    $deg = [int]($newPhases[$i] * 180.0 / [Math]::PI)
    $barLength = [Math]::Max(1, [int]($deg / 10))
    $bar = "█" * $barLength
    $pad = " " * (36 - $barLength)

    Write-Host ("{0,-16} | RTT: {1,4:F0} ms | Phase: {2,5:F1}° | [{3}{4}]" -f $hosts[$i], $latencies[$i], $deg, $bar, $pad) -ForegroundColor Green
}

$sw.Stop()

# 3. Compute Coherence Order Parameter R(t)
$R = [Math]::Sqrt(($sumCos * $sumCos) + ($sumSin * $sumSin)) / $N
$meanAngleRad = [Math]::Atan2($sumSin, $sumCos)
if ($meanAngleRad -lt 0) { $meanAngleRad += 2.0 * [Math]::PI }

$rPct = [int]($R * 100)
$gaugeFilled = "■" * [int]($rPct / 4)
$gaugeEmpty  = "░" * (25 - [int]($rPct / 4))
$color = if ($R -gt 0.7) { "Green" } elseif ($R -gt 0.4) { "Yellow" } else { "Red" }

# 4. Qi Phase & Markov State Dynamics
$t = (Get-Date).Millisecond / 1000.0
$phase = ([Math]::Sin(2 * [Math]::PI * $baseFreq * $t) + 1.0) / 2.0
$qiLevel = [int][Math]::Floor($phase * 72)
$pTrans = [Math]::Round(($phase * 0.8) + 0.1, 4)
$currentState = if ($qiLevel % 2 -eq 0) { "1/0" } else { "0/1" }

# 5. Platonic Elements (H-O-N-C) -> Merkle Leaf & Root Generation
$leafH = Get-NodeHash "H:1.008|Phase:$([Math]::Round($phase, 4))"
$leafO = Get-NodeHash "O:15.999|R:$([Math]::Round($R, 4))"
$leafN = Get-NodeHash "N:14.007|Qi:$qiLevel"
$leafC = Get-NodeHash "C:12.011|Markov:$currentState|Ptrans:$pTrans"

$branchHO = Get-NodeHash ($leafH + $leafO)
$branchNC = Get-NodeHash ($leafN + $leafC)
$merkleRoot = Get-NodeHash ($branchHO + $branchNC)

# Telemetry Display
Write-Host "`n--------------------------------------------------------------------------------" -ForegroundColor DarkCyan
Write-Host ("ORDER PARAMETER R(t) : {0,6:F4}  [{1}{2}] ({3}%)" -f $R, $gaugeFilled, $gaugeEmpty, $rPct) -ForegroundColor $color
Write-Host ("MEAN CLUSTER PHASE  : {0,6:F4} rad ({1,5:F1}°)" -f $meanAngleRad, ($meanAngleRad * 180.0 / [Math]::PI)) -ForegroundColor Cyan
Write-Host ("MARKOV STATE        : [{0}] (P_trans: {1}) | Qi Bucket: {2}/72" -f $currentState, $pTrans, $qiLevel) -ForegroundColor Yellow
Write-Host ("MERKLE TREE ROOT    : {0}" -f $merkleRoot) -ForegroundColor Cyan
Write-Host ("TOTAL SWEEP TIME    : {0:F3} ms" -f $sw.Elapsed.TotalMilliseconds) -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor DarkCyan

# 6. Automatic Git Commit
git add chronograph_engine.ps1
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
git commit -m "feat(core): integrate order parameter R, Markov matrix and Merkle root [$timestamp]" --quiet
Write-Host "`n[✓] Script updated and committed to Git." -ForegroundColor Green

Pop-Location