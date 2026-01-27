# 🚀 PROJECT PROTOCOLS & CONTEXT (v5.0)

## 🧠 CORE BEHAVIOR (SYSTEM 2 THINKING)
1. **Context First**: ALL paths must be relative to root. **ALWAYS READ `MAP.md` FIRST**.
2. **Commitment Constraint**: NEVER run `commit.sh` or `fast-commit.sh` unless explicitly asked to "save", "checkpoint", or "commit".
3. **Conditional Context Loading**:
   - **IF** writing `.res` files: Read `.agent/workflows/rescript-standards.md`.
   - **IF** writing `.rs` files: Read `.agent/workflows/rust-standards.md`.
   - **IF** writing Tests: Read `.agent/workflows/testing-standards.md`.
   - **IF** debugging/instrumenting: Read `.agent/workflows/debug-standards.md`.
   - **IF** creating **NEW** modules: Read `.agent/workflows/new-module-standards.md`.

## 🚨 CODING VITALS (PRIORITY 0)
- **ReScript v12 Only**: Use `Option`/`Result` explicitly. NO `unwrap()`, `panic!`, or `console.log`.
- **Logger Module**: Use `Logger.debug/info/error` for all telemetry.
- **Immutability**: Maintain functional purity in ReScript; avoid `mutable`.
- **Zero Warnings**: Production builds MUST have zero compiler warnings.

## 🛠️ WORKFLOW AUTOMATION

### PHASE 1: EXECUTION
- **Test-Driven**: Run `npm test` autonomously. If 2 failures occur, STOP and generate `FAILURE_REPORT.md`.
- **Build**: For formal tasks, run `npm run build`. For normal requests, skip (let dev server handle it).

### PHASE 2: COMMIT & PUSH
- **Explicit Permission**: Only commit when the user provides a message or instruction.
- **Standard Path**: `./scripts/commit.sh "msg"` (Build + Test + Guard Checks).
- **Fast Path**: `./scripts/fast-commit.sh "msg"` (Guard Checks only).
- **Push**: Run `./scripts/pre-push.sh` before pushing to remote.

## 📂 CRITICAL PATHS
- **Codebase Map**: `./MAP.md` (Semantic index - READ FIRST)
- **Pending Tasks**: `./tasks/pending`
- **Workflows**: `.agent/workflows/`