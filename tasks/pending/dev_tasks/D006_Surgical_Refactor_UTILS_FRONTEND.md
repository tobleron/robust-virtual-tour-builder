# Task D006: Surgical Refactor UTILS FRONTEND

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

- [ ] - **../../src/utils/AsyncQueue.res** (Metric: [Nesting: 3.60, Density: 0.12, Coupling: 0.02] | Drag: 4.88 | LOC: 471/300  🎯 Target: Function: `toSortedCopy` (High Local Complexity (6.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/utils/LoggerTelemetry.res** (Metric: [Nesting: 3.00, Density: 0.20, Coupling: 0.06] | Drag: 4.34 | LOC: 453/300  🎯 Target: Function: `parseRetryAfterHeaderMs` (High Local Complexity (4.8). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/utils/PersistenceLayer.res** (Metric: [Nesting: 3.00, Density: 0.12, Coupling: 0.05] | Drag: 4.26 | LOC: 545/300  🎯 Target: Function: `getAutosaveCostStats` (High Local Complexity (12.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/utils/Retry.res** (Metric: [Nesting: 4.20, Density: 0.29, Coupling: 0.03] | Drag: 5.55 | LOC: 386/300  🎯 Target: Function: `classifyError` (High Local Complexity (4.5). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/utils/WorkerPool.res** (Metric: [Nesting: 1.80, Density: 0.09, Coupling: 0.02] | Drag: 3.11 | LOC: 489/300  🎯 Target: Function: `createPoolSize` (High Local Complexity (4.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D006/verification.json` (files at `_dev-system/tmp/D006/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D006/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/utils/AsyncQueue.res`
- `src/utils/AsyncQueue.res` (9 functions, fingerprint 73547a4fed2786fc7e9fcd7af83fd94984b2fc851b1158f78d87422736d8a37f)
    - Grouped summary:
        - average × 1 (lines: 81)
        - computeStatus × 1 (lines: 90)
        - defaultAdaptiveConfig × 1 (lines: 33)
        - execute × 1 (lines: 300)
        - executeAdaptive × 1 (lines: 110)
        - executeWeighted × 1 (lines: 385)
        - getHeapUsageRatio × 1 (lines: 43)
        - percentile × 1 (lines: 70)
        - toSortedCopy × 1 (lines: 56)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/utils/LoggerTelemetry.res`
- `src/utils/LoggerTelemetry.res` (48 functions, fingerprint d8625090a6c46c9a09b88a0cb9329035e238b3eac3cfd0fc92417785b8de273d)
    - Grouped summary:
        - _ × 1 (lines: 499)
        - adaptiveSamplingScale × 1 (lines: 13)
        - attemptSendBatch × 1 (lines: 267)
        - bandwidthBytesSent × 1 (lines: 12)
        - bandwidthWindowStartMs × 1 (lines: 11)
        - bypassTestEnvCheck × 1 (lines: 8)
        - canUseTelemetryNetwork × 1 (lines: 75)
        - clearSuspensionIfExpired × 1 (lines: 25)
        - deduplicateBatchEntries × 1 (lines: 214)
        - encodeLogEntry × 1 (lines: 186)
        - encodeTelemetryBatch × 1 (lines: 207)
        - flushTelemetry × 1 (lines: 308)
        - flushTimer × 1 (lines: 489)
        - flushWithBeaconOnUnload × 1 (lines: 464)
        - idleFlushPending × 1 (lines: 10)
        - initializeBeforeUnloadListener × 1 (lines: 482)
        - initializeNetworkListener × 1 (lines: 454)
        - isBrowserRuntime × 1 (lines: 486)
        - isFlushing × 1 (lines: 7)
        - isTelemetrySuspended × 1 (lines: 31)
        - isTransportQueueOverflow × 1 (lines: 256)
        - noteTelemetryPayloadBytes × 1 (lines: 77)
        - nowMs × 1 (lines: 23)
        - parseRetryAfterHeaderMs × 1 (lines: 49)
        - processTransportQueue × 1 (lines: 103)
        - queueFillRatio × 1 (lines: 142)
        - runIdle × 1 (lines: 258)
        - sampleRateDebugProd × 1 (lines: 16)
        - sampleRateInfo × 1 (lines: 15)
        - samplingBandwidthBudgetBytesPerSec × 1 (lines: 17)
        - sanitizeJson × 1 (lines: 168)
        - sanitizePayload × 1 (lines: 183)
        - scheduleIdleFlush × 1 (lines: 353)
        - scheduleTransport × 1 (lines: 131)
        - sendTelemetry × 1 (lines: 392)
        - setBypassTestEnvCheck × 1 (lines: 19)
        - shouldQueueForPriority × 1 (lines: 162)
        - shouldSampleByLevel × 1 (lines: 363)
        - shouldSendLowPriority × 1 (lines: 151)
        - startPeriodicFlush × 1 (lines: 490)
        - suspendTelemetry × 1 (lines: 36)
        - suspendTelemetryForMs × 1 (lines: 39)
        - telemetryQueue × 1 (lines: 6)
        - telemetrySuspendedUntil × 1 (lines: 9)
        - transportActive × 1 (lines: 100)
        - transportQueue × 1 (lines: 99)
        - transportQueueOverflowReason × 1 (lines: 101)
        - validateTelemetryResponse × 1 (lines: 62)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/utils/PersistenceLayer.res`
- `src/utils/PersistenceLayer.res` (36 functions, fingerprint 0ff8db8c4c842daa10eccaae13d382c88ffcb286cb4cb60f6aa71a40bcb7fdad)
    - Grouped summary:
        - _ × 1 (lines: 361)
        - autosaveCostSamplesRef × 1 (lines: 55)
        - autosaveCostTargetMs × 1 (lines: 37)
        - autosaveCostWindowSize × 1 (lines: 38)
        - beforeUnloadListener × 1 (lines: 49)
        - checkRecovery × 1 (lines: 469)
        - clearSession × 1 (lines: 410)
        - coalesceMs × 1 (lines: 36)
        - currentSchemaVersion × 1 (lines: 35)
        - debounceMs × 1 (lines: 34)
        - decodeManifest × 1 (lines: 419)
        - decodeMetadataSlice × 1 (lines: 441)
        - encodeMetadataSlice × 1 (lines: 67)
        - extractFromSlice × 1 (lines: 435)
        - getAutosaveCostStats × 1 (lines: 154)
        - handleStateChange × 1 (lines: 363)
        - initSubscriber × 1 (lines: 377)
        - key × 1 (lines: 31)
        - lastQueuedAtMs × 1 (lines: 51)
        - lastSaveTimeout × 1 (lines: 47)
        - lastSavedRevision × 1 (lines: 48)
        - lastSliceSignatureRef × 1 (lines: 53)
        - manifestKey × 1 (lines: 32)
        - normalizeProjectData × 1 (lines: 214)
        - notifyStateChange × 1 (lines: 375)
        - pendingStateRef × 1 (lines: 52)
        - performSave × 1 (lines: 228)
        - performSaveRef × 1 (lines: 54)
        - processQueuedSave × 1 (lines: 190)
        - queueIncrementalSave × 1 (lines: 180)
        - recordAutosaveCost × 1 (lines: 98)
        - signatureOfJson × 1 (lines: 96)
        - sliceKey × 1 (lines: 65)
        - sliceKeyPrefix × 1 (lines: 33)
        - stateGetterRef × 1 (lines: 46)
        - subscriberRef × 1 (lines: 50)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/utils/Retry.res`
- `src/utils/Retry.res` (17 functions, fingerprint b559c2d067bf9371275285c5a39b5105aeb8aa80caa1176201cbb907b90e7e97)
    - Grouped summary:
        - calculateDelay × 1 (lines: 38)
        - checkAndConsumeBudget × 1 (lines: 200)
        - classifyError × 1 (lines: 107)
        - computeDelay × 1 (lines: 182)
        - defaultBudgetConfig × 1 (lines: 30)
        - defaultConfig × 1 (lines: 21)
        - defaultShouldRetry × 1 (lines: 136)
        - execute × 1 (lines: 395)
        - getRemainingBudget × 1 (lines: 247)
        - hasDeadline × 1 (lines: 180)
        - isAbortError × 1 (lines: 90)
        - isRetryableStatus × 1 (lines: 94)
        - loop × 1 (lines: 265)
        - parseHttpStatusCode × 1 (lines: 65)
        - parseRetryAfterSeconds × 1 (lines: 74)
        - retryBudgets × 1 (lines: 36)
        - waitForDelay × 1 (lines: 146)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/utils/WorkerPool.res`
- `src/utils/WorkerPool.res` (16 functions, fingerprint 71cfa2c85ce54d9a617eed3a1d74b096d37e3efacbec335776bc605cfd7fa0f6)
    - Grouped summary:
        - bindWorkerHandlers × 1 (lines: 144)
        - createPoolSize × 1 (lines: 44)
        - ensurePool × 1 (lines: 215)
        - extractExifWithWorker × 1 (lines: 462)
        - fingerprintWithWorker × 1 (lines: 296)
        - generateTinyWithWorker × 1 (lines: 398)
        - poolRef × 1 (lines: 42)
        - processFullWithWorker × 1 (lines: 243)
        - removeExifWaiter × 1 (lines: 114)
        - removeFingerprintWaiter × 1 (lines: 70)
        - removeFullWaiter × 1 (lines: 128)
        - removeTinyWaiter × 1 (lines: 98)
        - removeValidateWaiter × 1 (lines: 84)
        - shutdown × 1 (lines: 453)
        - takeWorker × 1 (lines: 58)
        - validateImageWithWorker × 1 (lines: 347)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
