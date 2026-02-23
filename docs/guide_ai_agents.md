# AI Agent Task Capacity and Parallelization Guide

## Purpose
Define practical task-sizing rules for Jules (or any AI coding agent) so single-session assignments are realistic, verifiable, and safe to run in parallel.

## Observed Capability Profile (Evidence-Based)

### What AI handles well
1. Focused refactors in a bounded area (e.g., single backend path or UI slice).
2. Fast implementation of primary path plus technical fallback.
3. Code compiles and integrates with existing architecture when scope is narrow.
4. Telemetry scaffolding during implementation.

### What AI struggles with
1. Full acceptance closure across all phases of a massive task.
2. Cross-domain completion (e.g., backend + frontend + tests + docs + qualitative report) in one shot.
3. Edge-condition validations that require environment-sensitive confirmation.

---

## Capacity Model for Single-Session Tasks

### Capacity A (Recommended default)
Best fit for one AI session.
- 1 subsystem focus (frontend or backend, not both).
- 1 primary objective.
- 1 fallback or guardrail allowed.
- 1 verification dimension (build or targeted test), not a full QA campaign.

### Capacity B (Allowed with tight controls)
Still feasible if carefully bounded.
- Up to 2 subsystems only when one is thin integration (glue).
- Up to 2 objectives if they are tightly coupled and in the same flow.
- Requires explicit file list and strict out-of-scope boundaries.

### Capacity C (Do not assign as single task)
Must be split before delegation.
- Multi-phase programs (architecture migration + parity + telemetry + tests + docs).
- Tasks exceeding 300-400 lines of touch radius or wide scope.

---

## Mandatory Task Sizing Rules
1. One task must have one dominant success condition.
2. Limit expected file touch radius to a defined list before work starts.
3. Do not combine implementation and broad validation campaigns in one assignment.
4. Quantitative targets (FPS, latency, drift) must be assigned as a separate verification task.

---

## Parallelization Contract (Required)
Tasks assigned to AI agents must be isolated from other code areas as much as possible.

Use this isolation contract when creating tasks:
1. `Boundary`: Specify exact modules/directories allowed.
2. `Owned Interfaces`: List allowed API contracts to touch.
3. `No-Touch Zones`: List shared files that must not change (e.g., `State.res`, `Reducer.res`).
4. `Merge Risk`: Call out likely conflict files and ban them unless essential.
5. `Independent Verification`: Each task must have a verification method that does not depend on unfinished parallel tasks.

---

## Task Authoring Template 

```md
Title:
Objective (single sentence):
Capacity class: A or B

In scope:
- ...

Out of scope:
- ...

Allowed files (root-relative):
- backend/src/...
- src/systems/...

No-touch files:
- src/core/Reducer.res
- src/core/State.res

Acceptance criteria (binary):
1. ...
2. ...

Verification evidence required:
1. Build/test command output summary
2. Screenshot/log snippet (if UI/runtime behavior)

If not complete:
- return with explicit blockers and partial status, no silent assumptions
```
