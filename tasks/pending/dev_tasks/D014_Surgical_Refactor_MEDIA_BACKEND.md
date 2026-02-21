# Task D014: Surgical Refactor MEDIA BACKEND

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

- [ ] - **../../backend/src/api/media/video_logic.rs** (Metric: [Nesting: 2.40, Density: 0.07, Coupling: 0.01] | Drag: 3.90 | LOC: 580/300) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D014/verification.json` (files at `_dev-system/tmp/D014/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D014/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/api/media/video_logic.rs`
- `backend/src/api/media/video_logic.rs` (12 functions, fingerprint 467fe9dde1ed78ba4f149ececc19ad7abb2d171a4c3ee3ececb8c8d03180c90e)
    - Grouped summary:
        - apply_capture_mode × 1 (lines: 136)
        - content_type × 1 (lines: 103)
        - drop × 1 (lines: 124)
        - extension × 1 (lines: 96)
        - from_str × 1 (lines: 89)
        - generate_teaser_sync × 1 (lines: 217)
        - get_ffmpeg_command × 1 (lines: 578)
        - headless_backend_origin × 1 (lines: 132)
        - new × 1 (lines: 114)
        - resolve_capture_viewport × 1 (lines: 150)
        - take × 1 (lines: 118)
        - transcode_video × 1 (lines: 171)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
