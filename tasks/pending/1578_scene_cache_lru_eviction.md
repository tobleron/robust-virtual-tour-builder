# Task: LRU Eviction & Memory Pressure Management for SceneCache

## Objective
Implement bounded LRU eviction in `SceneCache.res` and add browser memory pressure monitoring to prevent unbounded blob URL accumulation and eventual OOM crashes in large tours (500+ scenes).

## Problem Statement
`SceneCache.res` uses three unbounded `Belt.MutableMap.String` maps (`cache`, `sourceUrls`, `thumbUrls`). For a 500-scene tour, each scene holds a blob URL for its source (~20-80MB), thumbnail (~50KB), and snapshot (~200KB). Without eviction, the browser retains all blob references in memory. The `clearAll()` method exists but is only called on project reset. During prolonged editing sessions, memory grows monotonically, eventually causing browser tab crashes.

## Acceptance Criteria
- [ ] Replace `Belt.MutableMap.String` with a custom `LruCache` module that tracks access recency and evicts least-recently-used entries when exceeding configurable bounds
- [ ] Source URL cache: max 30 entries (only active + adjacent scenes need source blobs)
- [ ] Thumbnail cache: max 100 entries (sidebar visible range + buffer)
- [ ] Snapshot cache: max 50 entries (simulation/teaser working set)
- [ ] Eviction calls `URL.revokeObjectURL` on evicted entries to release memory
- [ ] Add `Performance.measureUserAgentSpecificMemory()` polling (where supported) for proactive eviction when memory exceeds 500MB
- [ ] Integrate with `StateDensityMonitor.res` to trigger aggressive eviction at `High` density level
- [ ] No regressions in scene switching latency (p95 ≤ 1500ms)

## Technical Notes
- **Files**: New `src/utils/LruCache.res`, modified `src/core/SceneCache.res`, modified `src/utils/StateDensityMonitor.res`
- **Pattern**: Doubly-linked list + hash map for O(1) get/put/evict
- **Measurement**: Memory growth ratio during 200-scene rapid navigation should stay ≤ 2.2x (baseline budget)
