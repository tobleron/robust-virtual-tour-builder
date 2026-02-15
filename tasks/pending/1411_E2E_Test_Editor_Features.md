# 1411: E2E Test - Editor & Feature Deep Dive

## Objective
Run E2E tests for the core Editor functionality and advanced feature deep dives in isolation.

## Context
Validation of the UI components, manual scene manipulations, and specific feature behaviors in the editor.

## Scope
- `tests/e2e/editor.spec.ts`
- `tests/e2e/feature-deep-dive.spec.ts`

## Steps
1. Run the specified E2E tests: `npx playwright test tests/e2e/editor.spec.ts tests/e2e/feature-deep-dive.spec.ts`
2. Analyze UI interaction issues or state synchronization bugs.
3. Prepare a detailed report in `docs/_pending_integration/e2e_editor_features_report.md`.
4. The report MUST include:
   - Pass/Fail status.
   - Specific UI elements that failed to interact or render correctly.
   - State management discrepancies identified during tests.
   - Proposed technical fixes.

## Report File
`docs/_pending_integration/e2e_editor_features_report.md`
