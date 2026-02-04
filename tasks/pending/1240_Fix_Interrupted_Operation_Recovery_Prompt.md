# Task 1240: Fix Interrupted Operation Recovery Prompt

## Objective
Fix the recovery process for interrupted operations so that the "Unfinished operations" prompt reliably appears on startup.

## Problem Analysis
- **Async Persistence Race**: `OperationJournal.startOperation` calls `saveCurrent()`, but it doesn't await the `IdbBindings.set` promise. If the browser refreshes immediately (simulated crash), the journal entry might not have been written to IndexedDB.
- **Timing**: `Main.res` checks for interrupted operations during `init()`, but if the IndexedDB state is inconsistent or lagging, it might find 0 entries.

## Proposed Solution
- Modify `OperationJournal.res` to allow awaiting `saveCurrent()` when starting an operation.
- In `ProjectManager.res`, ensure the journal entry is successfully persisted before proceeding with the save logic.
- Verify `Main.res` logic successfully waits for `OperationJournal.load()` before checking `interrupted.length`.

## Acceptance Criteria
- [ ] The "Unfinished operations" recovery prompt appears when expected.
- [ ] Interrupted operations can be resumed or cleared correctly.
- [ ] Corresponding test in `robustness.spec.ts` passes.
