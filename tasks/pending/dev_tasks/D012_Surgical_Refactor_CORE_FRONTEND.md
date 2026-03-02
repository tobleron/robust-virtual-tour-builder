# Task D012: Surgical Refactor CORE FRONTEND

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

- [ ] - **../../src/core/JsonParsersDecoders.res** (Metric: [Nesting: 3.00, Density: 0.65, Coupling: 0.05] | Drag: 4.65 | LOC: 376/300  🎯 Target: Function: `project` (High Local Complexity (13.4). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D012/verification.json` (files at `_dev-system/tmp/D012/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D012/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/core/JsonParsersDecoders.res`
- `src/core/JsonParsersDecoders.res` (36 functions, fingerprint 69e5550b02111d1ee90511d0d3ebae6e1252bfbe39f9effe0fb87e5cde88e9ab)
    - Grouped summary:
        - array × 1 (lines: 18)
        - arrivalView × 1 (lines: 257)
        - bool × 1 (lines: 22)
        - decode × 1 (lines: 316)
        - encode × 1 (lines: 331)
        - field × 1 (lines: 17)
        - file × 1 (lines: 43)
        - float × 1 (lines: 20)
        - hotspot × 1 (lines: 71)
        - id × 1 (lines: 25)
        - importScene × 1 (lines: 277)
        - int × 1 (lines: 19)
        - inventory × 1 (lines: 172)
        - inventoryEntry × 1 (lines: 168)
        - map × 1 (lines: 24)
        - motionAnimationSegment × 1 (lines: 343)
        - motionManifest × 1 (lines: 410)
        - motionShot × 1 (lines: 363)
        - motionTransitionOut × 1 (lines: 356)
        - normalizeLogo × 1 (lines: 56)
        - object × 1 (lines: 16)
        - opt × 1 (lines: 35)
        - option × 1 (lines: 23)
        - persistedSession × 1 (lines: 240)
        - project × 1 (lines: 181)
        - scene × 1 (lines: 95)
        - sceneEntry × 1 (lines: 161)
        - sceneStatus × 1 (lines: 132)
        - step × 1 (lines: 264)
        - steps × 1 (lines: 275)
        - string × 1 (lines: 21)
        - timelineItem × 1 (lines: 118)
        - transitionTarget × 1 (lines: 248)
        - updateHotspotMetadata × 1 (lines: 307)
        - updateMetadata × 1 (lines: 298)
        - viewFrame × 1 (lines: 63)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
