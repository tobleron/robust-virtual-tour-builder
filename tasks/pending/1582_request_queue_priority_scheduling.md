# Task: Priority-Aware Request Queue with Starvation Prevention

## Objective
Upgrade `RequestQueue.res` from a simple FIFO queue to a priority-based scheduler with starvation prevention, ensuring critical operations (navigation, scene load) always take precedence over background work (thumbnail enhancement, telemetry).

## Problem Statement
The current `RequestQueue.res` uses a flat FIFO array with `maxConcurrent=6` and `maxQueued=256`. When the upload pipeline saturates all 6 slots, navigation scene-load requests are queued behind upload chunks, causing visible scene-switching latency. There is no priority differentiation between critical user-facing requests and background ambient operations.

## Acceptance Criteria
- [ ] Implement 3-tier priority: `Critical` (navigation, scene load), `Normal` (upload, save/export), `Background` (thumbnail enhancement, telemetry, geocoding)
- [ ] Critical requests can preempt: if all 6 slots are full with Normal/Background work, a Critical request bumps the concurrency limit temporarily (+2 burst slots)
- [ ] Add starvation prevention: Background tasks get promoted to Normal after 30s of queuing, Normal to Critical after 60s
- [ ] Add queue depth per-priority as telemetry (`Logger.debug` on depth changes)
- [ ] Preserve existing `pause()/resume()` and `handleRateLimit()` semantics
- [ ] Preserve existing `scheduleWithRetry` API with optional `~priority` parameter (default: Normal)

## Technical Notes
- **Files**: `src/utils/RequestQueue.res`
- **Pattern**: Three separate arrays (or a single sorted array with priority comparison), process highest-priority first
- **Risk**: Medium — must ensure upload batches aren't starved by navigation, and vice versa
- **Measurement**: Scene-switch latency during concurrent 50-image upload should remain ≤ 1500ms (p95)
