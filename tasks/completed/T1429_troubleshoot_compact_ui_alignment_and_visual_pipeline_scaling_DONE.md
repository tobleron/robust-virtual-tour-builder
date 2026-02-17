# T1429 - Troubleshoot Compact UI Alignment and Visual Pipeline Scaling

## Objective
Fix compact-mode HUD alignment and size consistency:
- Keep the 3 top-left utility buttons vertically aligned with floor buttons in compact states.
- Add compact sizing for the visual pipeline when viewer is reduced to tablet/portrait modes.

## Hypothesis (Ordered Expected Solutions)
- [x] P1: Utility bar compact-mode `left` offset diverges from floor-nav offset, causing visual misalignment; unify offsets.
- [x] P2: Visual pipeline has no state-aware compact sizing; apply reduced scale/margins under tablet/portrait body classes.
- [x] P3: Verify compact sizing does not break interaction hit targets or layout overlap.

## Activity Log
- [x] Created troubleshooting task T1429.
- [x] Patch compact utility-bar alignment.
- [x] Patch compact visual-pipeline sizing rules.
- [x] Verify build.

## Code Change Ledger
| File Path | Change Summary | Revert Note |
|-----------|----------------|-------------|
| `css/components/viewer-ui.css` | Aligned compact utility-bar left offset to floor-nav axis (`20px`) in both state-based and media fallback rules. | `git checkout -- css/components/viewer-ui.css` |
| `src/components/VisualPipelineLogic.res` | Added compact visual-pipeline scaling/margins for tablet and portrait states to reduce footprint consistently. | `git checkout -- src/components/VisualPipelineLogic.res` |

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
- [x] Compact-mode top-left utility buttons now align on the same x-axis as compact floor buttons.
- [x] Visual pipeline now reduces size proportionally in tablet/portrait states while staying usable.
- [x] Re-verified with `npm run build`.
