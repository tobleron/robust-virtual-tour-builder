# Task: Offload Heavy Client-Side Computation to Web Workers

## Objective
Move CPU-intensive client-side operations (fingerprinting, image validation, thumbnail generation, EXIF parsing) off the main thread into dedicated Web Workers to eliminate UI jank during bulk uploads and large project operations.

## Problem Statement
Currently, `FingerprintService.res`, `ImageValidator.res`, `ThumbnailGenerator.res`, and `ExifParser.res` all execute on the main thread. For bulk uploads of 50+ high-resolution panoramas (each 20-80MB), these synchronous CPU-bound operations cause long tasks (>50ms) that degrade UI responsiveness. The `AsyncQueue.res` manages concurrency at the Promise level but doesn't address main-thread saturation.

## Acceptance Criteria
- [ ] Create a shared `ImageWorker` (Web Worker) that handles: fingerprint hashing, format validation, thumbnail projection, and EXIF extraction
- [ ] Implement a `WorkerPool` manager with configurable pool size (default: `navigator.hardwareConcurrency - 1`, min: 1)
- [ ] Replace direct calls in `UploadProcessorLogic.res` with worker-delegated equivalents
- [ ] Add AbortSignal propagation to workers so cancelled uploads terminate worker tasks
- [ ] Fallback: If workers fail to initialize (CSP/browser restrictions), transparently fall back to main-thread execution
- [ ] Performance target: Zero long tasks (>50ms) during fingerprinting/validation phase of a 100-image upload

## Technical Notes
- **Files**: New `src/workers/ImageWorker.res`, new `src/utils/WorkerPool.res`, modified `src/systems/UploadProcessorLogic.res`, `src/systems/FingerprintService.res`
- **Pattern**: Structured message passing with transferable `ArrayBuffer` objects to avoid serialization overhead
- **Measurement**: Performance observer long-task count before/after on 100-image upload
- **CSP**: Workers must comply with existing CSP policy (no `eval`, no inline scripts)
