# T1618 - Troubleshoot export/teaser progress visibility and ESC cancellation regression

## Objective
Determine why export and teaser progress UI no longer appears reliably, why export ESC cancel stopped working, and identify the introducing code change(s) with a safe fix plan.

## Hypothesis (Ordered Expected Solutions)
- [ ] Highest probability: progress events are still emitted but no longer mapped to the active processing UI state after OperationLifecycle/AppFSM refactors.
- [ ] ESC handler is wired to one operation channel (teaser) but export now uses another cancellation path without keyboard binding.
- [ ] A modal/overlay state condition now suppresses processing card render for export/teaser despite active operation status.
- [ ] Regression came from recent reliability/performance hardening where blocking state was removed or split.

## Activity Log
- [x] Create troubleshooting task before code changes.
- [x] Trace event flow from export/teaser start to progress UI rendering.
- [x] Trace ESC key handler routing for export and teaser.
- [x] Identify introducing commit/range via git blame/log.
- [x] Implement minimal safe fix preserving recent performance/reliability improvements.
- [x] Verify with targeted runtime checks (export + teaser) and operation cancellation behavior.

## Code Change Ledger
- [x] `src/systems/OperationLifecycle.res` - Fixed `reset()` to preserve active subscribers; removed `listeners := []` and added `notifyListeners()` after reset state clear.
  - Why: `AppContext` calls `OperationLifecycle.reset()` on `LoadProject`, which was wiping sidebar `useOperations()` subscriptions, causing no progress card and no ESC cancellation binding after project import.
  - Revert note: Restore `listeners := []` only if reset is moved to a scoped instance lifecycle where subscribers are safely reattached.

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Investigating a major regression where export/teaser progress bars are not visible and export ESC cancel no longer works while teaser ESC still works.
The goal is to identify exact causes and introducing changes before applying minimal safe fixes.
All edits will be logged for surgical rollback if needed.
