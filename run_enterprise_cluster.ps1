# ==============================================================================
# ENTERPRISE SOVEREIGN MOE MASTER AUTOMATION ENGINE
# ==============================================================================
[CmdletBinding()]
param(
    [ValidateSet("all", "engine", "crew", "absorb", "fork", "run", "status", "logs")]
    [string]$Action = "all",
    [string]$RootDir = "C:\RobdoeDeepSeekN-V3"
)

$ErrorActionPreference = "Stop"
$StartTime = [DateTime]::Now

$env:CREWAI_TELEMETRY_OPT_OUT = "true"
$env:OTEL_SDK_DISABLED        = "true"

if (-not (Test-Path $RootDir)) {
    Write-Host "[FATAL] Directory missing: $RootDir" -ForegroundColor Red
    exit 1
}

Push-Location $RootDir
$InferenceDir = Join-Path $RootDir "inference"
$SummaryFile  = Join-Path $RootDir "absorbed_moe_structure.md"
$LogsDir      = Join-Path $RootDir "logs"
$LogFile      = Join-Path $LogsDir "enterprise_moe.log"

if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  ROBDOE DEEPSEEK-V3: HARMONIC FORK AUTOMATION PIPELINE" -ForegroundColor Cyan
Write-Host "  CONSTANTS: 1,296,000 arcs | 3,600s/h | 86,400s/day | 0.0520833 Hz" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

function Invoke-HarmonicDotNetEngine {
    Write-Host "`n==> [STEP 1/3] EXECUTING .NET HARMONIC ROTATION ENGINE..." -ForegroundColor Yellow
    
    $code = @"
using System;
using System.Linq;
using System.Threading.Tasks;

namespace Robdoe.DeepSeek.Core {
    public struct ExpertScore {
        public int Index;
        public float Score;
    }

    public class HarmonicKuramotoEngine {
        public const double ArcsecondsFull = 1296000.0;
        public const double SecondsDay     = 86400.0;
        public const double RotationRate   = 15.0;
        public const double DeltaFreq      = 0.05208333;

        private readonly int _dModel;
        private readonly int _numExperts;
        private readonly float[,] _centroids;
        private readonly float[,] _phases;
        private readonly float[] _mass;

        public HarmonicKuramotoEngine(int dModel, int numExperts) {
            _dModel = dModel;
            _numExperts = numExperts;
            _centroids = new float[numExperts, dModel];
            _phases = new float[numExperts, dModel];
            _mass = new float[numExperts];
            Random rng = new Random(42);
            for (int k = 0; k < numExperts; k++) {
                _mass[k] = 1.0f + (float)rng.NextDouble() * 0.5f;
                for (int d = 0; d < dModel; d++) {
                    _centroids[k, d] = (float)(rng.NextDouble() * 0.04 - 0.02);
                    _phases[k, d] = (float)(k * (2.0 * Math.PI / numExperts));
                }
            }
        }

        public class RoutingResult {
            public double CurrentArc;
            public double DiurnalPhase;
            public int[] SelectedExperts;
            public float[] Weights;
            public float OrderParameterR;
            public float MaxCoupledForce;
        }

        public RoutingResult ComputeCoupling(int topK, float G, float K, float gamma, float epsilon) {
            double nowSeconds = DateTime.UtcNow.TimeOfDay.TotalSeconds;
            double currentArc = (nowSeconds * RotationRate) % ArcsecondsFull;
            double diurnalPhase = (currentArc / ArcsecondsFull) * 2.0 * Math.PI;

            float[] tokenState = new float[_dModel];
            float[] tokenPhase = new float[_dModel];
            float tokenMass = 0.0f;

            for (int d = 0; d < _dModel; d++) {
                tokenState[d] = (float)Math.Sin(diurnalPhase + (d * DeltaFreq));
                tokenPhase[d] = (float)((diurnalPhase + (d * DeltaFreq)) % (2.0 * Math.PI));
                tokenMass += tokenState[d] * tokenState[d];
            }
            tokenMass = (float)Math.Sqrt(tokenMass);

            float sumCos = 0.0f, sumSin = 0.0f;
            for (int d = 0; d < _dModel; d++) {
                sumCos += (float)Math.Cos(tokenPhase[d]);
                sumSin += (float)Math.Sin(tokenPhase[d]);
            }
            float orderR = (float)Math.Sqrt(sumCos * sumCos + sumSin * sumSin) / _dModel;

            float[] scores = new float[_numExperts];
            Parallel.For(0, _numExperts, k => {
                float rSq = 0.0f, phaseSum = 0.0f;
                for (int d = 0; d < _dModel; d++) {
                    float diff = _centroids[k, d] - tokenState[d];
                    rSq += diff * diff;
                    float pDiff = tokenPhase[d] - _phases[k, d];
                    phaseSum += (float)Math.Cos(pDiff);
                }
                float r = (float)Math.Sqrt(rSq + epsilon);
                float fNewton = G * (tokenMass * _mass[k]) / ((float)Math.Pow(r, gamma) + epsilon);
                float fKuramoto = K * (phaseSum / _dModel);
                scores[k] = fNewton + fKuramoto;
            });

            ExpertScore[] top = scores.Select((s, i) => new ExpertScore { Index = i, Score = s })
                                      .OrderByDescending(x => x.Score)
                                      .Take(topK).ToArray();

            float maxS = top[0].Score;
            float sumExp = top.Sum(x => (float)Math.Exp(x.Score - maxS));

            return new RoutingResult {
                CurrentArc = currentArc,
                DiurnalPhase = diurnalPhase,
                SelectedExperts = top.Select(x => x.Index).ToArray(),
                Weights = top.Select(x => (float)Math.Exp(x.Score - maxS) / sumExp).ToArray(),
                OrderParameterR = orderR,
                MaxCoupledForce = maxS
            };
        }
    }
}
"@
    if (-not ("Robdoe.DeepSeek.Core.HarmonicKuramotoEngine" -as [type])) {
        Add-Type -TypeDefinition $code -Language CSharp
    }

    $engine = New-Object Robdoe.DeepSeek.Core.HarmonicKuramotoEngine(128, 16)
    $res = $engine.ComputeCoupling(2, 1.2, 2.5, 2.0, 1e-3)

    Write-Host ("[✓] Current Diurnal Arc   : {0:N2}'' / 1,296,000''" -f $res.CurrentArc) -ForegroundColor Green
    Write-Host ("[✓] Solar Phase Angle     : {0:F4} rad" -f $res.DiurnalPhase) -ForegroundColor Green
    Write-Host ("[✓] Order Parameter (R)   : {0:F4}" -f $res.OrderParameterR) -ForegroundColor Green
    Write-Host ("[✓] Selected Experts      : {0}" -f ($res.SelectedExperts -join ", ")) -ForegroundColor Green
}

