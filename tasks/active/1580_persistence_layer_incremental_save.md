# Task: Incremental State Persistence with Delta Serialization

## Objective
Replace full-state serialization in `PersistenceLayer.res` with incremental delta persistence to reduce IndexedDB write latency and main-thread blocking during auto-save.

## Problem Statement
`PersistenceLayer.performSave` serializes the **entire** project state (all scenes, hotspots, timeline, inventory) on every structural mutation after a 2s debounce. For a 500-scene project with 2000 hotspots, this JSON serialization can take 50-200ms, blocking the main thread even when `requestIdleCallback` is used (since idle callbacks have a 50ms default deadline). The `JsonParsers.Encoders.project` call is synchronous and proportional to state size.

## Acceptance Criteria
- [ ] Implement structural diffing: track which top-level state keys changed since last save (scenes vs hotspots vs timeline vs metadata)
- [ ] Serialize only changed slices and write them as separate IndexedDB keys with a manifest entry
- [ ] On recovery, reconstruct full state from assembled slices
- [ ] Add `structuredClone` offloading: serialize state snapshot on a microtask boundary to avoid blocking the main thread
- [ ] Implement write coalescing: if multiple saves fire within 500ms, merge them into a single write
- [ ] Fallback: Full serialization if delta tracking falls out of sync (safety invariant with `Logger.warn`)
- [ ] Auto-save latency target: < 10ms main-thread cost for incremental saves

## Technical Notes
- **Files**: `src/utils/PersistenceLayer.res`, `src/core/JsonParsersEncoders.res`
- **Pattern**: Change-tracking using `structuralRevision` per domain slice (scene revision, hotspot revision, etc.)
- **Risk**: Medium — recovery path must handle partial writes (use IndexedDB transactions for atomicity)
- **Measurement**: Performance.now() timing around persistSave calls on 500-scene project
