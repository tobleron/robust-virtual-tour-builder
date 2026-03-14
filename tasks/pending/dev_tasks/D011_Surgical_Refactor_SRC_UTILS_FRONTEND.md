# Task D011: Surgical Refactor SRC UTILS FRONTEND

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

- [ ] - **../../src/utils/Logger.res** (Metric: [Nesting: 1.80, Density: 0.29, Coupling: 0.07] | Drag: 3.17 | LOC: 279/300  ⚠️ Trigger: Drag above target (1.80) with file already at 279 LOC.  🎯 Target: Function: `init` (High Local Complexity (18.8). Logic heavy.)) → Refactor in-place (keep near ~300 LOC)

- [ ] - **../../src/utils/NetworkStatus.res** (Metric: [Nesting: 2.40, Density: 0.36, Coupling: 0.03] | Drag: 4.03 | LOC: 385/300  ⚠️ Trigger: Drag above target (1.80); keep the module within the 250-350 LOC working band if you extract helpers.  🎯 Target: Function: `initialize` (High Local Complexity (9.0). Logic heavy.)) → Refactor in-place (keep near ~300 LOC)

- [ ] - **../../src/utils/RequestQueue.res** (Metric: [Nesting: 3.00, Density: 0.15, Coupling: 0.06] | Drag: 4.25 | LOC: 253/300  ⚠️ Trigger: Drag above target (1.80) with file already at 253 LOC.  🎯 Target: Function: `pushByPriority` (High Local Complexity (3.5). Logic heavy.)) → Refactor in-place (keep near ~300 LOC)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D011_Surgical_Refactor_SRC_UTILS_FRONTEND/verification.json` (files at `_dev-system/tmp/D011_Surgical_Refactor_SRC_UTILS_FRONTEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D011_Surgical_Refactor_SRC_UTILS_FRONTEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/utils/Logger.res`
- `src/utils/Logger.res` (50 functions, fingerprint 8cef8da528b4129723c7d58584a08535eaa6a9fd22d1083c00d78e636ab4e9bc)
    - Grouped summary:
        - appLog × 1 (lines: 31)
        - attempt × 1 (lines: 160)
        - attemptAsync × 1 (lines: 169)
        - batchTimer × 1 (lines: 255)
        - createLogEntry × 1 (lines: 53)
        - currentOperationId × 1 (lines: 35)
        - debug × 1 (lines: 86)
        - disable × 1 (lines: 228)
        - disableDiagnostics × 1 (lines: 223)
        - enable × 1 (lines: 213)
        - enableDiagnostics × 1 (lines: 218)
        - enabled × 1 (lines: 24)
        - enabledModules × 1 (lines: 26)
        - endOperation × 1 (lines: 183)
        - entries × 1 (lines: 29)
        - error × 1 (lines: 90)
        - errorWithAppError × 1 (lines: 122)
        - flushTelemetry × 1 (lines: 21)
        - getOperationId × 1 (lines: 38)
        - getSessionId × 1 (lines: 39)
        - info × 1 (lines: 88)
        - init × 1 (lines: 257)
        - initialized × 1 (lines: 185)
        - isDiagnosticMode × 1 (lines: 204)
        - isError × 1 (lines: 246)
        - isFlushing × 1 (lines: 19)
        - log × 1 (lines: 81)
        - logResult × 1 (lines: 187)
        - logToConsole × 1 (lines: 27)
        - logWithAppError × 1 (lines: 93)
        - maxAppLogEntries × 1 (lines: 32)
        - maxEntries × 1 (lines: 30)
        - minLevel × 1 (lines: 25)
        - perf × 1 (lines: 131)
        - runtimeContext × 1 (lines: 41)
        - sendTelemetry × 1 (lines: 22)
        - sessionId × 1 (lines: 34)
        - setBypassTestEnvCheck × 1 (lines: 20)
        - setGlobalLoggerWarnHook × 1 (lines: 251)
        - setLevel × 1 (lines: 206)
        - setOperationId × 1 (lines: 37)
        - startOperation × 1 (lines: 181)
        - telemetryQueue × 1 (lines: 18)
        - timed × 1 (lines: 141)
        - timedAsync × 1 (lines: 150)
        - toggle × 1 (lines: 233)
        - trace × 1 (lines: 84)
        - updateLogBuffers × 1 (lines: 68)
        - warn × 1 (lines: 89)
        - warnWithAppError × 1 (lines: 113)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/utils/NetworkStatus.res`
