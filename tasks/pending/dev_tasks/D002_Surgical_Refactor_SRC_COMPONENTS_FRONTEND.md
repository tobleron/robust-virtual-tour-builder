# Task D002: Surgical Refactor SRC COMPONENTS FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** Reduce estimated modification risk below the applicable drag target without fragmenting cohesive modules.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules only when the resulting split stays within the preferred size policy.
**Optimal State:** The file remains a clear 'Orchestrator' or 'Service' boundary, with only truly dense or isolated logic moved to specialized siblings.

### 🎯 Targets (Focus Area)
The Semantic Engine has identified the following specific symbols for refactoring:

## Tasks

### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../src/components/ReactHotspotLayer.res** (Metric: [Nesting: 6.00, Density: 0.37, Coupling: 0.08] | Drag: 7.49 | LOC: 417/400  ⚠️ Trigger: Drag above target (2.40) with file already at 417 LOC.  🎯 Target: Function: `make` (High Local Complexity (41.0). Logic heavy.)) → Refactor in-place (keep near ~400 LOC and above 220 LOC floor)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D002_Surgical_Refactor_SRC_COMPONENTS_FRONTEND/verification.json` (files at `_dev-system/tmp/D002_Surgical_Refactor_SRC_COMPONENTS_FRONTEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D002_Surgical_Refactor_SRC_COMPONENTS_FRONTEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/ReactHotspotLayer.res`
- `src/components/ReactHotspotLayer.res` (11 functions, fingerprint dec58200b9c44b04ba3103f1d1a5cf56461b9ad7eb045b2f7a58c2f5fe8dfc05)
    - Grouped summary:
        - cleanSceneTag × 1 (lines: 9)
        - clearHoveredStackRestoreTimer × 1 (lines: 165)
        - deriveDuplicateStackPlacements × 1 (lines: 68)
        - duplicateStackRestoreDelayMs × 1 (lines: 40)
        - duplicateTargetStackSpacingPx × 1 (lines: 39)
        - make × 1 (lines: 174)
        - resolveDuplicateGroupAnchorLinkId × 1 (lines: 156)
        - resolveStackedCoords × 1 (lines: 120)
        - sceneDisplayLabel × 1 (lines: 22)
        - sceneIdFromMeta × 1 (lines: 38)
        - shouldShowHotspotLabel × 1 (lines: 141)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
