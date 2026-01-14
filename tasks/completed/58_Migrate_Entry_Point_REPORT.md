---
description: Migrate main.js entry point to ReScript
---

# Objective
Convert the final JavaScript entry point `src/main.js` to `src/Main.res`.

# Context
`main.js` bootstraps React, initializes the Logger, and mounts the App. Keeping it in JS allows loose typing at the very root.

# Requirements

1.  **Create `src/Main.res`**:
    *   Use `ReactDOM.Client` bindings (already present in project usually, or `ReBindings.res`).
    *   Port initialization logic:
        *   `Logger.init()`.
        *   `AudioSystem.setup()`.
        *   `VisualPipeline.init()`.
        *   `InputSystem.init()`.
    *   Mount the `<App />` component.

2.  **Build Config**:
    *   Ensure `bsconfig.json` (or `rescript.json`) compiles `Main.res`.
    *   Update `index.html` to point to `src/Main.bs.js` instead of `src/main.js` (or update the Vite/build entry point).

3.  **Cleanup**:
    *   Delete `src/main.js`.

4.  **Verification**:
    *   App starts up correctly.
    *   Console shows "Application Initialized" (from Logger).
