# ==============================================================================
# POWERSHELL 5.1 .NET KURAMOTO NETWORK PHASE COUPLER (GOOGLE NETWORK ENDPOINTS)
# ==============================================================================
[CmdletBinding()]
param(
    [string[]]$Endpoints = @("time.google.com", "8.8.8.8", "8.8.4.4", "google.com"),
    [double]$CouplingConstant = 2.5,
    [double]$BaseFreq = 0.05208333
)

$ErrorActionPreference = "Stop"

$csharpCode = @"
using System;
using System.Collections.Generic;
using System.Net.NetworkInformation;

namespace Robdoe.Kuramoto {
    public class NetworkNodeResult {
        public string Host { get; set; }
        public double LatencyMs { get; set; }
        public double NaturalFreq { get; set; }
        public double InitialPhase { get; set; }
        public double SynchronizedPhase { get; set; }
        public bool IsAlive { get; set; }
    }

    public class KuramotoNetworkCoupler {
        private readonly double _couplingK;
        private readonly double _baseFreq;

        public KuramotoNetworkCoupler(double couplingK, double baseFreq) {
            _couplingK = couplingK;
            _baseFreq = baseFreq;
        }

        public List<NetworkNodeResult> SyncGoogleEndpoints(string[] hosts) {
            int n = hosts.Length;
            var results = new List<NetworkNodeResult>();
            var ping = new Ping();

            // 1. Live socket ping to measure physical network latency across Google nodes
            for (int i = 0; i < n; i++) {
                string host = hosts[i];
                var res = new NetworkNodeResult { Host = host, IsAlive = false };
                try {
                    var reply = ping.Send(host, 2000);
                    if (reply != null && reply.Status == IPStatus.Success) {
                        res.LatencyMs = reply.RoundtripTime > 0 ? reply.RoundtripTime : 1.0;
                        res.IsAlive = true;
                    } else {
                        res.LatencyMs = 100.0;
                    }
                } catch {
                    res.LatencyMs = 150.0;
                }

                // Map live latency delta to oscillator frequency omega_i and phase theta_i
                res.NaturalFreq = _baseFreq + (res.LatencyMs / 1000.0);
                res.InitialPhase = (res.LatencyMs % 360.0) * (Math.PI / 180.0);
                results.Add(res);
            }

            // 2. Kuramoto Differential Coupling across live node network states
            double dt = 0.1;
            for (int i = 0; i < n; i++) {
                double phaseDiffSum = 0.0;
                for (int j = 0; j < n; j++) {
                    phaseDiffSum += Math.Sin(results[j].InitialPhase - results[i].InitialPhase);
                }
                double dTheta = results[i].NaturalFreq + (_couplingK / n) * phaseDiffSum;
                results[i].SynchronizedPhase = (results[i].InitialPhase + dTheta * dt) % (2.0 * Math.PI);
            }

            return results;
        }
    }
}
"@

if (-not ("Robdoe.Kuramoto.KuramotoNetworkCoupler" -as [type])) {
    Add-Type -TypeDefinition $csharpCode -Language CSharp
}

$coupler = New-Object Robdoe.Kuramoto.KuramotoNetworkCoupler($CouplingConstant, $BaseFreq)
$nodes = $coupler.SyncGoogleEndpoints($Endpoints)

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  GOOGLE NETWORK KURAMOTO PHASE COUPLER (POWERSHELL 5.1 / .NET)" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

foreach ($node in $nodes) {
    $status = if ($node.IsAlive) { "[ALIVE]" } else { "[UNREACHABLE]" }
    $color  = if ($node.IsAlive) { "Green" } else { "Yellow" }
    Write-Host ("{0,-18} | RTT: {1,6:F1} ms | Freq: {2,8:F6} Hz | Initial: {3,6:F4} rad | Sync: {4,6:F4} rad {5}" -f `
        $node.Host, $node.LatencyMs, $node.NaturalFreq, $node.InitialPhase, $node.SynchronizedPhase, $status) -ForegroundColor $color
}
