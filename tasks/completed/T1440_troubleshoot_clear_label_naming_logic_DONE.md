# 🛠️ Troubleshooting: Clear Label Naming Logic (T1440)

## Hypothesis (Ordered Expected Solutions)
- [x] **Hypothesis 1**: `SceneNaming.res` has a guard that prevents renaming when the label is empty. (Confirmed).
- [x] **Hypothesis 2**: `TourLogic.res`'s `computeSceneFilename` doesn't include the "(Untagged)" postfix by default. (Confirmed).

## Activity Log
- [x] Updated `TourLogic.res` to include `_Untagged` in filenames for empty labels.
- [x] Updated `SceneNaming.res` to allow renaming scenes with empty labels.
- [x] Updated `LabelMenu.res` to pass `_baseName` when clearing or applying labels to ensure naming consistency.

## Code Change Ledger
| File Path | Change Summary | Revert Note |
|-----------|----------------|-------------|
| src/utils/TourLogic.res | Added `_Untagged` to `computeSceneFilename`. | N/A |
| src/core/SceneNaming.res | Removed `if label != ""` guard in `syncInventoryNames`. | N/A |
| src/components/LabelMenu.res | Passed `_baseName` in `UpdateSceneMetadata`. | N/A |

## Rollback Check
- [ ] (Confirmed CLEAN or REVERTED non-working changes).

## Context Handoff
Logical bug fixed: clearing a label now correctly updates the scene name to include an "(Untagged)" postfix, ensuring the UI reflects the change immediately and hotspots are updated.
