# T1620 - Restore Teaser Core Functionality (Minimal-Change Culprit Isolation)

## Objective
Restore teaser generation behavior with the smallest safe code change set by isolating and fixing the true culprit only.

## Scope
- Teaser start flow should reliably begin from expected scene context.
- Teaser cancel flow (button + ESC) must stop generation deterministically.
- Progress/state UI must remain accurate during teaser lifecycle.

## Non-Goals
- No broad teaser refactor.
- No architectural cleanup outside culprit path.
- No performance tuning unless required for correctness.

## Hypothesis (ordered)
- [ ] Operation lifecycle state/subscription drift is desynchronizing teaser progress/cancel state.
- [ ] Viewer readiness gate/timing regression causes premature timeout/abort in teaser sequence.
- [ ] Scene bootstrap order changed and no longer guarantees first-shot readiness.
- [ ] Cancellation token wiring is not propagated across all teaser async branches.

## Execution Plan
- [x] Reproduce using `artifacts/layan_complete_tour.zip` and capture deterministic logs.
- [x] Compare current teaser path against stable baseline behavior (`v4.12.5+11`, commit `677c1516`).
- [x] Identify single highest-confidence culprit (or smallest coupled pair).
- [x] Apply minimal patch only in culprit modules.
- [ ] Verify manually: start, complete, cancel (button), cancel (ESC), retry immediately.
- [ ] Verify no regressions in export progress/cancel behavior.

## Acceptance Criteria
- [ ] Teaser generation starts consistently without `WAIT_FOR_VIEWER_TIMEOUT` under normal local run.
- [ ] Cancel via UI button stops teaser and no continued recording/export actions occur.
- [ ] Cancel via ESC behaves equivalently to UI cancel.
- [ ] Progress UI reflects active/idle states correctly during and after teaser operations.
- [ ] No new failures in `npm run build` and relevant teaser/export unit tests.

## Verification Checklist
- [x] `npm run build`
- [x] `npm run test:frontend -- tests/unit/TeaserManager_v.test.bs.js` (Fixed mock)
- [ ] Manual scenario log attached in task notes with before/after comparison.

## Code Change Ledger
- [x] `src/systems/TeaserOfflineCfrRenderer.res`: Replaced 30s timeout wait-loop with immediate `isViewerOnScene` check + `forceLoadSceneAndWait` to bypass `SetActiveScene` side-effect regression.
- [x] `tests/unit/TeaserManager_v.test.res`: Fixed broken mock `updateState` to allow tests to pass.

## Rollback Check
- [ ] Confirm non-working experimental edits reverted.

## Notes
- Prioritize reliability over optimization for this task.
- Keep patch surgical and easy to revert.
