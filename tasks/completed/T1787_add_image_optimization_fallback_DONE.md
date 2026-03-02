# T1787 - Add Image Optimization Main-Thread Fallback

## Assignee: Gemini
## Capacity Class: A
## Objective
Ensure users on older browsers (Safari < 16.4, older Chrome) can still upload images by providing a graceful fallback to main-thread `Canvas` optimization if `OffscreenCanvas` or `Worker` support is missing.

## Context
The v5.2.0 update relies heavily on `WorkerPool` and `OffscreenCanvas`. If these APIs are missing, the upload will fail. We need a safety net.

## Strategy
1.  **Detect Support**: Check for `window.OffscreenCanvas` and `createImageBitmap` support at runtime.
2.  **Implement Fallback**: In `ImageOptimizer.res`, if support is missing or if the Worker returns a specific "Unsupported" error, fall back to the legacy main-thread `canvas.drawImage` method.
3.  **Telemetry**: Log a warning when fallback is triggered so we can track legacy browser usage.

## Boundary
- `src/utils/ImageOptimizer.res`
- `src/utils/WorkerPool.res`
- `src/utils/Constants.res`
