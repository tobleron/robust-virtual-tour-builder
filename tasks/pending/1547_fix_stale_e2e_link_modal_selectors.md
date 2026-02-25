# 1547 — Fix Stale E2E Test Selectors (LinkModal Scene Options)

## Priority: P1 — Test Debt

## Objective
Update E2E tests that use stale `[data-testid="scene-option"]` button selectors to use the correct `#link-target` select dropdown that exists in the actual `LinkModal.res` implementation.

## Context
The production `LinkModal.res` uses a `<select id="link-target">` dropdown for destination selection. However, several E2E tests reference `[data-testid="scene-option"]` buttons that do not exist in the current implementation. These tests pass silently because they use `.isVisible()` guards that skip the assertion when the element isn't found, providing false confidence in test coverage.

## Affected Tests
| File | Issue |
|------|-------|
| `tests/e2e/hotspot-advanced.spec.ts` | Uses `[data-testid="scene-option"]` for link target selection |
| `tests/e2e/timeline-management.spec.ts` | Same stale selector pattern |

## Acceptance Criteria
- [ ] Identify ALL instances of `[data-testid="scene-option"]` in E2E tests
- [ ] Replace with `page.selectOption('#link-target', targetValue)` matching actual modal implementation
- [ ] Verify the tests actually execute the link creation flow (not silently skipping via guards)
- [ ] Run the affected tests to confirm they interact with the real modal
- [ ] Document any tests that were silently passing without testing what they claim

## Implementation Guide
1. Search all E2E tests for `scene-option`
2. For each occurrence, replace with the correct selector:
   ```ts
   // Before (stale):
   await page.locator('[data-testid="scene-option"]').first().click();
   
   // After (correct):
   await page.selectOption('#link-target', sceneName);
   ```
3. Ensure the "Save Link" button click remains: `page.getByRole('button', { name: 'Save Link' }).click()`

## Files to Modify
- `tests/e2e/hotspot-advanced.spec.ts`
- `tests/e2e/timeline-management.spec.ts`
- Potentially others found via search
