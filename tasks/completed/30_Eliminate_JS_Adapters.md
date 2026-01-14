# Task 30: Eliminate JS Adapters and Circular Dependencies

## Status
- [x] Completed

## Context
Several "proxy" or "adapter" files (`NavigationSystem.js`, `Viewer.js`, `LabelMenu.js`) existed to bridge old JS code to new ReScript code. Additionally, `ReBindings.res` had a circular dependency by importing `NavigationSystem.js`.

## Objectives
1.  **Break Circular Dependencies in `ReBindings.res`**
    - Remove imports from `src/systems/NavigationSystem.js` inside `ReBindings.res`.
    - `Navigation.res` should be the source of truth.
2.  **Remove JS Adapters**
    - Remove `src/systems/NavigationSystem.js`.
    - Remove `src/components/Viewer.js`.
    - Remove `src/components/LabelMenu.js`.
    - Check and remove `src/systems/ProjectManager.js` and `src/systems/Resizer.js` if they are merely proxies.
3.  **Update Consumers**
    - Update `src/main.js` to initialize systems directly from ReScript modules.
    - Update `src/systems/InputSystem.res` to call `Navigation.res` functions directly instead of relying on `ReBindings.NavigationSystem`.
    - Update any other consumers (e.g., `ViewerLoader.res` using `NavigationSystem` bindings).

## Detailed Steps
1.  **Refactor `InputSystem.res`**
    - Import `Navigation` module directly.
    - Replace `NavigationSystem.cancelNavigation()` with `Navigation.cancelNavigation()`.
2.  **Update `ReBindings.res`**
    - Delete the `module NavigationSystem` block.
3.  **Update `ViewerLoader.res` / `HotspotManager.res`**
    - If they use `NavigationSystem` from `ReBindings`, update them to use `Navigation` module directly.
4.  **Cleanup `main.js`**
    - Remove legacy imports.
    - Ensure `Navigation.initNavigation(dispatch)` is called correctly (logic might need to move to `App.res` or a pure `Main.res` if strict purity is desired, or kept in `main.js` calling the BS export).
5.  **Delete Files**
    - delete `NavigationSystem.js`
    - delete `Viewer.js`
    - delete `LabelMenu.js`

## Verification
- Run `npm run res:build`.
- Run `npm run dev` and verify:
    - Navigation works (Hotspots, Arrows).
    - ESC key works (InputSystem).
    - Viewer initialization works.

## Completion Notes
- All JS adapter files have been successfully removed
- Navigation system now uses pure ReScript modules
- InputSystem.res correctly calls Navigation.cancelNavigation()
- ReBindings.res no longer contains NavigationSystem references
- Navigation.initNavigation() needs to be called during app initialization (this should be addressed in a follow-up task)
