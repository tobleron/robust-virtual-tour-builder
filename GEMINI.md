# 🚀 PROJECT PROTOCOLS & CONTEXT (v5.0)

## 🧠 CORE BEHAVIOR (SYSTEM 2 THINKING)
1. **Context First**: ALL paths must be relative to root. **ALWAYS READ `MAP.md` and `DATA_FLOW.md` FIRST**.
2. **MAP.md Integrity**: When updating `MAP.md`, ALWAYS use **root-relative paths** (e.g., `[src/Main.res](src/Main.res)`). NEVER use absolute paths or `file:///` URIs.
3. **Commitment Constraint**: NEVER run `commit.sh` or `fast-commit.sh` unless explicitly asked to "save", "checkpoint", or "commit".
4. **Task Protocol**: Before handling any task related concerns, read `tasks/TASKS.md`.
5. **Iterative Code Change Verification Policy**: For ongoing code calibration/refinement of any source files, verify the build after each change and defer unit-test rewrites until behavior stabilizes. Create or reuse a single pending task that tracks all deferred unit-test review work for the affected modules instead of editing tests on every iteration.
6. **Conditional Context Loading**:
   - **IF** writing `.res` files: Read `.agent/workflows/rescript-standards.md`.
   - **IF** writing `.rs` files: Read `.agent/workflows/rust-standards.md`.
   - **IF** writing Tests: Read `.agent/workflows/testing-standards.md`.
   - **IF** debugging/instrumenting: Read `.agent/workflows/debug-standards.md`.
   - **IF** creating **NEW** modules: Read `.agent/workflows/new-module-standards.md`.

## 🚨 CODING VITALS (PRIORITY 0)
- **ReScript v12 Only**: Use `Option`/`Result` explicitly. NO `unwrap()`, `panic!`, or `console.log`.
- **Schema Validation**: Use `rescript-json-combinators` (module `JsonCombinators`) for all JSON/IO interactions to ensure CSP compliance (no `eval`). Forbid `rescript-schema` and legacy `JSON` module.
- **Logger Module**: Use `Logger.debug/info/error` for all telemetry. High-value events and all `Diagnostic Mode` traces are visible via `./scripts/tail-diagnostics.sh`.
- **Immutability**: Maintain functional purity in ReScript; avoid `mutable`.
- **Zero Warnings**: Production builds MUST have zero compiler warnings.

## 🛠️ WORKFLOW AUTOMATION

### PHASE 0: TROUBLESHOOTING
- **Trigger**: When asked to "troubleshoot", "debug", "fix", or investigate a bug.
- **Action**: Create `tasks/active/T###_troubleshoot_[context].md` immediately (Sequential numbering with project tasks).
- **Mandatory Content**:
  - [ ] **Hypothesis (Ordered Expected Solutions)**: Checkbox list ordered by highest probability first. Each item must be an expected fix path, not just a symptom.
  - [ ] **Activity Log**: Checkbox list of experiments/edits.
  - [ ] **Code Change Ledger**: During troubleshooting, record every code change as it happens (file path + short change summary + revert note) so individual edits can be rolled back surgically.
  - [ ] **Rollback Check**: [ ] (Confirmed CLEAN or REVERTED non-working changes).
  - [ ] **Context Handoff**: 3-sentence summary for the next session if the window fills up.

### PHASE 1: EXECUTION
- **Default verification for iterative code changes**: Prefer `npm run build` or the narrowest relevant build-equivalent check first. Do not spend tokens repeatedly updating unit tests while the source behavior is still being tuned.
- **Deferred test maintenance**: If source code changes outpace test updates, create or reuse one shared pending task for deferred unit-test review and list the affected modules there for later alignment once the implementation is stable.

### PHASE 2: COMMIT & PUSH
- **Explicit Permission**: Only commit when the user provides a message or instruction.
- **Fast Path (Local Snapshot)**: `./scripts/fast-commit.sh "msg"` (Quick, Local, No Tests/Push).
- **Standard Path (Push)**: `./scripts/commit.sh "msg" [branch]` (Build Guard, Commit, & Push. Note: Tests are currently Bypassed/Manual).
- **Main Branch Guard**: `main` is production-bound. Dev-only auth/bootstrap shortcuts must never be promoted there; `./scripts/guard-main-release.sh main` is enforced by scripts and CI.
- **Selective Promotion Rule**: Dev-only features must live in isolated commits so production-safe improvements can be promoted to `main` without carrying development shortcuts.
- **Storage Check**: Before committing, audit for unnecessary large files (logs, temp zips, etc.) and ask the user for cleanup permission.
- **Manual Push**: `./scripts/pre-push.sh` is available for manual verification if needed.
