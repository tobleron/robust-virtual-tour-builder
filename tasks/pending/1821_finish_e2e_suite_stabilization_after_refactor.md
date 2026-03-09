# 1821 Finish E2E Suite Stabilization After Refactor

## Objective
Finish aligning the Playwright E2E suite with the current post-refactor app behavior so `npm run test:e2e` can run without stale-selector, stale-fixture, or stale-flow failures.

## Current State
- Frontend unit tests are already current and passing.
- `npm run test:frontend` passes at `196` files / `999` tests.
- Builder boot E2E setup is already updated to use `/builder` instead of the legacy root path.
- Accessibility E2E was already repaired and is currently green for the active cases in `tests/e2e/accessibility-comprehensive.spec.ts`.
- Shared E2E helpers were already modernized in `tests/e2e/e2e-helpers.ts`:
  - checked-in zip fixture path for standard project
  - builder-shell boot wait
  - updated modal action handling for `Continue`
  - current scene-list locator support
  - viewer-ready helper support

## Remaining Work

### 1. Finish `auto-forward-comprehensive.spec.ts`
- The first test now passes:
  - `should create auto-forward link via emerald double-chevron button`
- The next blocker is:
  - `should navigate auto-forward chain during simulation with waypoint animation`
- Current issue:
  - the test was partially rewritten away from stale project fixtures and stale selectors
  - it still fails while trying to surface the current auto-forward control in the hotspot action UI
  - the current failure is not app boot anymore; it is test-flow mismatch
- Required fix:
  - inspect the current hotspot action menu contract after link creation
  - align the selector and interaction sequence with the actual current compact hotspot action UI
  - keep using current helpers and current upload-driven setup rather than reintroducing stale fixture assumptions

### 2. Resume full-suite Playwright stabilization after `auto-forward`
- After `auto-forward-comprehensive.spec.ts` is green, rerun:
  - `npx playwright test --max-failures=1`
- Continue fixing the suite in real failure order.
- Prioritize stale assumptions caused by refactor or UI evolution:
  - legacy `.scene-item` assumptions where scene buttons are now the actual stable target
  - stale ignored artifact paths under `artifacts/`
  - stale modal selectors and startup sentinels
  - stale viewer/linking flow assumptions

### 3. Normalize shared E2E selectors/helpers where drift is repeated
- Continue centralizing recurring compatibility fixes in `tests/e2e/e2e-helpers.ts` when the same break pattern shows up in multiple specs.
- Expected likely candidates:
  - scene selection
  - viewer readiness
  - project-load hydration
  - link-modal/open-link flow
  - export and processing status waits

### 4. Keep product-side accessibility fixes intact
- Do not regress the notification live-region work already added in:
  - `src/components/NotificationCenter.res`
- Accessibility spec should remain green while the broader suite is repaired.

## Verified Progress Already Completed
- `tests/e2e/accessibility-comprehensive.spec.ts` active cases pass.
- `tests/e2e/auto-forward-comprehensive.spec.ts`
  - first test passes after:
    - current scene locator alignment
    - current hotspot placement flow
    - current save button targeting
- `tests/e2e/e2e-helpers.ts` already contains current builder boot + fixture alignment work.

## Known Technical Findings
- A stale frontend dev server on port `3000` caused one round of misleading Playwright instability; that was environmental, not product logic.
- Some old Playwright failures were caused by missing ignored `artifacts/*` files and were already migrated to checked-in `tests/e2e/fixtures/*`.
- Some older tests assumed a dialog-first add-link flow that no longer matches the current builder state exactly.
- The current hotspot action UI is compact and stateful, so tests must use current visible controls rather than older modal-era assumptions.

## Acceptance Criteria
- `tests/e2e/auto-forward-comprehensive.spec.ts` is fully green on Chromium.
- `npx playwright test --max-failures=1` can be advanced repeatedly without immediately failing on already-known stale assumptions from this task.
- `npm run test:e2e` is materially closer to green, with the next remaining failures documented if total closure is not finished in the same session.
- No regression to:
  - `npm run test:frontend`
  - the repaired accessibility E2E coverage

## Verification
- `npm run test:frontend`
- `npx playwright test tests/e2e/auto-forward-comprehensive.spec.ts --project=chromium`
- `npx playwright test --max-failures=1`
- `npm run test:e2e` once the failure chain is sufficiently cleared

## Files Already Involved
- `tests/e2e/e2e-helpers.ts`
- `tests/e2e/accessibility-comprehensive.spec.ts`
- `tests/e2e/auto-forward-comprehensive.spec.ts`
- `src/components/NotificationCenter.res`

## Notes
- This is a follow-up to active task `1820_unit_test_alignment_and_e2e_stabilization.md`.
- Do not archive `1820` until the user explicitly signs off on that active task. This pending task is only the queued continuation for the remaining unresolved E2E work.
