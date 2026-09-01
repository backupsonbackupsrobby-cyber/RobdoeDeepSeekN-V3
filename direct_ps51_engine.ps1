# ==============================================================================
# PURE POWERSHELL 5.1 NATIVE .NET HARMONIC ENGINE & GIT PIPELINE
# ==============================================================================
$ErrorActionPreference = "Stop"
Push-Location "C:\RobdoeDeepSeekN-V3"

Write-Host "==> [PS 5.1] COMPILING NATIVE .NET HARMONIC ENGINE..." -ForegroundColor Cyan

$csharpCode = @"
using System;
using System.Collections.Generic;
using System.Net.NetworkInformation;

namespace Robdoe.PS51Engine {
    public class KuramotoRunner {
        public static void Execute(string[] hosts) {
            double baseFreq = 0.05208333;
            double couplingK = 2.5;
            var ping = new Ping();
            int n = hosts.Length;

            double[] latencies = new double[n];
            double[] initialPhases = new double[n];

            for (int i = 0; i < n; i++) {
                try {
                    var reply = ping.Send(hosts[i], 1500);
                    latencies[i] = (reply != null && reply.Status == IPStatus.Success) ? reply.RoundtripTime : 100.0;
                } catch {
                    latencies[i] = 150.0;
                }
                initialPhases[i] = (latencies[i] % 360.0) * (Math.PI / 180.0);
            }

            Console.WriteLine("\n--- PS 5.1 LIVE NETWORK PHASE MATRIX ---");
            for (int i = 0; i < n; i++) {
                double phaseSum = 0.0;
                for (int j = 0; j < n; j++) {
                    phaseSum += Math.Sin(initialPhases[j] - initialPhases[i]);
                }
                double dTheta = baseFreq + (latencies[i] / 1000.0) + (couplingK / n) * phaseSum;
                double syncPhase = (initialPhases[i] + dTheta * 0.1) % (2.0 * Math.PI);

                Console.WriteLine(string.Format("{0,-18} | RTT: {1,5:F0} ms | Initial: {2,6:F4} rad | Sync: {3,6:F4} rad", 
                    hosts[i], latencies[i], initialPhases[i], syncPhase));
            }
        }
    }
}
"@

if (-not ("Robdoe.PS51Engine.KuramotoRunner" -as [type])) {
    Add-Type -TypeDefinition $csharpCode -Language CSharp
}

[Robdoe.PS51Engine.KuramotoRunner]::Execute(@("time.google.com", "8.8.8.8", "8.8.4.4", "google.com"))

Write-Host "`n==> [PS 5.1] STAGING ALL WORKSPACE CHANGES TO GIT..." -ForegroundColor Cyan
git add -A

Write-Host "`n==> [PS 5.1] COMMITTING AND PUSHING TO ORIGIN..." -ForegroundColor Cyan
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
git commit -m "prod(ps51): pure powershell 5.1 execution at $timestamp" --quiet
git push origin HEAD

Write-Host "`n[✓] Pure PowerShell 5.1 Pipeline Execution Complete." -ForegroundColor Green
Pop-Location
