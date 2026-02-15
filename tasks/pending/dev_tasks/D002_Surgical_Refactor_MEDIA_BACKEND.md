# Task D002: Surgical Refactor MEDIA BACKEND

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
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions. 🏗️ ARCHITECTURAL TARGET: Split into exactly 2 cohesive modules to respect the Read Tax (avg 300 LOC/module).

- [ ] - **../../backend/src/api/media/video_logic.rs** (Metric: [Nesting: 2.40, Density: 0.07, Coupling: 0.02] | Drag: 3.79 | LOC: 387/300)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D002/verification.json` (files at `_dev-system/tmp/D002/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D002/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/api/media/video_logic.rs`
- `backend/src/api/media/video_logic.rs` (5 functions, fingerprint be4149fb2b7db2c9f5277cc679726c03e4384b26747ff7c7f4aa30cdfe7f7543)
    - Grouped summary:
        - drop × 1 (lines: 252)
        - generate_teaser_sync × 1 (lines: 123)
        - get_ffmpeg_command × 1 (lines: 377)
        - headless_backend_origin × 1 (lines: 73)
        - transcode_video × 1 (lines: 77)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
