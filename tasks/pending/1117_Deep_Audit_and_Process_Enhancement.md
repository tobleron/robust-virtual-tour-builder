# Task 1117: Deep Audit, Process Enhancement & Zombie Elimination

## Objective
Enhance the architectural integrity of the project by refining the `_dev-system` analyzer to proactively manage the lifecycle of generated tasks and auditing the entire development workflow for loopholes.

## ⚡ Technical Goals
- **Zombie Elimination**: Update the `_dev-system/analyzer` to automatically delete task files in `tasks/pending/` that no longer meet the threshold criteria (e.g., after a config change or manual refactor).
- **Workflow Audit**: Review the interaction between the analyzer, `MAP.md`, and the `tasks/` directory to ensure no concerns are left unaddressed or double-counted.
- **Process Optimization**: Harmonize the "Smart Merge" logic with the "Surgical Refactor" logic to prevent circular task generation (e.g., merging files that immediately trigger a split task).
- **Metric Verification**: Ensure the `Drag` score and `LOC` thresholds are perfectly tuned for current codebase scale.

## Tasks
- [x] Implement stale task cleanup in `_dev-system/analyzer/src/main.rs`. (Verified)
- [x] Conduct a deep audit of all modules currently in `pending/` and verify they are valid concerns. (Audit complete, tasks 1106, 1108, 1112, 1113, 1114, 1116 are valid)
- [x] Refine `MAP.md` sync logic to ensure all new modules are correctly classified. (Enhanced: Added `.bs.js` exclusion and MAP.md zombie elimination)
- [x] Verify build and test stability after analyzer logic updates. (Passed)
