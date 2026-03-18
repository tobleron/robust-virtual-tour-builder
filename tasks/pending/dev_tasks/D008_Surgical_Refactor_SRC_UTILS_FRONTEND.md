# Task D008: Surgical Refactor SRC UTILS FRONTEND

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

- [ ] - **../../src/utils/NetworkStatus.res** (Metric: [Nesting: 2.40, Density: 0.37, Coupling: 0.03] | Drag: 4.05 | LOC: 377/400  ⚠️ Trigger: Drag above target (2.40) with file already at 377 LOC.  🎯 Target: Function: `initialize` (High Local Complexity (9.0). Logic heavy.)) → Refactor in-place (keep near ~400 LOC and above 220 LOC floor)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D008_Surgical_Refactor_SRC_UTILS_FRONTEND/verification.json` (files at `_dev-system/tmp/D008_Surgical_Refactor_SRC_UTILS_FRONTEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D008_Surgical_Refactor_SRC_UTILS_FRONTEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/utils/NetworkStatus.res`
- `src/utils/NetworkStatus.res` (45 functions, fingerprint 59e936604aceb032cadb3f7ffa5d59a18343027a84109aa55c6c05950cbeb01d)
    - Grouped summary:
        - applySnapshot × 1 (lines: 175)
        - boolSubscribers × 1 (lines: 36)
        - cleanup × 1 (lines: 380)
        - clearRetryTimer × 1 (lines: 166)
        - currentAttempt × 1 (lines: 64)
        - currentNextRetryAtMs × 1 (lines: 66)
        - currentOnline × 1 (lines: 63)
        - currentPhase × 1 (lines: 49)
        - currentReason × 1 (lines: 56)
        - currentRetryDelayMs × 1 (lines: 65)
        - enterState × 1 (lines: 225)
        - forceStatus × 1 (lines: 354)
        - getSnapshot × 1 (lines: 127)
        - handleFocus × 1 (lines: 374)
        - handleOffline × 1 (lines: 370)
        - handleOnline × 1 (lines: 362)
        - initialize × 1 (lines: 389)
        - initialized × 1 (lines: 76)
        - intMax × 1 (lines: 113)
        - intMin × 1 (lines: 120)
        - isOnline × 1 (lines: 141)
        - lastHealthyAtMs × 1 (lines: 67)
        - nextDelayForAttempt × 1 (lines: 208)
        - notifySubscribers × 1 (lines: 157)
        - optionFloatEquals × 1 (lines: 106)
        - optionIntEquals × 1 (lines: 99)
        - parseRetryAfter × 1 (lines: 257)
        - phaseAllowsRequests × 1 (lines: 41)
        - phaseMessage × 1 (lines: 79)
        - probe × 1 (lines: 265)
        - probeInFlight × 1 (lines: 75)
        - probeNow × 1 (lines: 323)
        - reasonSignature × 1 (lines: 87)
        - reportBackendUnavailable × 1 (lines: 328)
        - reportProbeFailure × 1 (lines: 332)
        - reportRateLimited × 1 (lines: 336)
        - reportRequestSuccess × 1 (lines: 348)
        - reportTransportFailure × 1 (lines: 344)
        - retryDelaysMs × 1 (lines: 39)
        - retryTimeoutId × 1 (lines: 74)
        - scheduleRetry × 1 (lines: 215)
        - skipProbe × 1 (lines: 77)
        - snapshotSubscribers × 1 (lines: 37)
        - subscribe × 1 (lines: 143)
        - subscribeSnapshot × 1 (lines: 150)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
