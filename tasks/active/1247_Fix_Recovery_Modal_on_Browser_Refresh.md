# Task 1247: Fix Recovery Modal on Browser Refresh

## Objective
Ensure the recovery modal is correctly displayed after a browser refresh if a persistent operation (like saving) was interrupted.

## Context
E2E test `tests/e2e/error-recovery.spec.ts` failure: `Browser refresh during save should trigger recovery modal`.

## Technical Details
- Test: `Browser refresh during save should trigger recovery modal`
- Failure: The recovery prompt doesn't appear after the page reloads.
- Relevant Modules: `src/utils/RecoveryManager.res`, `src/components/RecoveryPrompt.res`, `src/utils/OperationJournal.res`.

## Acceptance Criteria
- [ ] The recovery modal is shown on startup if an interrupted operation is detected in the journal.
- [ ] Corresponding test in `error-recovery.spec.ts` passes.
