import os
import subprocess
from crewai import Agent, Crew, Process, Task, LLM

# ------------------------------------------------------------------------------
# 1. LOCAL LLM CONFIGURATION (Zero API Keys)
# Targets local Ollama instance at http://localhost:11434
# Models: "ollama/qwen2.5:14b", "ollama/deepseek-r1:8b", or "ollama/llama3.1:8b"
# ------------------------------------------------------------------------------
local_llm = LLM(
    model="ollama/qwen2.5:14b",
    base_url="http://localhost:11434"
)

# ------------------------------------------------------------------------------
# 2. DEFINE AGENTS
# ------------------------------------------------------------------------------
harmonic_phase_agent = Agent(
    role="Photonic Harmonic Oscillator",
    goal="Calculate and lock network phase angles using local .NET C# Kuramoto execution.",
    backstory="Autonomous engine supervisor managing real-time phase synchronization and dispersion matrix calculations.",
    verbose=True,
    allow_delegation=False,
    llm=local_llm
)

git_sync_agent = Agent(
    role="Atomic Storage & Sync Agent",
    goal="Ensure all phase-coupled states and patched code files are committed and pushed to origin.",
    backstory="Version control agent ensuring repository synchronization across local and origin branches.",
    verbose=True,
    allow_delegation=False,
    llm=local_llm
)

# ------------------------------------------------------------------------------
# 3. DEFINE TASKS & EXECUTION ACTIONS
# ------------------------------------------------------------------------------
def execute_kuramoto_step() -> str:
    cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", "C:\\RobdoeDeepSeekN-V3\\google_kuramoto_network.ps1"]
    res = subprocess.run(cmd, capture_output=True, text=True)
    return res.stdout if res.returncode == 0 else res.stderr

def execute_git_commit() -> str:
    cmd = [
        "powershell", "-Command",
        "Push-Location C:\\RobdoeDeepSeekN-V3; git add -A; git commit -m 'prod(crew): automated phase-locked execution'; git push origin HEAD; Pop-Location"
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    return res.stdout if res.returncode == 0 else res.stderr

task_sync = Task(
    description="Run the live .NET Kuramoto network coupler script to derive phase angles.",
    expected_output="Verified phase angles and latency metrics for all monitored network endpoints.",
    agent=harmonic_phase_agent,
    action=execute_kuramoto_step
)

task_git = Task(
    description="Stage workspace changes and push to origin.",
    expected_output="Confirmation of clean git commit and push to origin remote.",
    agent=git_sync_agent,
    action=execute_git_commit
)

# ------------------------------------------------------------------------------
# 4. CREW PIPELINE LAUNCHER
# ------------------------------------------------------------------------------
if __name__ == "__main__":
    pipeline_crew = Crew(
        agents=[harmonic_phase_agent, git_sync_agent],
        tasks=[task_sync, task_git],
        process=Process.sequential,
        verbose=True
    )
    
    print("==> [CREWAI] Starting local offline agent pipeline...")
    output = pipeline_crew.kickoff()
    print("\n[✓] Local CrewAI Orchestration Complete:")
    print(output)
