# T1798 Troubleshoot teaser ESC dim persistence

- Assignee: Codex
- Objective: Identify and fix why pressing ESC during teaser generation leaves the window viewer permanently dimmed.
- Scope: Teaser cancel teardown, body mode classes, snapshot/overlay cleanup, viewer lifecycle reset.

## Hypothesis (Ordered Expected Solutions)
- [ ] ESC cancel path does not fully clear `teaser-mode` body class, leaving teaser dim CSS active.
- [ ] ESC cancel path does not hide/remove `#viewer-snapshot-overlay` after abort, leaving an opaque overlay on stage.
- [ ] Operation cancellation marks lifecycle stopped but misses UI reducer transition that unsets `isTeasing`.
- [ ] A race between navigation cancellation and teaser recorder teardown re-applies dim state after cancel.

## Activity Log
- [x] Create troubleshooting task and gather teaser/cancel code paths.
- [x] Trace ESC handler dispatch chain and operation cancellation callbacks.
- [x] Inspect lifecycle class toggles and overlay visibility rules.
- [x] Implement minimal fix and verify with build/tests.
- [ ] Record rollback status and handoff summary.

## Code Change Ledger
- [x] `src/systems/TeaserRecorder.res`: Added `Overlay.clear()` and guaranteed fade-overlay reset in `stopRecording()` for cancel/success teardown.
- [x] `src/systems/InputSystem.res`: ESC teaser cancel path now force-clears teaser fade, stops recorder, and removes `snapshot-visible` overlay class immediately.

## Rollback Check
- [x] Confirmed CLEAN. Fix validated via `npm run res:build` and targeted unit tests.

## Context Handoff
The bug reproduces when ESC is pressed during teaser generation and the stage remains dimmed after cancellation. Initial suspect areas are `teaser-mode` class lifecycle and snapshot overlay cleanup in viewer lifecycle and input cancellation paths. Next step is to verify the exact cancellation flow and patch only the missing teardown step to avoid regressions.
