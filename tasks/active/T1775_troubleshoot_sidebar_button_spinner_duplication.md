# T1775 Troubleshoot Sidebar Button Spinner Duplication

## Objective
Remove the extra spinner animation from the `Export` and `Teaser` sidebar buttons while preserving the progress bar spinner behavior during active operations.

## Hypothesis (Ordered Expected Solutions)
- [ ] `SidebarActions` applies `btn-loading` class to Export/Teaser; removing this class from those two buttons will remove the duplicate spinner without affecting progress bar spinner.
- [ ] If spinner persists, a secondary CSS selector targets pending state by attribute/class and needs narrowing.
- [ ] If operation UX regresses, add a dedicated non-spinner pending class for Export/Teaser buttons while keeping disable/text states.

## Activity Log
- [x] Located pending-state class assignment in `src/components/Sidebar/SidebarActions.res`.
- [x] Located spinner pseudo-element definition in `css/components/buttons.css` (`.btn-loading::after`).
- [x] Apply surgical patch to Export/Teaser button class strings only.
- [x] Verify build/tests.
- [ ] Manual UX verification notes.

## Code Change Ledger
- [x] `src/components/Sidebar/SidebarActions.res`: removed conditional `btn-loading` class from Export and Teaser buttons only; preserved pending disable and label text behavior.

## Rollback Check
- [x] Confirmed CLEAN (no non-working changes retained; no rollback required).

## Context Handoff
The duplicate spinner is implemented through `.btn-loading::after` in `buttons.css`. `Export` and `Teaser` buttons in `SidebarActions.res` currently attach `btn-loading` when pending, which creates the extra spinner on top of the progress UI spinner. Planned fix is to stop applying `btn-loading` on those two buttons only, preserving pending disable/text behavior and keeping progress-bar spinner unchanged.
