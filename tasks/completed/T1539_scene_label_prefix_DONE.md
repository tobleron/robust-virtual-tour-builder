# T1539 Scene List Label Prefix

## Assignee
- Codex

## Objective
- Reintroduce the prefix numbering for scenes that have a custom label, ensuring the sidebar still displays the monotonic ID before every label even when the user tags a scene.

## Boundary
- Frontend components directly rendering scene metadata (primarily `SceneList/SceneItem.res`) and the touring naming helpers (`TourLogic`).

## Owned Interfaces
- `TourLogic`, `SceneList/SceneItem.res`, and any selectors that format scene titles.

## No-Touch Zones
- Backend modules and unrelated UI elements.

## Hypothesis (Ordered Expected Solutions)
- [x] Expose a helper that renders the numbered prefix together with a label when one exists.
- [x] Make the sidebar scene item use this helper so every row shows the sequence-number prefix.

## Activity Log
- [x] Confirmed current `SceneList` renders raw `scene.label` without prefix, causing the numbering to disappear once the label is set.
- [x] Added `TourLogic.formatDisplayLabel` and wired `SceneItem` to use it.
- [x] Ran `npm run build` to ensure the change compiles cleanly.

## Code Change Ledger
- [x] Added `TourLogic.formatDisplayLabel(scene)` which prefixes labeled scenes with their `sequenceId` while leaving unlabeled scenes relying on the sanitized filename.
- [x] Updated `SceneList/SceneItem.res` to render the new formatted label instead of the raw label or name.

## Rollback Check
- [x] Build succeeded after applying the change.

## Context Handoff
- (No additional handoff needed since the build is green and logic proven.)
