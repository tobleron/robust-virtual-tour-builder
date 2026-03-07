# Task D012: Surgical Refactor TRAVERSAL FRONTEND

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

- [ ] - **../../src/systems/Traversal/CanonicalTraversal.res** (Metric: [Nesting: 4.20, Density: 0.15, Coupling: 0.05] | Drag: 5.45 | LOC: 403/300  🎯 Target: Function: `stripSceneTag` (High Local Complexity (5.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D012/verification.json` (files at `_dev-system/tmp/D012/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D012/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Traversal/CanonicalTraversal.res`
- `src/systems/Traversal/CanonicalTraversal.res` (16 functions, fingerprint 96250445eef351dda54515476ff38bfe188d43f2bd05772b4831f219b18deddc)
    - Grouped summary:
        - addVisitedLink × 1 (lines: 69)
        - applyManualOverrides × 1 (lines: 278)
        - applyVisitedActions × 1 (lines: 76)
        - clampOrder × 1 (lines: 57)
        - collectForwardRefs × 1 (lines: 207)
        - derive × 1 (lines: 398)
        - deriveAdmissibleOrders × 1 (lines: 457)
        - deriveAdmissibleOrdersByLinkId × 1 (lines: 363)
        - deriveReturnLinkIdSet × 1 (lines: 178)
        - deriveTraversalSnapshot × 1 (lines: 100)
        - displaySceneLabel × 1 (lines: 43)
        - firstNewLinkId × 1 (lines: 86)
        - isValidForwardOrder × 1 (lines: 313)
        - moveRefToIndex × 1 (lines: 352)
        - sortDefaultForwardRefs × 1 (lines: 263)
        - stripSceneTag × 1 (lines: 30)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
