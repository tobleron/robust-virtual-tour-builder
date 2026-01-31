# 🚀 PROJECT PROTOCOLS & CONTEXT (v5.0)

## 🧠 CORE BEHAVIOR (SYSTEM 2 THINKING)
1. **Context First**: ALL paths must be relative to root. **ALWAYS READ `MAP.md` FIRST**.
2. **MAP.md Integrity**: When updating `MAP.md`, ALWAYS use **root-relative paths** (e.g., `[src/Main.res](src/Main.res)`). NEVER use absolute paths or `file:///` URIs.
3. **Commitment Constraint**: NEVER run `commit.sh` or `fast-commit.sh` unless explicitly asked to "save", "checkpoint", or "commit".
4. **Task Protocol**: Before handling any task related concerns, read `tasks/TASKS.md`.
5. **Conditional Context Loading**:
   - **IF** writing `.res` files: Read `.agent/workflows/rescript-standards.md`.
   - **IF** writing `.rs` files: Read `.agent/workflows/rust-standards.md`.
   - **IF** writing Tests: Read `.agent/workflows/testing-standards.md`.
   - **IF** debugging/instrumenting: Read `.agent/workflows/debug-standards.md`.
   - **IF** creating **NEW** modules: Read `.agent/workflows/new-module-standards.md`.

## 🚨 CODING VITALS (PRIORITY 0)
- **ReScript v12 Only**: Use `Option`/`Result` explicitly. NO `unwrap()`, `panic!`, or `console.log`.
- **Schema Validation**: Use `rescript-schema` for all JSON/IO interactions. Forbid legacy `JSON` module for complex objects. Use `S.serializeToJsonStringOrThrow` for all outgoing JSON. NO `Obj.magic` or unsafe casts.
- **Logger Module**: Use `Logger.debug/info/error` for all telemetry. High-value events and all `Diagnostic Mode` traces are visible via `./scripts/tail-diagnostics.sh`.
- **Immutability**: Maintain functional purity in ReScript; avoid `mutable`.
- **Zero Warnings**: Production builds MUST have zero compiler warnings.

## 🛠️ WORKFLOW AUTOMATION

### PHASE 1: EXECUTION
- **Build**: For normal requests, skip (let dev server handle it).

### PHASE 2: COMMIT & PUSH
- **Explicit Permission**: Only commit when the user provides a message or instruction.
- **Fast Path (Local Snapshot)**: `./scripts/fast-commit.sh "msg"` (Quick, Local, No Tests/Push).
- **Standard Path (Push)**: `./scripts/commit.sh "msg" [branch]` (Build Guard, Commit, & Push. Note: Tests are currently Bypassed/Manual).
- **Triple Path (Sync)**: `./scripts/triple-commit.sh "msg"` (Syncs & Pushes to main/testing/dev).
- **Manual Push**: `./scripts/pre-push.sh` is available for manual verification if needed.
