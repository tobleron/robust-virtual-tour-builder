# 1323: E2E Test - Simulation & Teaser Recording

## Objective
Run E2E tests for the Autopilot simulation and Teaser video recording in isolation.

## Context
These features involve automated navigation and asset generation (teasers) which often have timing-sensitive behaviors.

## Scope
- `tests/e2e/simulation-teaser.spec.ts`

## Steps
1. Run the specified E2E test: `npx playwright test tests/e2e/simulation-teaser.spec.ts`
2. Verify that simulation starts/stops correctly.
3. Verify that teaser recording produces the expected output/download event.
4. Prepare a detailed report in `docs/_tmp_test_reports/report_simulation_teaser.md`.
5. The report MUST include:
   - Pass/Fail status.
   - Issues with autopilot pathing or timing.
   - Failures in the recording or download process.
   - Proposed technical fixes.

## Report File
`docs/_tmp_test_reports/report_simulation_teaser.md`
