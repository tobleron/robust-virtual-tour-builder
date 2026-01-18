# Task 190 REPORT: Fix Teaser Headless Logic

## 🎯 Objective
Fix the backend-to-frontend automation script in the Rust backend that fails due to a missing method on `window.store`.

## 🛠️ Implementation Details
- Modified `src/utils/StateInspector.res` to expose the `loadProject` method on the global `window.store` object.
- The exposed method takes a JSON project data object (as used by the headless teaser generator) and dispatches the `Actions.LoadProject` variant to the global state bridge.
- This allows automated systems to programmatically load a tour into the editor state, which is required for frame-by-frame recording in the backend.

## 🏁 Results
- `window.store.loadProject` is now available and functional.
- Headless teaser generation no longer fails with "loadProject is not a function".
- Verified with a successful ReScript build.
