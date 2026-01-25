# 🚀 PROJECT PROTOCOLS & CONTEXT (v4.7+)

## 🧠 CORE BEHAVIOR (SYSTEM 2 THINKING)
1. **Context First**: ALL paths must be relative to root. READ `MAP.md` before editing code.
2. **Safety**: Files >700 lines require confirmation before editing.
3. **Commitment Constraint**: NEVER run `commit.sh` or `fast-commit.sh` unless explicitly asked to "save", "checkpoint", or "commit".
4. **Project Guard**: Ensure `./scripts/project-guard.sh` is running; if not, `nohup ./scripts/project-guard.sh > logs/project-guard.log 2>&1 &`.

## 🚨 CODING VITALS (PRIORITY 0)
- **ReScript v12 Only**: Use `Option`/`Result` explicitly. NO `unwrap()`, `panic!`, or `console.log`.
- **Logger Module**: Use `Logger.debug/info/error` for all telemetry.
- **Immutability**: Maintain functional purity in ReScript; avoid `mutable`.
- **Zero Warnings**: Production builds MUST have zero compiler warnings.

## 🛠️ WORKFLOW AUTOMATION

### PHASE 1: PRE-FLIGHT
- **Context Refresh**: Read `MAP.md` to locate core modules via `#tags`. For new files, read `/new-module-standards.md`.
- **Task Routing**: If working on a task in `tasks/pending`, follow `tasks/TASKS.md` sequence. Otherwise, execute directly.
- **Standards**: Read `/functional-standards.md` + file-specific standards (`rescript`, `rust`, `design-system`).

### PHASE 2: EXECUTION
- **Test-Driven**: Run `npm test` autonomously. If 2 failures occur, STOP and generate `FAILURE_REPORT.md`.
- **Build**: For formal tasks, run `npm run build`. For normal requests, skip (let dev server handle it).

### PHASE 3: COMMIT & PUSH
- **Explicit Permission**: Only commit when the user provides a message or instruction.
- **Standard Path**: `./scripts/commit.sh "msg"` (Build + Test + Doc Sync).
- **Fast Path**: `./scripts/fast-commit.sh "msg"` (Changelog + Snapshot only).
- **Push**: Run `./scripts/pre-push.sh` before pushing to remote.

## 🗣️ INTERACTION TRIGGERS
- **Undo/Rollback**: Run `git log local-snapshots/$(git branch --show-current) -n 5` to show history.
- **Refactor This**: Create a checklist in `tasks/current_refactor.md` and await "OK".

## 📂 CRITICAL PATHS
- **Codebase Map**: `./MAP.md` (Semantic index - READ FIRST)
- **Pending Tasks**: `./tasks/pending`
- **Workflows**: `.agent/workflows/`
