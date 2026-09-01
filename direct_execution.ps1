# ==============================================================================
# DIRECT HARDWARE & NETWORK EXECUTION (NO LLM MIDDLEMAN)
# ==============================================================================
$ErrorActionPreference = "Stop"
Push-Location "C:\RobdoeDeepSeekN-V3"

Write-Host "==> [1/3] EXECUTING IN-MEMORY .NET KURAMOTO ENGINE..." -ForegroundColor Yellow

$csharpCode = @"
using System;
using System.Collections.Generic;
using System.Net.NetworkInformation;

namespace Robdoe.DirectExec {
    public class DirectRunner {
        public static void Run(string[] hosts) {
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

            Console.WriteLine("\n--- LIVE NETWORK PHASE COUPLING ---");
            for (int i = 0; i < n; i++) {
                double phaseSum = 0.0;
                for (int j = 0; j < n; j++) {
                    phaseSum += Math.Sin(initialPhases[j] - initialPhases[i]);
                }
                double dTheta = baseFreq + (latencies[i] / 1000.0) + (couplingK / n) * phaseSum;
                double syncPhase = (initialPhases[i] + dTheta * 0.1) % (2.0 * Math.PI);
                
                Console.WriteLine(string.Format("{0,-18} | RTT: {1,5:F0} ms | Phase: {2,6:F4} rad | Sync: {3,6:F4} rad", 
                    hosts[i], latencies[i], initialPhases[i], syncPhase));
            }
        }
    }
}
"@

if (-not ("Robdoe.DirectExec.DirectRunner" -as [type])) {
    Add-Type -TypeDefinition $csharpCode -Language CSharp
}

[Robdoe.DirectExec.DirectRunner]::Run(@("time.google.com", "8.8.8.8", "8.8.4.4", "google.com"))

Write-Host "`n==> [2/3] STAGING WORKSPACE TO GIT..." -ForegroundColor Yellow
git add -A

Write-Host "`n==> [3/3] COMMITTING AND PUSHING TO ORIGIN..." -ForegroundColor Yellow
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
git commit -m "prod(direct): execution run at $timestamp" --quiet
git push origin HEAD

Write-Host "`n[✓] Direct execution complete." -ForegroundColor Green
Pop-Location
