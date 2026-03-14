# Task D009: Surgical Refactor SRC SITE FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 1.80 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.
**Optimal State:** The file becomes a pure 'Orchestrator' or 'Service', with complex math/logic moved to specialized siblings.

### 🎯 Targets (Focus Area)
The Semantic Engine has identified the following specific symbols for refactoring:

## Tasks

### 🔧 Action: Audit & Delete
**Directive:** De-bloat: Reduce module size by identifying and extracting independent domain logic.

- [ ] - **../../src/site/PortalApi.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 362)) → Refactor in-place (keep near ~300 LOC)

- [ ] - **../../src/site/PortalApp.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 2354)) → Refactor in-place (keep near ~300 LOC)

- [ ] - **../../src/site/PortalTypes.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 194)) → Refactor in-place (keep near ~300 LOC)


### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../src/site/PageFrameworkBuilder.js** (Metric: [Nesting: 9.00, Density: 0.20, Coupling: 0.01] | Drag: 10.20 | LOC: 352/300  ⚠️ Trigger: Drag above target (1.80); keep the module within the 250-350 LOC working band if you extract helpers.) → Refactor in-place (keep near ~300 LOC)

- [ ] - **../../src/site/PortalApi.res** (Metric: [Nesting: 1.80, Density: 0.19, Coupling: 0.06] | Drag: 2.99 | LOC: 362/300  ⚠️ Trigger: Drag above target (1.80); keep the module within the 250-350 LOC working band if you extract helpers.  🎯 Target: Function: `authHeaderValue` (High Local Complexity (5.8). Logic heavy.)) → Refactor in-place (keep near ~300 LOC)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D009_Surgical_Refactor_SRC_SITE_FRONTEND/verification.json` (files at `_dev-system/tmp/D009_Surgical_Refactor_SRC_SITE_FRONTEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D009_Surgical_Refactor_SRC_SITE_FRONTEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/site/PageFrameworkBuilder.js`
- `src/site/PageFrameworkBuilder.js` (0 functions, fingerprint e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/site/PortalApi.res`
- `src/site/PortalApi.res` (33 functions, fingerprint 793b045fd7e881859ac3679775e53545073e9d9e2b20841fd039cbee196023d4)
    - Grouped summary:
        - adminSessionDecoder × 1 (lines: 43)
        - apiErrorDecoder × 1 (lines: 37)
        - assignTour × 1 (lines: 322)
        - authHeaderValue × 1 (lines: 63)
        - changeAdminPassword × 1 (lines: 182)
        - createCustomer × 1 (lines: 246)
        - decodeErrorResponse × 1 (lines: 88)
        - decodeResponse × 1 (lines: 80)
        - deleteAccessLinks × 1 (lines: 314)
        - deleteCustomer × 1 (lines: 352)
        - deleteTour × 1 (lines: 360)
        - devHosts × 1 (lines: 31)
        - getAdminSession × 1 (lines: 141)
        - listCustomers × 1 (lines: 232)
        - listLibraryTours × 1 (lines: 239)
        - loadCustomerPublic × 1 (lines: 381)
        - loadCustomerSession × 1 (lines: 387)
        - loadCustomerTours × 1 (lines: 393)
        - loadSettings × 1 (lines: 199)
        - maybeErrorMessage × 1 (lines: 71)
        - okDecoder × 1 (lines: 59)
        - regenerateAccessLink × 1 (lines: 295)
        - request × 1 (lines: 97)
        - revokeAccessLink × 1 (lines: 306)
        - signInAdmin × 1 (lines: 148)
        - signInDecoder × 1 (lines: 53)
        - signOutAdmin × 1 (lines: 172)
        - signOutCustomer × 1 (lines: 399)
        - unassignTour × 1 (lines: 333)
        - updateCustomer × 1 (lines: 271)
        - updateSettings × 1 (lines: 206)
        - updateTourStatus × 1 (lines: 341)
        - uploadTour × 1 (lines: 368)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
