# 1319: E2E Test - Ingestion & Import

## Objective
Run E2E tests related to asset ingestion and desktop import in complete isolation, identify issues, and propose solutions.

## Context
Validation of the initial entry points of the application (uploading and importing scenes).

## Scope
- `tests/e2e/ingestion.spec.ts`
- `tests/e2e/desktop-import.spec.ts`

## Steps
1. Ensure the development environment is running (`npm run dev` and backend).
2. Run the specified E2E tests: `npx playwright test tests/e2e/ingestion.spec.ts tests/e2e/desktop-import.spec.ts`
3. Analyze any failures or flakiness.
4. Prepare a detailed report in `docs/_tmp_test_reports/report_ingestion_import.md`.
5. The report MUST include:
   - Pass/Fail status for each test file.
   - Trace logs or screenshots for failures (if available).
   - Root cause analysis for each failure.
   - Proposed technical fixes.

## Report File
`docs/_tmp_test_reports/report_ingestion_import.md`
