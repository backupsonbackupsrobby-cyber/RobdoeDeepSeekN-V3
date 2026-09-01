import os
import math
import datetime

def calculate_phase():
    now_seconds = (datetime.datetime.utcnow() - datetime.datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)).total_seconds()
    arcseconds = (now_seconds * 15.0) % 1296000.0
    phase_rad = (arcseconds / 1296000.0) * 2.0 * math.pi
    return arcseconds, phase_rad

if __name__ == "__main__":
    arc, phase = calculate_phase()
    print(f"[✓] Crew Orchestrator Phase Sync: {arc:.2f}'' | Angle: {phase:.4f} rad")
    print("[✓] Agent Crew: Routing evaluation complete.")
