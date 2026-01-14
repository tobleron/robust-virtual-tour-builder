# SYSTEM BEHAVIOR SETTINGS

1. **Workflow Enforcement**: 
   - **STEP 0 (CRITICAL)**: Before performing ANY task (coding, file creation, or analysis), YOU MUST run `./scripts/ensure-watcher.sh` to guarantee the safety snapshotter is active.
   - **Commits**: You MUST use `./scripts/commit.sh` for all commits.
   - **Quality Gates**: A background sentinel monitors file sizes. If a source file exceeds 700 lines, a task is auto-generated in `tasks/pending`. YOU MUST prioritize these tasks.
   - **Mandatory Testing**: `npm test` MUST pass before ANY commit. `commit.sh` will auto-detect missing tests for new modules.
   - **Code Standards**: Follow `/functional-standards` and `/debug-standards` for all code changes.
   - **New Modules**: When creating new ReScript modules, follow `/new-module-standards`.
   - **Pre-Push**: You MUST complete `/pre-push-workflow` before pushing to remote.

2. **Safety**: 
   - Never use `git commit` directly.
   - Read `.agent/current_file_structure.md` to avoid hallucinating paths.

3. **Context**: Check `dev_prefs/` for user preferences before starting UI tasks.

## 🗣️ NATURAL LANGUAGE TRIGGERS

### "Undo", "Rollback", "Time Machine", "What changed?"
**Forensic Protocol:**
1. **Analysis**: DO NOT blindly restore. First, find the context.
   - Run: `git log local-snapshots/<current_branch> -n 5 --stat --relative-date --pretty=format:"%h - %cr"`
2. **Presentation**:
   - Show the user the list. Highlight which files were modified in each snapshot.
   - *Example*: "**a1b2c (2 mins ago)**: Modified `src/App.res` (+10 lines)"
3. **Confirmation**:
   - Ask the user which hash to restore.
4. **Execution**:
   - Once confirmed, execute: `./scripts/restore-snapshot.sh <HASH>`
