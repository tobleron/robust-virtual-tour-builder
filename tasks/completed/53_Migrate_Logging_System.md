---
description: Migrate Debug and Logger utilities to a unified ReScript Logger module
---

# Objective
Migrate the existing JavaScript logging infrastructure (`src/utils/Debug.js` and `src/utils/Logger.js`) to a unified, type-safe ReScript module `src/utils/Logger.res`. This ensures all telemetry, debugging, and error reporting are strictly typed and consistent across the application.

# Context
Currently, logging is split between `Debug.js` (telemetry, complex logic) and `Logger.js` (simple buffer). Both are untyped JavaScript, leading to potential runtime issues and inconsistent usage.

# Requirements

1.  **Create `src/utils/Logger.res`**:
    *   Implement log levels as a Variant/Polyvariant (e.g., `#Debug | #Info | #Warn | #Error`).
    *   Implement module names as a Variant or restricted string type to prevent typos.
    *   Port functionality from `Debug.js`:
        *   `enable/disable` logic.
        *   `enableModule/disableModule`.
        *   Telemetry transmission (`sendTelemetry`).
        *   Rolling buffer management.
        *   Console styling (using `%c`).
    *   Port functionality from `Logger.js`:
        *   Global app log buffer for UI reporting.
        *   `window.onerror` and `window.onunhandledrejection` bindings (using `Rb.Nullable` logic if needed).

2.  **Expose to Window**:
    *   Ensure the `Logger` is exposed to `window.DEBUG` for console access, maintaining backward compatibility for debugging sessions.

3.  **Refactor Consumers**:
    *   Search for all usages of `Debug.log` or imports from `./utils/Debug.js`.
    *   Replace them with `Logger.info`, `Logger.debug`, etc.
    *   Likely consumers: `VideoEncoder.res`, `Navigation.res`, `App.res`.

4.  **Cleanup**:
    *   Delete `src/utils/Debug.js`.
    *   Delete `src/utils/Logger.js`.

5.  **Verification**:
    *   Verify checking `window.DEBUG` in console works.
    *   Verify telemetry requests are still sent to the backend.
