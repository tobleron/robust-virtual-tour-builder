---
description: Debugging and Logging Standards
---

# Debugging and Logging Standards

Follow these steps to ensure consistent logging and observational capabilities across the project.

## 1. Global Master Switch
The source of truth for all architectural logging is `src/constants.js`.

```javascript
/* src/constants.js */
export const DEBUG_LOG_LEVEL = 'info'; // Set to 'debug' for granular dev logs
```

## 2. Using the Debug Utility
Avoid `console.log`. Use the `Debug` module from `src/utils/Debug.js`.

- `Debug.debug(module, message, data)`: For high-frequency developer logs (e.g., animation frames, math stalls).
- `Debug.info(module, message, data)`: For major lifecycle events (e.g., "UPLOAD_BATCH_START", "PROJECT_LOADED").
- `Debug.warn(module, message, data)`: For soft failures or unexpected states.
- `Debug.error(module, message, data)`: For critical logic failures.

## 3. Progress Bar Visibility
Any operation that takes longer than **250ms** must report progress to the user.

### Standard Phasing
For multi-step operations (like uploads or exports), use explicit phase naming:
1. `updateProgress(0, "Phase 1: Starting...", true, "Initialization")`
2. `updateProgress(30, "Phase 2: Working...", true, "Processing")`
3. `updateProgress(95, "Phase 3: Finalizing...", true, "Cleanup")`
4. `updateProgress(100, "Done", false)`

## 4. Performance Auditing
Use `performance.now()` to wrap critical sections and log their duration using `Debug.info`.

```javascript
const start = performance.now();
await doWork();
Debug.info('Module', 'WORK_COMPLETE', { duration: performance.now() - start });
```

## 5. Telemetry
The `Debug` utility automatically sends all logs with severity >= `DEBUG_LOG_LEVEL` to the backend `logs/telemetry.log`. Ensure the backend is running to capture these.
