# Task: Incremental State Persistence with Delta Serialization

## Objective
Replace full-state serialization in `PersistenceLayer.res` with incremental delta persistence to reduce IndexedDB write latency and main-thread blocking during auto-save.

## Problem Statement
`PersistenceLayer.performSave` serializes the **entire** project state (all scenes, hotspots, timeline, inventory) on every structural mutation after a 2s debounce. For a 500-scene project with 2000 hotspots, this JSON serialization can take 50-200ms, blocking the main thread even when `requestIdleCallback` is used (since idle callbacks have a 50ms default deadline). The `JsonParsers.Encoders.project` call is synchronous and proportional to state size.

## Acceptance Criteria
- [x] Implement structural diffing: track which top-level state keys changed since last save (scenes vs hotspots vs timeline vs metadata)
- [x] Serialize only changed slices and write them as separate IndexedDB keys with a manifest entry
- [x] On recovery, reconstruct full state from assembled slices
- [x] Add `structuredClone` offloading: serialize state snapshot on a microtask boundary to avoid blocking the main thread
- [x] Implement write coalescing: if multiple saves fire within 500ms, merge them into a single write
- [x] Fallback: Full serialization if delta tracking falls out of sync (safety invariant with `Logger.warn`)
- [x] Auto-save latency target: < 10ms main-thread cost for incremental saves

## Technical Notes
- **Files**: `src/utils/PersistenceLayer.res`, `src/core/JsonParsersEncoders.res`
- **Pattern**: Change-tracking using `structuralRevision` per domain slice (scene revision, hotspot revision, etc.)
- **Risk**: Medium — recovery path must handle partial writes (use IndexedDB transactions for atomicity)
- **Measurement**: Performance.now() timing around persistSave calls on 500-scene project

## Verification Log
- `npm run res:build` ✅
- `npm run test:frontend` ✅ (180 files, 898 tests)
- Playwright runtime budget run (`tests/e2e/perf-budgets.spec.ts`) ✅
  - bulk upload fixture latency: `45077ms` with `29` imported scenes
  - metrics file: `artifacts/perf-budget-metrics.json`
- Code-level checks:
  - Incremental slices (`inventory`, `sceneOrder`, `timeline`, `metadata`) with per-slice signatures.
  - Manifest + legacy envelope dual-write for recovery fallback.
  - Recovery path reassembles project from slices and warns/falls back to legacy payload when needed.
  - Write coalescing window `coalesceMs = 500`.
  - Snapshot cloning via `structuredClone` with safe fallback.
- Direct autosave benchmark test:
  - `tests/unit/PersistenceLayer_v.test.res` asserts `averageMs <= 10.0` for controlled incremental saves.
  - Included in full frontend suite pass (`180 files`, `898 tests`).
