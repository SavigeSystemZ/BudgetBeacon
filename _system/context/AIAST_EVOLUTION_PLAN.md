# AIAST Evolution Plan: Hardening & Modernization Strategy

This plan outlines a world-class, phased approach to comprehensively eliminate the 5 core vulnerabilities within the `_AI_AGENT_SYSTEM_TEMPLATE`. 

### Language Selection for Core Orchestration: **Go (Golang)**
*Why Go?* We are choosing Go over Rust for this architectural migration. Go is the industry standard for CLI orchestration and infrastructure (Docker, Kubernetes, Antigravity CLI are all written in Go). It provides a "clean, just works" experience, compiles instantly across platforms, has an exceptionally robust standard library for filesystem manipulation and concurrency (via goroutines), and has a lower learning curve for agents to maintain and modify than Rust.

---

## Phase 1: Stabilization & Safety (The Shield)
*Goal: Stop data loss and context bloat immediately using the existing toolchain before the massive architectural rewrite.*

**1.1 Native Safe-Sync (Resolves Destructive Overwrites)**
- **Action:** Upgrade the existing `update-template.sh` to natively support 3-way merging and automatic backups.
- **Implementation:** 
  - Before applying template updates, the script will mathematically hash the managed files.
  - If a file is modified locally by an agent, instead of overwriting it, the script will rename the local file to `<filename>.local_override.md`, lay down the fresh template version, and append a diff block as an active `TODO` for the agent to resolve the conflict.
  - Automatically create a `.update_backups/` snapshot on every sync.

**1.2 Automated Context Compaction (Resolves Context Bloat)**
- **Action:** Implement a `compact-context` module.
- **Implementation:**
  - Create a routine that analyzes the age and size of files in `_system/context/`, `WHERE_LEFT_OFF.md`, and `TODO.md`.
  - When tokens exceed a threshold (e.g., 50 files or 30 days old), an agent triggers a compression task.
  - The task uses an LLM call to summarize the operational history into a highly dense `_system/context/ARCHIVE_SUMMARY.md`.
  - Stale tactical files are zipped into `_system/context/cold-storage/` and removed from the active context window.

---

## Phase 2: Architectural Migration (The Go Rewrite)
*Goal: Eliminate Bash fragility by migrating the entire meta-system orchestration into a compiled, strongly typed Go binary.*

**2.1 The `aiast` CLI Foundation (Resolves Brittleness)**
- **Action:** Build a monolithic Go application (`aiast-cli`) to replace the labyrinth of shell scripts.
- **Implementation:**
  - Initialize a new Go module (`cmd/aiast`).
  - Re-implement `system-doctor.sh`, `validate-system.sh`, and `check-system-awareness.sh` as compiled Go commands (`aiast doctor`, `aiast validate`, `aiast sync`).
  - Use Go's `filepath` and `os` packages to guarantee 100% cross-platform compatibility (macOS/Linux/Windows) and eliminate absolute path string-parsing bugs.

**2.2 JSON/Schema Strictness**
- **Action:** Move all configuration from loose Markdown/Bash arrays into strictly typed JSON/YAML managed by the Go CLI.
- **Implementation:**
  - The Go CLI will use internal structs to strictly enforce the schema of `SYSTEM_REGISTRY.json` and `repo-operating-profile.json`, preventing agents from ever writing malformed metadata.

---

## Phase 3: True Sandbox Isolation (The Fortress)
*Goal: Protect the host machine from rogue agent commands or destructive hallucinations.*

**3.1 Native Devcontainer / Docker Scaffolding**
- **Action:** Integrate secure execution layers for all downstream applications.
- **Implementation:**
  - Update the scaffold profile matrix so that every newly generated project automatically includes a tightly bound `Dockerfile` and `docker-compose.yml` configured strictly for agent execution.
  - The Go CLI will gain an `aiast execute` command that routes all agent shell commands into the containerized environment.
  - Block access to `~/.MyAppZ/` outside of the specific project's bounded directory via Docker volume mounts.

**3.2 Privilege Separation**
- **Action:** Implement a dual-user model inside the sandbox.
- **Implementation:**
  - Agents operate as an unprivileged `ai-agent` user inside the container. If they attempt an operation requiring `sudo` (like installing a global dependency), the Go CLI intercepts the request and queues it for human biometric/password approval, strictly adhering to the user's elevation rules.

---

## Phase 4: Swarm Event-Bus (The Hive Mind)
*Goal: Enable real-time, zero-polling communication between multiple agents working on the same repository.*

**4.1 Lightweight IPC Event-Bus**
- **Action:** Replace the filesystem polling mechanism with real-time sockets.
- **Implementation:**
  - The `aiast` Go CLI will spawn a lightweight background daemon (`aiast serve`) per repository.
  - This daemon hosts a local WebSocket or gRPC server bound to a local port (registered in `~/.MyAppZ/PORTS_REGISTRY.md`).

**4.2 Push-Based State Synchronization**
- **Action:** Implement subscribe/notify logic for the Swarm.
- **Implementation:**
  - Instead of polling `WHERE_LEFT_OFF.md`, agents subscribe to the `aiast serve` daemon.
  - When Agent A finishes a task and commits code, the daemon instantly pushes a JSON payload to Agent B ("Task complete. New context available.").
  - This eradicates file locking race conditions and slashes token usage, as agents are only fed context exactly when the system state mutates.

---

### Execution Strategy
We can begin executing **Phase 1** immediately within the current bash architecture to plug the bleeding holes, and then seamlessly transition into **Phase 2** by scaffolding the initial Go project inside the `TEMPLATE` directory.
