# Task D002: Surgical Refactor API MEDIA BACKEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 1.80 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.
**Optimal State:** The file becomes a pure 'Orchestrator' or 'Service', with complex math/logic moved to specialized siblings.

### 🎯 Targets (Focus Area)
The Semantic Engine has identified the following specific symbols for refactoring:

## Tasks

### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../backend/src/api/media/video_capture.rs** (Metric: [Nesting: 3.00, Density: 0.10, Coupling: 0.02] | Drag: 5.18 | LOC: 327/300  ⚠️ Trigger: Drag above target (1.80) with file already at 327 LOC.) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../backend/src/api/media/video_runtime_generate.rs** (Metric: [Nesting: 2.40, Density: 0.07, Coupling: 0.03] | Drag: 3.85 | LOC: 315/300  ⚠️ Trigger: Drag above target (1.80) with file already at 315 LOC.) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D002/verification.json` (files at `_dev-system/tmp/D002/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D002/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/api/media/video_capture.rs`
- `backend/src/api/media/video_capture.rs` (3 functions, fingerprint 34d280a16a262280580ec52cc068fc697c8d239cb08d8f3d983609680f2cdef8)
    - Grouped summary:
        - capture_frames_cdp × 1 (lines: 42)
        - capture_frames_polling × 1 (lines: 218)
        - start_script_content × 1 (lines: 35)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `backend/src/api/media/video_runtime_generate.rs`
- `backend/src/api/media/video_runtime_generate.rs` (1 functions, fingerprint 72c956cac2db449e54e30505893b1efd3fb8f05ba298f02dade0ecb3b941eb70)
    - Grouped summary:
        - generate_teaser_sync × 1 (lines: 15)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
