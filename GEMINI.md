# 🚀 PROJECT PROTOCOLS & CONTEXT

## 🧠 CORE BEHAVIOR (SYSTEM 2 THINKING)
Before executing ANY code or shell command, you must perform a **Context Check**:
1. **Locate Root**: Run `git rev-parse --show-toplevel` to find the project root.
2. **Pathing**: ALL paths in your commands must be relative to this root.
3. **Safety**: If you are about to edit a file >700 lines, **PAUSE** and ask for confirmation.
4. **Never use `git commit` directly** - Always use `./scripts/commit.sh`.

## 🛠️ WORKFLOW AUTOMATION
**Do not ask to run these. AUTOMATICALLY run them in this order:**

### PHASE 1: PRE-FLIGHT
- **Watcher Check (CRITICAL)**: Check if the safety watcher is running.
  - *Command*: `./scripts/ensure-watcher.sh`
- **Task Workflow (CRITICAL)**: Before performing ANY task from `tasks/pending` or `tasks/active`:
  - Read `tasks/TASKS.md` first to understand the proper workflow.
  - Follow the instructions in exact sequential order.
- **Context Refresh**: 
  - Read `.agent/current_file_structure.md` to avoid hallucinating paths.
  - If imports found from `src/`, read relevant `.resi` / `.rs` interfaces.
  - **New Modules**: If creating a new file, read `/new-module-standards` first.

### PHASE 2: EXECUTION
- **Coding Standards (Routed)**:
  - **ALWAYS READ FIRST**: `/functional-standards` (Universal Principles apply to ALL code).
  - **THEN**, based on file type:
    - For **ReScript** (`.res`, `.resi`): ALSO follow `/rescript-standards`.
    - For **Rust** (`.rs`): ALSO follow `/rust-standards`.
  - **Logging**: All debug logs must follow `/debug-standards`.
- **Test-Driven Dev**:
  - Follow `/testing-standards` for test structure and patterns.
  - You are PERMITTED to run `npm test` autonomously.
  - **Constraint**: If tests fail 2x in a row, STOP and generate a `FAILURE_REPORT.md`.

### PHASE 3: COMMIT & PUSH
- **Commit Protocol**: Use `./scripts/commit.sh` (handles formatting/linting).
- **Push Protocol**: BEFORE pushing to remote, read and follow `/pre-push-workflow`.

## 🗣️ INTERACTION TRIGGERS

### "Undo" / "Rollback" / "Time Machine" / "What changed?"
**Forensic Protocol:** Do NOT guess.
1. **Analysis**: Find the context first.
   - Run: `git log local-snapshots/$(git branch --show-current) -n 5 --stat --relative-date --pretty=format:"%h - %cr"`
2. **Presentation**: Show the user the list. Highlight which files were modified.
   - *Example*: "**a1b2c (2 mins ago)**: Modified `src/App.res` (+10 lines)"
3. **Confirmation**: Await specific hash selection from user.
4. **Execution**: Once confirmed, run: `./scripts/restore-snapshot.sh <HASH>`

### "Refactor This"
**Action:**
1. Create a checklist in `tasks/current_refactor.md`.
2. Wait for user "OK".
3. Proceed file-by-file.

## 📂 CRITICAL PATHS
- **Docs**: `./dev_prefs/` (User preferences)
- **File Structure**: `.agent/current_file_structure.md` (Avoid path hallucination)
- **Pending Tasks**: `./tasks/pending` (Write overflow tasks here)