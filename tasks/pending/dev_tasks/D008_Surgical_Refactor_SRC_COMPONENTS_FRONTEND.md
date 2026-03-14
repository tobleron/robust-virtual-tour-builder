# Task D008: Surgical Refactor SRC COMPONENTS FRONTEND

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

- [ ] - **../../src/components/ReactHotspotLayer.res** (Metric: [Nesting: 6.00, Density: 0.39, Coupling: 0.08] | Drag: 7.50 | LOC: 404/300  ⚠️ Trigger: Drag above target (1.80); keep the module within the 250-350 LOC working band if you extract helpers.  🎯 Target: Function: `make` (High Local Complexity (41.0). Logic heavy.)) → Refactor in-place (keep near ~300 LOC)

- [ ] - **../../src/components/VisualPipelineEdgePaths.res** (Metric: [Nesting: 4.80, Density: 0.43, Coupling: 0.05] | Drag: 6.23 | LOC: 253/300  ⚠️ Trigger: Drag above target (1.80) with file already at 253 LOC.  🎯 Target: Function: `clipId` (High Local Complexity (2.5). Logic heavy.)) → Refactor in-place (keep near ~300 LOC)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D008_Surgical_Refactor_SRC_COMPONENTS_FRONTEND/verification.json` (files at `_dev-system/tmp/D008_Surgical_Refactor_SRC_COMPONENTS_FRONTEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D008_Surgical_Refactor_SRC_COMPONENTS_FRONTEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/ReactHotspotLayer.res`
- `src/components/ReactHotspotLayer.res` (11 functions, fingerprint 9b6048619a9b271e13d431855e9668a0e4a4b195bc42fe43a28dd8dcbb573cce)
    - Grouped summary:
        - cleanSceneTag × 1 (lines: 9)
        - clearHoveredStackRestoreTimer × 1 (lines: 156)
        - deriveDuplicateStackPlacements × 1 (lines: 68)
        - duplicateStackRestoreDelayMs × 1 (lines: 40)
        - duplicateTargetStackSpacingPx × 1 (lines: 39)
        - make × 1 (lines: 165)
        - resolveDuplicateGroupAnchorLinkId × 1 (lines: 147)
        - resolveStackedCoords × 1 (lines: 111)
        - sceneDisplayLabel × 1 (lines: 22)
        - sceneIdFromMeta × 1 (lines: 38)
        - shouldShowHotspotLabel × 1 (lines: 132)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/components/VisualPipelineEdgePaths.res`
- `src/components/VisualPipelineEdgePaths.res` (3 functions, fingerprint 8f00ac5dfcc74a1f849933ccc36d8434774aa9cdaea44538359a68047d21477b)
    - Grouped summary:
        - buildContinuityPaths × 1 (lines: 173)
        - edgePathForPair × 1 (lines: 30)
        - hasNodeCollisionOnHorizontal × 1 (lines: 5)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
