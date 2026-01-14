# AntiGravity Workflow Manual
**Version 1.0** | **For Developers & AI Agents**

## 👋 Introduction
Welcome to the AntiGravity environment. This project uses a **"Safety First"** workflow system designed to prevent crashes, lost code, and broken builds. 

Unlike standard projects, you do not use raw `git` commands for everything. Instead, you have a suite of automated tools acting as your **Safety Net**, **Time Machine**, and **Gatekeeper**.

---

## 🟢 1. Starting Your Day
**Rule:** Never start coding without the Safety Net.

The system relies on a background "Shadow Watcher" that records every file save to a hidden backup branch. If this isn't running, you have no undo button.

### How to Start
Run the unified development script. This launches your backend, frontend compilers, and the **Snapshot Watcher** automatically.

    ./start_dev.sh

**What happens?**
1.  **Safety Check**: `scripts/ensure-watcher.sh` runs. If the watcher isn't active, it starts it.
2.  **Snapshots Active**: Every time you save a file (`Ctrl+S`), a silent backup is created in the `local-snapshots/` branch.
3.  **Dev Servers**: Rust and ReScript compilers start in watch mode.

---

## 💾 2. The Development Loop (Auto-Save)
**Feature:** "The Shadow Branch"

You do not need to manually save "WIP" (Work In Progress) commits.
* **Just Code**: Modify files as normal.
* **Auto-Backup**: The system captures a snapshot of your entire project state every time a file changes on disk.
* **Invisible**: These snapshots do **not** clutter your main git history. They live in a parallel dimension (`local-snapshots/develop`).

---

## 📦 3. Committing Changes
**Rule:** NEVER use `git commit` directly.

When you have finished a feature and want to create a permanent version in the project history:

### The Command
    ./scripts/commit.sh "feat: Add new hero section"

### What the Script Does (So you don't have to):
1.  **Preference Guard**: Scans your code for forbidden patterns (e.g., `console.log`, `var`, `innerHTML`). If found, it blocks the commit.
2.  **Context Map**: Updates `.agent/current_file_structure.md` so the AI knows where files are.
3.  **Versioning**: Automatically increments the version number (e.g., `v4.1.2` -> `v4.1.3`) in `package.json` and `src/version.js`.
4.  **Cache Busting**: Updates `index.html` to force browsers to load the new code.
5.  **Build Verification**: Runs `npm run res:build`. If the build fails, the commit is aborted.

---

## ⏪ 4. The Time Machine (Undo/Rollback)
**Feature:** "Forensic Rollback"

If you break the code or delete the wrong file, you can revert to any previous moment (even seconds ago).

### Option A: Ask the AI (Recommended)
Simply type in the chat:
> "AntiGravity, rollback to 5 minutes ago."
> "Undo the last change."
> "What changed recently? I need to go back."

The AI will:
1.  Analyze the "Shadow Branch" logs.
2.  Show you a list of recent changes with file stats.
3.  Run the restore script for you upon confirmation.

### Option B: Manual Terminal
Run the interactive menu:

    ./scripts/restore-snapshot.sh

* Select a snapshot hash from the list.
* Confirm "Yes".
* **Result**: Your files are instantly reverted. Your git history remains untouched.

---

## 🚀 5. Pushing to GitHub
**Rule:** Only push when stable.

When you run `git push`, a **Gatekeeper** hook runs automatically.

### The Checks
The push will **fail** if:
1.  **Backend Tests Fail**: Runs `cargo test` in the `backend/` folder.
2.  **Dirty Logs**: If you left `telemetry.log` or debug files.
3.  **Heavy Files**: If you accidentally committed a file larger than 1MB.

**If it fails:** Fix the issue (or revert using the Time Machine) and push again.

---

## ⚡ Cheat Sheet

| I want to... | Do this... |
| :--- | :--- |
| **Start Coding** | `./start_dev.sh` |
| **Save a Version** | `./scripts/commit.sh "message"` |
| **Undo Mistakes** | Ask AI: *"Rollback"* OR run `./scripts/restore-snapshot.sh` |
| **Check Logs** | Ask AI: *"What changed in the last 10 mins?"* |
| **Push Code** | `git push` (Automatic checks will run) |