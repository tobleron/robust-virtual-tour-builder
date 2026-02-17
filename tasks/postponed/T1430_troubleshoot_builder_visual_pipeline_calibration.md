# T1430 - Troubleshoot Builder Visual Pipeline Calibration

## Objective
Calibrate the builder visual pipeline behavior and sizing in compact modes, with specific focus on portrait usability and interaction clarity.

## Hypothesis (Ordered Expected Solutions)
- [ ] P1: Portrait scale factor for `.visual-pipeline-wrapper` is too aggressive and makes interaction feel cramped.
- [ ] P2: Bottom spacing and safe-area padding need per-state tuning to prevent overlap with HUD/floor controls.
- [ ] P3: Node/drop-zone geometry should be reduced proportionally (not just wrapper scale) for cleaner touch behavior.

## Activity Log
- [ ] Move task to `tasks/active/` when resuming calibration.
- [ ] Capture target viewport dimensions and overlap conditions.
- [ ] Tune visual-pipeline compact styles and verify interaction.
- [ ] Verify with `npm run build`.

## Code Change Ledger
| File Path | Change Summary | Revert Note |
|-----------|----------------|-------------|
| `src/components/VisualPipelineLogic.res` | (pending) Calibrate compact portrait/tablet sizing, spacing, and node/drop-zone geometry. | `git checkout -- src/components/VisualPipelineLogic.res` |

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
- [ ] Current compact calibration improved tablet mode but portrait remains suboptimal per user feedback.
- [ ] Resume by tuning builder-only visual-pipeline compact rules without altering export behavior.
- [ ] Keep floor/utility alignment fixes intact while calibrating pipeline.
