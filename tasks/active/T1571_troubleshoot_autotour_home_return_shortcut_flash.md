# T1571 Troubleshoot Auto-Tour Home-Return Shortcut Flash

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [ ] A race exists between the auto-tour countdown interval and timeout callbacks; one final interval tick re-renders default shortcuts before home navigation begins.
  - [ ] The room-label suppression flag handles only label rendering, not shortcut panel visibility, so panel flash still appears under timing contention.
  - [ ] A newer map shortcut timing path changed event-loop timing enough to expose the pre-existing race more frequently.

- [ ] **Activity Log**
  - [x] Reviewed `TourScriptUI.res` auto-tour completion/countdown flow and `TourScripts.res` load handler.
  - [x] Added one-shot shortcut-panel suppression during countdown timeout -> home navigation transition.
  - [x] Reset suppression on next viewer load.
  - [x] Verified build (`npx rsbuild build`) and sanity-checked affected paths.
  - [x] Identified 5s countdown boundary race (interval sets countdown to 0 and redraws default shortcuts before timeout transition).
  - [x] Adjusted interval boundary behavior to keep countdown at `1` until timeout initiates home transition.

- [ ] **Code Change Ledger**
  - [x] `src/systems/TourTemplates/TourScriptUI.res`: added `suppressShortcutPanelUntilNextLoad` and guarded `updateNavShortcutsV2` to keep panel hidden during final countdown->home transition frame.
  - [x] `src/systems/TourTemplates/TourScriptUI.res`: changed countdown interval terminal tick to keep `autoTourHomeReturnCountdownRemaining = 1` (not `0`) so default shortcuts are never rendered before timeout return-home transition.
  - [x] `src/systems/TourTemplates/TourScripts.res`: clear `suppressShortcutPanelUntilNextLoad` on next scene `load` event.
  - [x] Revert note: all edits are isolated to export tour template scripts and can be reverted surgically by removing the new suppression flag/guard if needed.

- [ ] **Rollback Check**
  - [x] Confirmed CLEAN (working changes only; no non-working edits retained).

- [ ] **Context Handoff**
  - [ ] Auto-tour end currently uses both interval and timeout timers.
  - [ ] The fix should suppress shortcut panel rendering only during the transition frame from countdown end to home scene load.
  - [ ] Reset must occur on next load to avoid persistent hidden shortcuts.
