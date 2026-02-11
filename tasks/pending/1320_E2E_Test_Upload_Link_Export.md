# 1320: E2E Test - Upload, Linking & Export

## Objective
Run the full workflow E2E test (Upload -> Link -> Export) in isolation, identify bottlenecks or failures, and propose solutions.

## Context
This test covers the critical end-to-end path of creating a tour and exporting it.

## Scope
- `tests/e2e/upload-link-export-workflow.spec.ts`

## Steps
1. Run the specified E2E test: `npx playwright test tests/e2e/upload-link-export-workflow.spec.ts`
2. Monitor for timeouts or race conditions during the multi-step process.
3. Analyze any failures in the export generation or download phase.
4. Prepare a detailed report in `docs/_tmp_test_reports/report_upload_link_export.md`.
5. The report MUST include:
   - Pass/Fail status.
   - Breakdown of which stage failed (Upload, Linking, or Export).
   - Root cause analysis.
   - Proposed technical fixes.

## Report File
`docs/_tmp_test_reports/report_upload_link_export.md`
