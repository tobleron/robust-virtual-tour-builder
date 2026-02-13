# 1322: E2E Test - Navigation & Rapid Scene Switching

## Objective
Run E2E tests for navigation mechanisms and stress-test rapid scene shifting in isolation.

## Context
Validation of the FSM (Finite State Machine) transitions and handled of concurrent navigation requests.

## Scope
- `tests/e2e/navigation.spec.ts`
- `tests/e2e/rapid-scene-switching.spec.ts`

## Steps
1. Run the specified E2E tests: `npx playwright test tests/e2e/navigation.spec.ts tests/e2e/rapid-scene-switching.spec.ts`
2. Look for hangs, infinite loops, or locked states during rapid switching.
3. Analyze if the transition locks are working as intended.
4. Prepare a detailed report in `docs/_pending_integration/e2e_navigation_switching_report.md`.
5. The report MUST include:
   - Pass/Fail status.
   - Frequency of race conditions or hangs.
   - Analysis of transition lock effectiveness.
   - Proposed technical fixes.

## Report File
`docs/_pending_integration/e2e_navigation_switching_report.md`
