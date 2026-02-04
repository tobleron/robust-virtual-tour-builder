# Task 1213: Merge Folders FRONTEND

## Objective
## 🧩 Merge Objective
**Role:** Architecture Cleanup Bot
**Goal:** Reduce File Fragmentation (Read Tax).
**Constraint:** Combined file must not exceed 800 LOC.
**Optimal State:** Related small modules are unified into a single context window, reducing token consumption.

## Tasks

### 🔧 Action: Merge Fragmented Folders
**Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module file (e.g., `hooks.rs`). CRITICAL: Delete the now-empty `src/hooks/` folder to reduce directory nesting tax and strip any existing '@efficiency' tags.

- [ ] Folder: `src/hooks` (Metric: Recursive Feature Pod: 2 files in subtree sum to 81 LOC (fits in context). Max Drag: 9.57)
    - `src/hooks/../../src/hooks/UseIsInteractionPermitted.res`
    - `src/hooks/../../src/hooks/UseThrottledAction.res`
