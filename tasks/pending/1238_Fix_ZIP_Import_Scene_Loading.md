# Task 1238: Fix ZIP Import Scene Loading & Test Selector

## Objective
Fix the issue where scenes are not visible in the sidebar after a successful ZIP import and correct the E2E test selector.

## Problem Analysis
- **Selector Mismatch**: The E2E test `tests/e2e/desktop-import.spec.ts` uses the selector `.scene-list-item`, but the actual class in `SceneItem.res` is `scene-item`.
- **Virtualization Delay**: The `SceneList` is virtualized. If the initial render happens before the container is measured, it might show 0 items. The test might be checking too early or using an incorrect selector that doesn't account for the list rendering after state hydration.

## Proposed Solution
- Update `tests/e2e/desktop-import.spec.ts` to use `.scene-item`.
- Add a short `expect(projectNameInput).toHaveValue(...)` check before counting scenes to ensure state hydration has finished.
- Ensure `SceneList.res` handles initial measurement correctly or provide a minimum height for the virtualized container to trigger an initial item load.

## Acceptance Criteria
- [ ] Importing a valid ZIP tour results in scenes appearing in the sidebar.
- [ ] `tests/e2e/desktop-import.spec.ts` passes.