- `src/utils/NetworkStatus.res` (45 functions, fingerprint 80aceeeed5ae07ffef623f71c750bce9851f94f602e2402e178992b5744c3ea0)
    - Grouped summary:
        - applySnapshot × 1 (lines: 175)
        - boolSubscribers × 1 (lines: 36)
        - cleanup × 1 (lines: 388)
        - clearRetryTimer × 1 (lines: 166)
        - currentAttempt × 1 (lines: 64)
        - currentNextRetryAtMs × 1 (lines: 66)
        - currentOnline × 1 (lines: 63)
        - currentPhase × 1 (lines: 49)
        - currentReason × 1 (lines: 56)
        - currentRetryDelayMs × 1 (lines: 65)
        - enterState × 1 (lines: 227)
        - forceStatus × 1 (lines: 362)
        - getSnapshot × 1 (lines: 127)
        - handleFocus × 1 (lines: 382)
        - handleOffline × 1 (lines: 378)
        - handleOnline × 1 (lines: 370)
        - initialize × 1 (lines: 397)
        - initialized × 1 (lines: 76)
        - intMax × 1 (lines: 113)
        - intMin × 1 (lines: 120)
        - isOnline × 1 (lines: 141)
        - lastHealthyAtMs × 1 (lines: 67)
        - nextDelayForAttempt × 1 (lines: 208)
        - notifySubscribers × 1 (lines: 157)
        - optionFloatEquals × 1 (lines: 106)
        - optionIntEquals × 1 (lines: 99)
        - parseRetryAfter × 1 (lines: 264)
        - phaseAllowsRequests × 1 (lines: 41)
        - phaseMessage × 1 (lines: 79)
        - probe × 1 (lines: 272)
        - probeInFlight × 1 (lines: 75)
        - probeNow × 1 (lines: 331)
        - reasonSignature × 1 (lines: 87)
        - reportBackendUnavailable × 1 (lines: 336)
        - reportProbeFailure × 1 (lines: 340)
        - reportRateLimited × 1 (lines: 344)
        - reportRequestSuccess × 1 (lines: 356)
        - reportTransportFailure × 1 (lines: 352)
        - retryDelaysMs × 1 (lines: 39)
        - retryTimeoutId × 1 (lines: 74)
        - scheduleRetry × 1 (lines: 215)
        - skipProbe × 1 (lines: 77)
        - snapshotSubscribers × 1 (lines: 37)
        - subscribe × 1 (lines: 143)
        - subscribeSnapshot × 1 (lines: 150)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/utils/RequestQueue.res`
- `src/utils/RequestQueue.res` (27 functions, fingerprint 2e9c38c24430464a8cc471f0a744b3786ca874bb7a7028a337e83911be78cc60)
    - Grouped summary:
        - activeCount × 1 (lines: 6)
        - backgroundQueue × 1 (lines: 22)
        - criticalBurstSlots × 1 (lines: 5)
        - criticalQueue × 1 (lines: 20)
        - currentConcurrencyLimit × 1 (lines: 87)
        - drain × 1 (lines: 192)
        - handleRateLimit × 1 (lines: 150)
        - handleRateLimitForScope × 1 (lines: 168)
        - initializeNetworkListener × 1 (lines: 216)
        - length × 1 (lines: 28)
        - logQueueDepths × 1 (lines: 31)
        - maxConcurrent × 1 (lines: 3)
        - maxQueued × 1 (lines: 4)
        - normalQueue × 1 (lines: 21)
        - nowMs × 1 (lines: 25)
        - pause × 1 (lines: 129)
        - paused × 1 (lines: 24)
        - process × 1 (lines: 95)
        - promoteStarved × 1 (lines: 56)
        - pushByPriority × 1 (lines: 48)
        - resume × 1 (lines: 139)
        - schedule × 1 (lines: 226)
        - scheduleWithPriority × 1 (lines: 230)
        - scheduleWithRetry × 1 (lines: 261)
        - scopeBackoffUntilMs × 1 (lines: 26)
        - shiftNext × 1 (lines: 80)
        - waitForScope × 1 (lines: 179)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
