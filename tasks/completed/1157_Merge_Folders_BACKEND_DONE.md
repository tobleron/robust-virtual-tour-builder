# Task 1157: Merge Folders BACKEND

## Objective
## 🧩 Merge Objective
**Role:** Architecture Cleanup Bot
**Goal:** Reduce File Fragmentation (Read Tax).
**Constraint:** Combined file must not exceed 800 LOC.
**Optimal State:** Related small modules are unified into a single context window, reducing token consumption.

## Tasks

### 🔧 Action: Merge Fragmented Folders
**Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module to reduce token overhead during analysis.

- [ ] Folder: `../../backend/src/pathfinder` (Metric: Read Tax high (Score 3.00). Projected Limit: 300 (Drag 3.47))
    - `../../backend/src/pathfinder/algorithms.rs`
    - `../../backend/src/pathfinder/graph.rs`
    - `../../backend/src/pathfinder/utils.rs`
- [ ] Folder: `backend/src/auth` (Metric: Recursive Feature Pod: 4 files in subtree sum to 288 LOC (fits in context). Max Drag: 3.05)
    - `backend/src/auth/../../backend/src/auth/handlers.rs`
    - `backend/src/auth/../../backend/src/auth/middleware.rs`
    - `backend/src/auth/../../backend/src/auth/mod.rs`
    - `backend/src/auth/../../backend/src/auth/service.rs`
- [ ] Folder: `backend/src/middleware` (Metric: Recursive Feature Pod: 3 files in subtree sum to 213 LOC (fits in context). Max Drag: 3.03)
    - `backend/src/middleware/../../backend/src/middleware/mod.rs`
    - `backend/src/middleware/../../backend/src/middleware/quota_check.rs`
    - `backend/src/middleware/../../backend/src/middleware/request_tracker.rs`
