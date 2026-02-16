# T1418 - Troubleshoot Export Active Floor Styling and Room Label Visibility

## Objective
Make exported tours match builder parity for floor and scene labeling UX by ensuring the active floor uses identical visual treatment and the room label appears at the top of the viewer when the room has a label.

## Hypotheses (Expected Solutions Ordered by Probability)
- [x] **H1 (Highest)**: Export template uses stale floor-navigation CSS tokens/classes, so active floor state is applied functionally but rendered with non-parity styling.
- [x] **H2**: Export runtime does not render/update the top room label from scene metadata consistently (missing DOM node, stale binding, or hidden CSS state).
- [x] **H3**: Scene-change lifecycle in export runtime updates hotspots and panorama but misses synchronized UI refresh hooks for floor active state and room label text.

## Activity Log (Experiments / Edits)
- [x] Inspect export template CSS/DOM/runtime in `src/systems/TourTemplates.res` for floor navigation and room label behavior.
- [x] Port/align active floor CSS/UI rules from builder-facing UI spec into export template.
- [x] Ensure floor active class assignment/update logic runs on initial scene load and every scene transition.
- [x] Add/restore room label node in exported viewer chrome and wire text updates from current scene label.
- [x] Validate behavior by building project and sanity-checking generated export runtime.

## Code Change Ledger (for Surgical Revert)
- [x] `src/systems/TourTemplates.res` - Added export floor-nav overlay CSS/DOM/runtime sync and persistent room-label CSS/DOM/runtime sync on scene load. Revert path: remove `#viewer-floor-nav-export` / `.viewer-persistent-label-export` CSS+DOM+runtime helpers and restore prior export template.
- [ ] `tests/unit/TourTemplates_v.test.res` - (planned if needed) Add/update assertions around exported CSS/runtime for active floor and room label contract. Revert path: drop new export contract assertions.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes before completion move.

## Context Handoff
- [x] Summarize exact export CSS/runtime deltas and resulting behavior parity with builder.
- [x] Record any remaining non-parity edge cases with reproducible steps.
- [x] Note whether tests/build passed and what to run next if follow-up is required.
