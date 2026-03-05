# 1616 Run Full E2E With Verification

## Objective
Execute the full Playwright E2E suite (all configured browsers) in a clean environment, confirm that the newly strengthened visual pipeline behavior and surrounding navigation logic remain stable, and capture reproducible artifacts for every failure or success milestone.

## Scope
- Start from a fresh build (`npm run build`) so the exported dev server matches the latest changes.
- Run `npx playwright test` with the global suite configuration (all browsers) and collect trace/video/screenshot artifacts.
- Pay attention to timeline-management spec (#200) since it is currently failing with locator timeouts; document exact failure details and add follow-up tasks if systemic flakiness persists.
- Record the test-result paths (`test-results/...`) plus any console warnings/errors that surfaced during the run.

## Acceptance Criteria
- Full `npx playwright test` run completes (pass or fails with documented artifacts).
- Any newly introduced failures are reproduced once after re-running the relevant spec to confirm they are deterministic.
- Provide a short summary of the failures/passes, test duration, and the artifacts’ paths inside `test-results/`.
- Mark the task as completed only after the above verification is captured.

## Verification
- [ ] Build executed (`npm run build`) and clean.
- [ ] Full Playwright suite run (all projects) with artifacts saved.
- [ ] Failures reproduced once and documented (`test-results/.../error-context.md`, screenshot).
- [ ] Summary added at the end of this document before moving to `completed/`.
