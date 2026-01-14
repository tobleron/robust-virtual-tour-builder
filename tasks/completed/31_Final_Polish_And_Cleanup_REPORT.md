---
description: Final Polish, Deprecation Fixes, and System Verification
---

# Task 31: Final Polish & Optimization

## Objective (Completed)
Clean up the codebase after the extensive ReScript migration. This involves resolving all compilation warnings (deprecations, unused variables), verifying system integrity, and ensuring a clean production build.

## Context
We have successfully migrated the core logic, viewer systems, and adapters to ReScript. However, the build output shows numerous deprecation warnings (e.g., `Js.Int.toString` -> `Int.toString`, `Js.Float.toFixed` -> `Float.toFixed`) and unused variables. These need to be resolved to ensure a maintainable and high-quality codebase.

## Detailed Steps

1.  **Automated Migration**
    - [ ] Run `npx rescript-tools migrate-all src` to automatically fix `Js.*` deprecations.
    - [ ] Run `npx rescript-tools check src` (if available) or rely on compiler output to verify fixes.

2.  **Manual Cleanup**
    - [ ] Review compilation output for remaining warnings.
    - [ ] Fix "unused variable" warnings by renaming with `_` prefix or removing code.
    - [ ] Fix any remaining `Js.Exn` usage that wasn't auto-migrated (e.g., to `JsExn`).
    - [ ] Remove any leftover `.js` files in `src/systems` or `src/components` that are no longer used (if any missed).

3.  **System Verification**
    - [ ] Verify `TeaserManager.res` compilation and logic (ensure no regressions from Task 29).
    - [ ] Verify `UploadProcessor.res` compilation (ensure `Resizer` integration from Task 30 is solid).
    - [ ] Ensure `ReBindings.res` is clean and minimal.

4.  **Final Build Check**
    - [ ] Run `npm run res:build` and ensure **zero warnings** (or strictly justified ones).

## Testing
- **Compilation**: The primary test is a clean build log.
- **Runtime**: Since we can't run the UI here, we rely on the strict type system.

## Rollback Plan
- Revert changes to specific files if migration causes semantic breakage (unlikely for syntax migrations).
