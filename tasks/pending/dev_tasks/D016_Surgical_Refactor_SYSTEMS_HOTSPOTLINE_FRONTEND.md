# Task D016: Surgical Refactor SYSTEMS HOTSPOTLINE FRONTEND

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

- [ ] - **../../src/systems/HotspotLine/HotspotLineDrawing.res** (Metric: [Nesting: 3.00, Density: 0.21, Coupling: 0.06] | Drag: 4.21 | LOC: 280/300  ⚠️ Trigger: Drag above target (1.80) with file already at 280 LOC.  🎯 Target: Function: `waypointsRaw` (High Local Complexity (2.0). Logic heavy.)) → Refactor in-place


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D016/verification.json` (files at `_dev-system/tmp/D016/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D016/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/HotspotLine/HotspotLineDrawing.res`
- `src/systems/HotspotLine/HotspotLineDrawing.res` (8 functions, fingerprint 7b16638e0309dd0cfcea77ffb3228ad32942e8e4049ad88b011794b8d43a1657)
    - Grouped summary:
        - areCoordinatesValid × 1 (lines: 9)
        - drawLinkingDraft × 1 (lines: 176)
        - drawPersistentLines × 1 (lines: 161)
        - drawSingleHotspotLine × 1 (lines: 87)
        - getCamState × 1 (lines: 20)
        - isViewerValid × 1 (lines: 16)
        - renderPathSegment × 1 (lines: 73)
        - updatePolyLine × 1 (lines: 27)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