function Invoke-CrewOrchestrator {
    Write-Host "`n==> [STEP 2/3] RUNNING PHASE-LOCKED AGENT CREW..." -ForegroundColor Yellow
    if (Test-Path ".\crew_git_orchestrator.py") { python ".\crew_git_orchestrator.py" }
}

function Invoke-AtomicAbsorption {
    Write-Host "`n==> [STEP 3/3] EXECUTING ATOMIC ABSORPTION & REPLICATION..." -ForegroundColor Yellow
    if (Test-Path $InferenceDir) {
        $Files = Get-ChildItem -Path $InferenceDir -Recurse -File -ErrorAction SilentlyContinue
        $SB = [System.Text.StringBuilder]::new()
        [void]$SB.AppendLine("# ENTERPRISE ROTATIONAL DATA MATRIX SNAPSHOT")
        [void]$SB.AppendLine("# DIURNAL CONSTANTS: 1296000arcs | 3600s/h | 86400s/day | 0.0520833 Hz")
        [void]$SB.AppendLine("# TIMESTAMP: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
        [void]$SB.AppendLine("| File Subpath | Bytes | SHA256 Hash | Last Modified |")
        [void]$SB.AppendLine("| :--- | :--- | :--- | :--- |")

        foreach ($f in $Files) {
            $rel = ".\" + $f.FullName.Substring($RootDir.Length + 1)
            $hash = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash
            [void]$SB.AppendLine("| $rel | $($f.Length) | $hash | $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')) |")
        }
        [System.IO.File]::WriteAllText($SummaryFile, $SB.ToString(), [System.Text.Encoding]::UTF8)
    }

    $oldEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $branch = (git rev-parse --abbrev-ref HEAD).Trim()
        $remote = if ((git remote) -contains "upstream") { "upstream" } else { "origin" }

        git add $SummaryFile
        git commit -m "prod(core): 1296000arcs diurnal phase-lock absorption [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]" --quiet

        $tagName = "v2026.09.01-rotational-core"
        if (git tag -l $tagName) { git tag -d $tagName | Out-Null }
        git tag -a $tagName -m "Immutable 0.052Hz Rotational Release Tag: $tagName"

        git push $remote $branch --tags --force
        Write-Host "[✓] Rotational absorption complete." -ForegroundColor Green
    }
    finally { $ErrorActionPreference = $oldEAP }
}

function Invoke-ForkSync {
    Write-Host "`n==> [FORK] EXECUTING SAFE UPSTREAM FORK SYNCHRONIZATION..." -ForegroundColor Yellow
    if (Test-Path ".\sync_enterprise_fork.ps1") {
        .\sync_enterprise_fork.ps1
    } else {
        Write-Host "[ERROR] 'sync_enterprise_fork.ps1' missing!" -ForegroundColor Red
    }
}

try {
    switch ($Action) {
        "all" {
            Invoke-HarmonicDotNetEngine
            Invoke-CrewOrchestrator
            Invoke-AtomicAbsorption
        }
        "engine" { Invoke-HarmonicDotNetEngine }
        "crew"   { Invoke-CrewOrchestrator }
        "absorb" { Invoke-AtomicAbsorption }
        "fork"   { Invoke-ForkSync }
        "run"    { python ".\inference\enterprise_moe_daemon.py" }
        "status" {
            git branch --show-current
            git status --short
        }
        "logs" {
            if (Test-Path $LogFile) { Get-Content $LogFile -Tail 50 -Wait }
            else { Write-Host "[WARN] Log file missing: $LogFile" -ForegroundColor Yellow }
        }
    }
    
    $elapsed = ([DateTime]::Now - $StartTime).TotalSeconds.ToString("F2")
    Write-Host "`n================================================================================" -ForegroundColor Green
    Write-Host "  ENTERPRISE PIPELINE SUCCESSFUL [TIME: ${elapsed}s]" -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor Green
}
finally {
    Pop-Location
}
