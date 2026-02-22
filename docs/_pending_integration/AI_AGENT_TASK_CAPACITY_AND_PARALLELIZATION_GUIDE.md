# AI Agent Task Capacity and Parallelization Guide

## Purpose
Define practical task-sizing rules for Jules (or any AI coding agent) so single-session assignments are realistic, verifiable, and safe to run in parallel.

This guide is based on recent delivery behavior observed in teaser/CDP work:
- strong execution on focused implementation slices,
- weaker completion on broad multi-phase closure tasks that combine code + validation + documentation + metrics.

## Observed Capability Profile (Evidence-Based)

### What Jules handled well
1. Focused refactor in a bounded area (example: backend teaser capture path).
2. Fast implementation of primary path plus technical fallback.
3. Code compiles and integrates with existing architecture when scope is narrow.
4. Can add telemetry scaffolding during implementation.

### What Jules did not consistently finish in one pass
1. Full acceptance closure across all phases of a large task.
2. Cross-domain completion (backend + frontend + tests + docs + quantitative report) in one session.
3. Strict verification of every non-code gate (benchmark proof, rollout report, checklist artifacts).
4. Edge-condition validation requiring environment-sensitive behavioral confirmation.

## Capacity Model for Single-Session Tasks

### Capacity A (Recommended default)
Best fit for one AI session.
- 1 subsystem focus (frontend or backend, not both unless trivial glue).
- 1 primary objective.
- 1 fallback or guardrail allowed.
- 1 verification dimension (build or targeted test), not a full QA campaign.

### Capacity B (Allowed with tight controls)
Still feasible if carefully bounded.
- Up to 2 subsystems only when one is thin integration.
- Up to 2 objectives if they are tightly coupled and in the same flow.
- Requires explicit file list and strict out-of-scope.

### Capacity C (Do not assign as single task)
Must be split before delegation.
- Multi-phase programs (architecture migration + parity + telemetry + tests + docs).
- Work requiring full end-to-end benchmark evidence.
- Any task with more than one independent gatekeeper (engineering + QA + release docs).

## Mandatory Task Sizing Rules
1. One task must have one dominant success condition.
2. Limit expected file touch radius to a defined list before work starts.
3. Do not combine implementation and broad validation campaigns in one assignment.
4. Quantitative targets (FPS, latency, drift, memory, etc.) must be assigned as a separate verification task.
5. Documentation deliverables that require analysis should be a separate closure task.

## Parallelization Rule (Required)
Tasks assigned to Jules or any AI agent should be isolated from other code areas as much as possible.

Use this isolation contract when creating tasks:
1. `Boundary`: Specify exact modules/directories allowed.
2. `Owned Interfaces`: List allowed API contracts to touch.
3. `No-Touch Zones`: List shared files that must not change.
4. `Merge Risk`: Call out likely conflict files and ban them unless essential.
5. `Independent Verification`: Each task must have a verification method that does not depend on unfinished parallel tasks.

## Task Authoring Template (Use for Agent Delegation)

```
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

## Decomposition Pattern for Large Features
When a request looks like a big epic, split into sequential tasks:
1. `Implementation Slice`: code change only.
2. `Stability Slice`: fallback/error/cancel handling only.
3. `Validation Slice`: metrics and acceptance proof only.
4. `Documentation Slice`: rollout notes/checklist/report only.

Do not collapse these back into one assignment for a single agent session.

## Recommended Review Policy for Agent-Delivered Work
1. Verify claimed acceptance criteria line by line against task spec.
2. Reject "core done" claims if non-code gates were required and not delivered.
3. Grade completion as:
   - `Complete`: all acceptance criteria and evidence delivered.
   - `Partial`: implementation done, closure gates missing.
   - `Not Ready`: fails compile/runtime correctness.

## Practical Assignment Limits (Default)
1. Max one major behavior change per task.
2. Max one fallback mechanism per task.
3. Max one runtime environment assumption per task.
4. Max one performance target per task.

## Why this policy
This preserves delivery speed while reducing partial completions, merge churn, and rework loops. It also enables safe parallel execution by minimizing overlap and conflict in shared architecture files.
