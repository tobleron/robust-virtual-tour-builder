# Task: AsyncQueue Backpressure Signals & Adaptive Concurrency

## Objective
Implement adaptive concurrency control in `AsyncQueue.res` that dynamically adjusts parallelism based on real-time backend response latency, error rate, and system memory pressure.

## Problem Statement
`AsyncQueue.res` uses a fixed `maxConcurrency` which is determined at call time. During bulk uploads, if the backend becomes slow (due to CPU saturation from image processing), maintaining full concurrency amplifies the pressure. Conversely, if the backend is underloaded, the fixed concurrency leaves throughput on the table. The `executeWeighted` variant adds weight-based budgeting but doesn't adapt to runtime conditions.

## Acceptance Criteria
- [x] Implement AIMD (Additive Increase, Multiplicative Decrease) concurrency control:
  - Increase concurrency by 1 after every N successful completions without errors
  - Halve concurrency on any error or when average latency exceeds a threshold
- [x] Add latency tracking: measure p50/p95 of worker completion times per batch
- [x] Add error-rate tracking: if error rate exceeds 20% in a window, reduce concurrency to minimum (1)
- [x] Expose backpressure signal: when queue depth > 2x concurrency, emit `Logger.warn` with queue health metrics
- [x] Add memory pressure integration: reduce concurrency if `performance.memory` (where available) shows heap > 80% utilized
- [x] Make AIMD parameters configurable per call site (upload vs export have different optimal profiles)
- [x] Preserve existing `execute` and `executeWeighted` APIs as wrappers with AIMD disabled by default

## Technical Notes
- **Files**: `src/utils/AsyncQueue.res`
- **Pattern**: TCP-inspired AIMD with configurable initial/min/max concurrency and measurement windows
- **Risk**: Low — new function `executeAdaptive` with existing functions unchanged
- **Measurement**: Bulk upload throughput should self-optimize: faster on fast backends, gentler on slow backends
