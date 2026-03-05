# 1779 Sidebar Buttons Remove Spinners

## Objective
Remove spinner indicators from sidebar action buttons (New, Load, Save, Settings, Export/Teaser and related sidebar controls) so spinner visuals appear only inside the progress card.

## Scope
- Identify all sidebar button states that currently render spinner/loader visuals.
- Remove spinner icons/animations from button content while preserving disabled/busy gating behavior.
- Keep spinner/progress indicators only in the progress card UI.
- Ensure previous export/teaser spinner removals remain intact and behavior is consistent across all sidebar actions.

## Acceptance Criteria
- No sidebar action button displays spinner animation during operations.
- Progress card remains the sole location showing spinner/progress status.
- Button labels/icons remain stable and usable while operation lock/disable logic still works.

## Verification
- [ ] `npm run build` passes.
- [ ] Manual check confirms spinner appears only in progress card, never in sidebar buttons.
