import os
import sys
from crewai import Agent, Task, Crew, Process
from langchain_openai import ChatOpenAI

print("=" * 80)
print("  ENTERPRISE MULTI-AGENT GIT ORCHESTRATOR (HA-FAILOVER ENGINE)")
print("=" * 80)

# ------------------------------------------------------------------------------
# 1. ENTERPRISE TIER-1 RESILIENCE: FAILOVER MODEL ORCHESTRATION
# ------------------------------------------------------------------------------
try:
    # Attempt Primary Deployment Model (Cloud Tier)
    print("[INIT] Booting Primary Cloud Model (gpt-4o)...")
    enterprise_llm = ChatOpenAI(
        model="gpt-4o",  # Bypassing mini to avoid strict project restriction
        temperature=0.2,
        max_tokens=4000
    )
    # Ping test to verify project token permissions before handing over to agents
    enterprise_llm.invoke("Ping")
    print("[SUCCESS] Connected to Cloud Infrastructure.")
except Exception as cloud_error:
    print(f"[WARN] Cloud Infrastructure rejected credentials: {cloud_error}")
    print("[FALLBACK] Initializing Zero-Trust Local Engine via Ollama...")
    
    # Failover to local production model (Hardware Tier)
    enterprise_llm = ChatOpenAI(
        base_url="http://localhost:11434/v1",
        api_key="ollama",  # System pass-through value
        model="llama3.1",  # Swappable with deepseek-coder or qwen2.5-coder
        temperature=0.1
    )

# ------------------------------------------------------------------------------
# 2. ISOLATED PRODUCTION AGENT ROLES (Boundary Enforcement)
# ------------------------------------------------------------------------------
analyst_agent = Agent(
    role='Lead Codebase Analyst',
    goal='Statically scan repository file structures and map structural hotspots.',
    backstory='Enterprise pipeline auditor specializing in zero-fault dependency isolation.',
    verbose=True,
    allow_delegation=False,
    llm=enterprise_llm
)

git_operator_agent = Agent(
    role='Automated Git Systems Operator',
    goal='Execute isolated branch creation, worktree configuration, and merge gating.',
    backstory='Hardened system daemon capable of conflict resolution across continuous integration.',
    verbose=True,
    allow_delegation=False,
    llm=enterprise_llm
)

# ------------------------------------------------------------------------------
# 3. TASK DEFINITIONS & SECURE CONTEXT STRATEGY
# ------------------------------------------------------------------------------
scan_repo_task = Task(
    description='Analyze the active folder tracking structure for circular imports or file collisions.',
    expected_output='A clean structural audit report documenting code structural health.',
    agent=analyst_agent
)

# ------------------------------------------------------------------------------
# 4. EXECUTION LAYER
# ------------------------------------------------------------------------------
enterprise_crew = Crew(
    agents=[analyst_agent, git_operator_agent],
    tasks=[scan_repo_task],
    process=Process.sequential,  # Serial execution ensures state durability
    verbose=True
)

if __name__ == "__main__":
    print("[START] Executing Multi-Agent Pipeline...")
    result = enterprise_crew.kickoff()
    print("\n[FINAL COMPLIANCE OUTPUT]:\n", result)
