# Task 1113: Merge Folders BACKEND

## Objective
## 🧩 Merge Objective
**Role:** Architecture Cleanup Bot
**Goal:** Reduce File Fragmentation (Read Tax).
**Constraint:** Combined file must not exceed 800 LOC.
**Optimal State:** Related small modules are unified into a single context window, reducing token consumption.

## Tasks
- [ ] Folder: `backend/src/services/auth`
    - **Metric:** Recursive Feature Pod: 2 files in subtree sum to 111 LOC (fits in context).
    - **Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module to reduce token overhead during analysis.
    - `../../backend/src/services/auth/jwt.rs`
    - `../../backend/src/services/auth/mod.rs`
- [ ] Folder: `backend/src/services/media`
    - **Metric:** Recursive Feature Pod: 8 files in subtree sum to 766 LOC (fits in context).
    - **Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module to reduce token overhead during analysis.
    - `../../backend/src/services/media/analysis.rs`
    - `../../backend/src/services/media/analysis_exif.rs`
    - `../../backend/src/services/media/analysis_quality.rs`
    - `../../backend/src/services/media/mod.rs`
    - `../../backend/src/services/media/naming.rs`
    - `../../backend/src/services/media/resizing.rs`
    - `../../backend/src/services/media/storage.rs`
    - `../../backend/src/services/media/webp.rs`
- [ ] Folder: `backend/src/services/project`
    - **Metric:** Recursive Feature Pod: 4 files in subtree sum to 605 LOC (fits in context).
    - **Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module to reduce token overhead during analysis.
    - `../../backend/src/services/project/load.rs`
    - `../../backend/src/services/project/mod.rs`
    - `../../backend/src/services/project/package.rs`
    - `../../backend/src/services/project/validate.rs`
- [ ] Folder: `backend/src/services/geocoding`
    - **Metric:** Recursive Feature Pod: 2 files in subtree sum to 375 LOC (fits in context).
    - **Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module to reduce token overhead during analysis.
    - `../../backend/src/services/geocoding/logic.rs`
    - `../../backend/src/services/geocoding/mod.rs`
- [ ] Folder: `backend/src/middleware`
    - **Metric:** Recursive Feature Pod: 4 files in subtree sum to 375 LOC (fits in context).
    - **Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module to reduce token overhead during analysis.
    - `../../backend/src/middleware/auth.rs`
    - `../../backend/src/middleware/mod.rs`
    - `../../backend/src/middleware/quota_check.rs`
    - `../../backend/src/middleware/request_tracker.rs`
