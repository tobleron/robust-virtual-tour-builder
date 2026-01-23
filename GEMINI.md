# 🚀 PROJECT PROTOCOLS & CONTEXT

## 🧠 CORE BEHAVIOR (SYSTEM 2 THINKING)
Before executing ANY code or shell command, you must perform a **Context Check**:
1. **Pathing**: ALL paths in your commands must be relative to project root.
2. **Safety**: If you are about to edit a file >700 lines, **PAUSE** and ask for confirmation.
3. **Never use `git commit` directly**.

## 🚨 CODING VITALS (PRIORITY 0)
- **ReScript v12 Only**: All frontend code MUST be in ReScript v12.
- **Explicit Handling**: Use `Option`/`Result` explicitly. No `unwrap()` or `panic!`.
- **Logger Module**: `console.log` is strictly forbidden. Use the `Logger` module.
- **No Alerts**: Use `EventBus.dispatch(ShowNotification(...))` or modals.
- **Immutability**: Maintain functional purity in ReScript; avoid `mutable` unless performance critical.

## 📂 CRITICAL PATHS
- **Codebase Map**: `./MAP.md` (Semantic index - READ FIRST)
- **Pending Tasks**: `./tasks/pending` (Standard tasks)
- **Postponed Tasks**: `./tasks/postponed` (Deferred tasks) & `./tasks/postponed/tests` (Test tasks)

## 🛠️ WORKFLOW AUTOMATION
**Do not ask to run these. AUTOMATICALLY run them in this order:**

### PHASE 1: PRE-FLIGHT (CONTEXT & ROUTING)
1. **Context Refresh**: 
   - Read [MAP.md](file:///Users/r2/Desktop/robust-virtual-tour-builder/MAP.md) to understand the semantic project structure and locate core modules via `#tags`.
   - If imports found from `src/`, read relevant `.resi` / `.rs` interfaces.
   - **New Modules**: If creating a new file, read `/new-module-standards.md` first.
2. **Task Routing**:
   - **Existing Tasks**: ONLY when working with EXISTING tasks from `tasks/pending`, `tasks/postponed`, or `tasks/active`:
     - Read `tasks/TASKS.md` first to understand the proper workflow.
     - Follow the instructions in exact sequential order.
   - **Normal Requests**: For general user requests that don't reference existing tasks, execute directly without creating task files.

### PHASE 2: EXECUTION (STANDARDS & VERIFICATION)
1. **Coding Standards (Routed)**:
   - **ALWAYS READ FIRST**: `/functional-standards.md` (Universal Principles apply to ALL code).
   - **THEN**, based on file type:
     - For **ReScript** (`.res`, `.resi`): ALSO follow `/rescript-standards.md`.
     - For **Rust** (`.rs`): ALSO follow `/rust-standards.md`.
   - **Styling**: ALL CSS/UI work must follow `/docs/DESIGN_SYSTEM.md`.
   - **Logging**: All debug logs must follow `/debug-standards.md`.
2. **Code Sentinel (Automation)**:
   - A background process (`./scripts/watch-file-limits.sh`) monitors code for growth, coverage, and structure changes.
   - **Automated Tasks**: It automatically creates tasks in `tasks/pending/` for Refactors, Tests, and Map Synchronization.
   - **Token Efficiency**: Do NOT manually create maintenance tasks if the Sentinel can handle them.
3. **Test-Driven Dev**:
   - Follow `/testing-standards.md` for test structure and patterns.
   - You are PERMITTED to run `npm test` autonomously.
   - **Constraint**: If tests fail 2x in a row, STOP and generate a `FAILURE_REPORT.md`.
4. **Build Verification**:
   - **For Formal Tasks**: ALWAYS run `npm run build` to ensure compilation passes before considering a task complete.
   - **For Normal Requests**: Skip `npm run build` (user runs `npm run dev` in background for live compilation).

### PHASE 3: COMMIT & PUSH
- **Commit Protocol**: Use `./scripts/commit.sh` (handles formatting/linting).
- **Push Protocol**: BEFORE pushing to remote, read and follow `/pre-push-workflow.md`.

## 🗣️ INTERACTION TRIGGERS

### "Undo" / "Rollback" / "Time Machine" / "What changed?"
**Forensic Protocol:** Do NOT guess.
1. **Analysis**: Find the context first.
   - Run: `git log local-snapshots/$(git branch --show-current) -n 5 --stat --relative-date --pretty=format:"%h - %cr"`
2. **Presentation**: Show the user the list. Highlight which files were modified.
3. **Confirmation**: Await specific hash selection from user.
4. **Execution**: Once confirmed, run: `./scripts/restore-snapshot.sh <HASH>`

### "Refactor This"
**Action:**
1. Create a checklist in `tasks/current_refactor.md`.
2. Wait for user "OK".
3. Proceed file-by-file.