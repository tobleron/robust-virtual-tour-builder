# Task D020: Surgical Refactor SRC FRONTEND

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

- [ ] - **../../src/App.res** (Metric: [Nesting: 6.60, Density: 0.34, Coupling: 0.11] | Drag: 7.94 | LOC: 429/300  🎯 Target: Function: `make` (High Local Complexity (35.3). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/ServiceWorkerMain.res** (Metric: [Nesting: 2.40, Density: 0.17, Coupling: 0.08] | Drag: 3.57 | LOC: 302/300  ⚠️ Trigger: Drag above target (1.80) with file already at 302 LOC.) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D020/verification.json` (files at `_dev-system/tmp/D020/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D020/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/App.res`
- `src/App.res` (7 functions, fingerprint 427e4f047d94c6764e40c1b1e247afbd84dc016deb834d5e5b243fa9772e14fe)
    - Grouped summary:
        - cadencePolicy × 1 (lines: 46)
        - canSyncToServer × 1 (lines: 68)
        - intMax × 1 (lines: 74)
        - intMin × 1 (lines: 75)
        - localAssetSyncSignature × 1 (lines: 18)
        - make × 2 (lines: 78, 457)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/ServiceWorkerMain.res`
- `src/ServiceWorkerMain.res` (21 functions, fingerprint 928b5014870bd4a3cb34743f6436fc334f107848c64b82da5ee34e95b5153aff)
    - Grouped summary:
        - activatePromise × 1 (lines: 185)
        - cacheName × 1 (lines: 79)
        - dedupeAssets × 1 (lines: 143)
        - fetchAndCache × 1 (lines: 277)
        - fetchWithAdaptiveTimeout × 1 (lines: 140)
        - fetchWithTimeout × 1 (lines: 130)
        - hasHashedAssetName × 1 (lines: 103)
        - installPromise × 1 (lines: 149)
        - isApi × 1 (lines: 259)
        - isImmutable × 1 (lines: 273)
        - isNavigation × 1 (lines: 260)
        - isResponseOlderThan × 1 (lines: 117)
        - isStaleWhileRevalidate × 1 (lines: 274)
        - manualAssets × 1 (lines: 80)
        - mode × 1 (lines: 257)
        - pathname × 1 (lines: 256)
        - performFetch × 1 (lines: 262)
        - request × 1 (lines: 252)
        - runtimeStaleMaxAgeMs × 1 (lines: 101)
        - shouldCacheResponse × 1 (lines: 108)
        - url × 1 (lines: 255)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
