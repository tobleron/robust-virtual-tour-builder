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

- [ ] - **../../src/utils/AsyncQueue.res** (Metric: [Nesting: 3.60, Density: 0.13, Coupling: 0.02] | Drag: 4.87 | LOC: 465/300  🎯 Target: Function: `toSortedCopy` (High Local Complexity (6.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/utils/LoggerTelemetry.res** (Metric: [Nesting: 3.00, Density: 0.21, Coupling: 0.06] | Drag: 4.35 | LOC: 441/300  🎯 Target: Function: `parseRetryAfterHeaderMs` (High Local Complexity (4.8). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/utils/PersistenceLayer.res** (Metric: [Nesting: 3.00, Density: 0.08, Coupling: 0.07] | Drag: 4.25 | LOC: 423/300  🎯 Target: Function: `normalizeProjectData` (High Local Complexity (2.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D006/verification.json` (files at `_dev-system/tmp/D006/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D006/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/utils/AsyncQueue.res`
- `src/utils/AsyncQueue.res` (9 functions, fingerprint 51330da07cd5d8b5fa52e17eb2b94499d1ad876df901eb721be240242bea220f)
    - Grouped summary:
        - average × 1 (lines: 81)
        - computeStatus × 1 (lines: 90)
        - defaultAdaptiveConfig × 1 (lines: 33)
        - execute × 1 (lines: 289)
        - executeAdaptive × 1 (lines: 113)
        - executeWeighted × 1 (lines: 374)
        - getHeapUsageRatio × 1 (lines: 43)
        - percentile × 1 (lines: 70)
        - toSortedCopy × 1 (lines: 56)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/utils/LoggerTelemetry.res`
- `src/utils/LoggerTelemetry.res` (49 functions, fingerprint 5a0c4e5f9f0fce023a11459b52997fb3726cd8bf1ba89f25e49666dcbe918895)
    - Grouped summary:
        - _ × 3 (lines: 490, 491, 492)
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
        - flushTimer × 1 (lines: 480)
        - flushWithBeaconOnUnload × 1 (lines: 462)
        - idleFlushPending × 1 (lines: 10)
        - initializeBeforeUnloadListener × 1 (lines: 476)
        - initializeNetworkListener × 1 (lines: 452)
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
        - sendTelemetry × 1 (lines: 390)
        - setBypassTestEnvCheck × 1 (lines: 19)
        - shouldQueueForPriority × 1 (lines: 162)
        - shouldSampleByLevel × 1 (lines: 363)
        - shouldSendLowPriority × 1 (lines: 151)
        - startPeriodicFlush × 1 (lines: 481)
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
- `src/utils/PersistenceLayer.res` (31 functions, fingerprint 6cd6875e8e2ae2b1f0187baa38693e6352561060a0a57f8ac4e5b601522a6ca0)
    - Grouped summary:
        - _ × 1 (lines: 241)
        - beforeUnloadListener × 1 (lines: 46)
        - checkRecovery × 1 (lines: 351)
        - clearSession × 1 (lines: 295)
        - coalesceMs × 1 (lines: 36)
        - currentSchemaVersion × 1 (lines: 35)
        - debounceMs × 1 (lines: 34)
        - decodeManifest × 1 (lines: 304)
        - decodeMetadataSlice × 1 (lines: 323)
        - encodeMetadataSlice × 1 (lines: 55)
        - extractFromSlice × 1 (lines: 317)
        - handleStateChange × 1 (lines: 243)
        - initSubscriber × 1 (lines: 257)
        - key × 1 (lines: 31)
        - lastQueuedAtMs × 1 (lines: 48)
        - lastSaveTimeout × 1 (lines: 44)
        - lastSavedRevision × 1 (lines: 45)
        - lastSliceSignatureRef × 1 (lines: 50)
        - manifestKey × 1 (lines: 32)
        - normalizeProjectData × 1 (lines: 115)
        - notifyStateChange × 1 (lines: 255)
        - pendingStateRef × 1 (lines: 49)
        - performSave × 1 (lines: 129)
        - performSaveRef × 1 (lines: 51)
        - processQueuedSave × 1 (lines: 91)
        - queueIncrementalSave × 1 (lines: 86)
        - signatureOfJson × 1 (lines: 84)
        - sliceKey × 1 (lines: 53)
        - sliceKeyPrefix × 1 (lines: 33)
        - stateGetterRef × 1 (lines: 43)
        - subscriberRef × 1 (lines: 47)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
