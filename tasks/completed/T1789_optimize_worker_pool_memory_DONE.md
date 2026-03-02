# T1789 - Optimize Worker Pool Memory Usage

## Assignee: Gemini
## Capacity Class: A
## Objective
Prevent memory crashes on low-end devices by dynamically adjusting the Worker Pool size based on available device memory and image size.

## Context
Currently, the pool spawns `hardwareConcurrency - 1` workers. On an 8-core machine with 8GB RAM processing 12K images, this could spawn 7 workers each consuming 500MB, leading to a crash.

## Strategy
1.  **Device Sensing**: Use `navigator.deviceMemory` (if available) to estimate RAM.
2.  **Dynamic Sizing**: Limit pool size conservatively (e.g., max 2-3 workers for large images on low-RAM devices).
3.  **Monitoring**: Add memory pressure telemetry if possible.

## Boundary
- `src/utils/WorkerPool.res`
- `src/utils/Constants.res`
