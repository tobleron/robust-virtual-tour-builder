# Task 1193: Merge Folders BACKEND

## Objective
## 🧩 Merge Objective
**Role:** Architecture Cleanup Bot
**Goal:** Reduce File Fragmentation (Read Tax).
**Constraint:** Combined file must not exceed 800 LOC.
**Optimal State:** Related small modules are unified into a single context window, reducing token consumption.

## Tasks

### 🔧 Action: Merge Fragmented Folders
**Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module file (e.g., `auth.rs`). CRITICAL: Delete the now-empty `../../backend/src/auth/` folder to reduce directory nesting tax and strip any existing '@efficiency' tags.

- [ ] Folder: `../../backend/src/auth` (Metric: Read Tax high (Score 2.00). Projected Limit: 300 (Drag 3.05))
    - `../../backend/src/auth/jwt.rs`
    - `../../backend/src/auth/middleware.rs`
