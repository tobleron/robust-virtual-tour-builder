# Task D006: Surgical Refactor SRC SITE FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** Reduce estimated modification risk below the applicable drag target without fragmenting cohesive modules.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules only when the resulting split stays within the preferred size policy.
**Optimal State:** The file remains a clear 'Orchestrator' or 'Service' boundary, with only truly dense or isolated logic moved to specialized siblings.

### 🎯 Targets (Focus Area)
The Semantic Engine has identified the following specific symbols for refactoring:

## Tasks

### 🔧 Action: Audit & Delete
**Directive:** De-bloat: Reduce module size by identifying and extracting independent domain logic.

- [ ] - **../../src/site/PortalApi.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 366)) → Refactor in-place (keep near ~400 LOC and above 220 LOC floor)

- [ ] - **../../src/site/PortalApp.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 2977)) → Refactor in-place (keep near ~400 LOC and above 220 LOC floor)

- [ ] - **../../src/site/PortalTypes.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 225)) → Refactor in-place (keep near ~400 LOC and above 220 LOC floor)


### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../src/site/PortalApp.res** (Metric: [Nesting: 8.40, Density: 0.19, Coupling: 0.01] | Drag: 9.67 | LOC: 2977/400  ⚠️ Trigger: Drag above target (2.40); keep the module within the 350-450 LOC working band if you extract helpers.  🎯 Target: Function: `make` (High Local Complexity (225.8). Logic heavy.)) → 🏗️ Split into 7 modules (target 350-450 LOC each, center ~400 LOC, floor 220 LOC)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D006_Surgical_Refactor_SRC_SITE_FRONTEND/verification.json` (files at `_dev-system/tmp/D006_Surgical_Refactor_SRC_SITE_FRONTEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D006_Surgical_Refactor_SRC_SITE_FRONTEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/site/PortalApp.res`
- `src/site/PortalApp.res` (29 functions, fingerprint b0003462ddf215c25278701a172e34127dbe14b8c198e1c2e8c9ca7f83b9a874)
    - Grouped summary:
        - actionLabel × 1 (lines: 501)
        - adminActionIcon × 1 (lines: 301)
        - appBrandHeader × 1 (lines: 275)
        - brandLockup × 1 (lines: 264)
        - customerDraftFromOverview × 1 (lines: 226)
        - customerPortalPath × 1 (lines: 589)
        - customerTourPath × 1 (lines: 591)
        - directTourAccessUrl × 1 (lines: 586)
        - draftFromSettings × 1 (lines: 218)
        - emptyFlash × 1 (lines: 216)
        - findCustomerOverview × 1 (lines: 82)
        - friendlyDateTimeLabel × 1 (lines: 195)
        - injectBaseHref × 1 (lines: 615)
        - isoToLocalDateTime × 1 (lines: 171)
        - localDateTimeToIso × 1 (lines: 183)
        - make × 3 (lines: 508, 2665, 3041)
        - messageNode × 1 (lines: 253)
        - mobileLabel × 1 (lines: 584)
        - normalizePath × 1 (lines: 104)
        - nowPlusDaysIsoLocal × 1 (lines: 166)
        - parseRoute × 1 (lines: 124)
        - portalTourEntryBaseUrl × 1 (lines: 594)
        - portalTourEntryCandidates × 1 (lines: 602)
        - recipientTypeFromValue × 1 (lines: 246)
        - recipientTypeLabel × 1 (lines: 239)
        - recipientTypeValue × 1 (lines: 232)
        - routeAccessMessage × 1 (lines: 207)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
