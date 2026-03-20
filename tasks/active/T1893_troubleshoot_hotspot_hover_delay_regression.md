# T1893 Troubleshoot Hotspot Hover Delay Regression

## Objective
Restore the delayed closing behavior for hotspot hover action buttons so the secondary controls do not disappear immediately when the pointer leaves the hotspot.

## Hypothesis
- [ ] The latest CSS refactor shortened or removed the exit-delay transition on the hotspot hover controls.
- [ ] A component class change in the hotspot editor or export styles is overriding the previous hover timing.
- [ ] The behavior depends on a shared Tailwind/CSS class and should be restored centrally rather than per-component.

## Activity Log
- [x] Inspect the hotspot hover button markup and CSS classes.
- [x] Compare the latest CSS refactors against the previous hover timing behavior.
- [x] Restore the delay without changing the existing hotspot actions or visuals.
- [x] Rebuild and verify the hover timing.
- [x] Increase the hotspot hover exit delay so secondary controls linger longer before closing.
- [x] Remove the extra shadow treatment from the hotspot secondary controls and `#` button.
- [x] Increase the hotspot hover exit delay again to 1400ms per user feedback.
- [x] Replace the CSS-only hover delay with a shared hotspot hover-open state so the drawer lingers universally and switches immediately to another hotspot.
- [x] Revert the shared hover-open state after it caused the drawer to collapse/behave incorrectly for normal hotspots.
- [x] Restore deterministic hover timing by moving the hotspot secondary-button delay back into shared CSS instead of Tailwind arbitrary delay utilities.
- [x] Keep hotspot secondary buttons clickable during the delayed exit window by removing immediate pointer-event shutdown on hover leave.
- [x] Replace CSS-only hover persistence with a React-controlled hotspot drawer state that lingers on leave and switches immediately to the next hovered hotspot.
- [x] Tighten hotspot drawer button spacing now that the persisted-open state makes the full transform offsets visible.
- [x] Align the persisted-open drawer positioning with Tailwind's `translate` property so buttons do not overshoot while both hover and open-state styles are active.
- [x] Restore the opening animation by letting `group-hover` drive the initial reveal and using the React open-state only for post-leave persistence.
- [x] Loosen the drawer spacing slightly from the temporary too-tight layout.
- [x] Restore smooth drawer sliding by adding `translate` to the shared hotspot control transition list.
- [x] Add a slight post-checkpoint gap between hotspot drawer buttons so adjacent controls do not visually touch.
- [x] Remove diffuse hotspot shadows and keep the hotspot typography on the hard-stroke shadow style only.
- [x] Restore hotspot visibility on bright backgrounds with a crisp hard-edge stroke after the diffuse halo removal proved too aggressive.
- [x] Replace the hotspot button shadow separation with an explicit border stroke so visibility no longer depends on any shadow treatment.
- [x] Harden hotspot rendering for older imported projects by falling back to the viewer's live scene id when custom scene metadata is missing.
- [x] Restore the hotspot visual from full border stroke to the intended angled hard-shadow treatment.

## Code Change Ledger
- [x] `css/components/viewer-ui-controls.css` - restored shared hover enter/exit delay rules for hotspot secondary controls.
- [x] `src/components/PreviewArrow.res` - removed redundant Tailwind delay utilities so the shared CSS rule is the single timing source.
- [x] `src/utils/Constants.res` - increased the hotspot hover exit delay to slow down button dismissal.
- [x] `src/utils/Constants.res` - increased the hotspot hover exit delay to 1400ms.
- [x] `css/components/viewer-ui-controls.css` - removed the default shadow from hotspot secondary controls.
- [x] `src/components/PreviewArrow.res` - removed the extra `shadow-lg` classes from the retarget and delete buttons.
- [x] `src/components/ReactHotspotLayer.res` - added the shared hover-open state and delayed clear timer for hotspot drawers.
- [x] `css/components/viewer-ui-controls.css` - replaced the hover-delay rules with drawer-open visibility overrides.
- [x] `src/components/PreviewArrow.res` - reverted the hover-open drawer enter hooks and restored the original delayed hover classes.
- [x] `src/components/ReactHotspotLayer.res` - removed the shared hotspot hover-open state and delayed clear timer.
- [x] `css/components/viewer-ui-controls.css` - removed the drawer-open visibility overrides.
- [x] `css/components/viewer-ui-controls.css` - added shared enter/exit transition-delay rules and pointer-event gating for hotspot secondary controls.
- [x] `src/components/PreviewArrow.res` - removed the Tailwind arbitrary delay utilities so the shared CSS timing is the single hover-delay path.
- [x] `css/components/viewer-ui-controls.css` - removed pointer-event gating so visible secondary controls remain selectable during the exit-delay linger.
- [x] `src/components/ReactHotspotLayer.res` - added a shared active drawer link id and delayed close timer so hotspot drawers stay open after leave and cancel close when re-entered.
- [x] `src/components/PreviewArrow.res` - added explicit drawer-open and drawer-enter hooks so drawer buttons can keep the active hotspot open while the pointer moves between controls.
- [x] `css/components/viewer-ui-controls.css` - restored explicit open-state transforms for hotspot drawers and moved linger behavior out of CSS delays.
- [x] `src/components/PreviewArrow.res` - reduced the drawer hover transform offsets so the buttons sit closer to the center control.
- [x] `css/components/viewer-ui-controls.css` - matched the persisted-open drawer transforms to the tighter button spacing.
- [x] `css/components/viewer-ui-controls.css` - changed persisted-open drawer positioning from `transform` to `translate` so it matches the Tailwind hover utilities and avoids double application during hover.
- [x] `src/components/ReactHotspotLayer.res` - changed drawer activation so hover animation comes from CSS hover, while the React drawer-open state is only used to persist the drawer after leave.
- [x] `src/components/PreviewArrow.res` - removed root-level forced drawer activation on enter and adjusted hover offsets to a slightly looser spacing.
- [x] `css/components/viewer-ui-controls.css` - matched persisted-open drawer spacing to the new looser offsets.
- [x] `css/components/viewer-ui-controls.css` - added `translate` to the hotspot control transition definition so drawer position changes animate smoothly again.
- [x] `src/components/PreviewArrow.res` - increased the drawer hover offsets slightly to create a visible gap between neighboring controls.
- [x] `css/components/viewer-ui-controls.css` - matched the persisted-open drawer offsets to the slightly larger button spacing.
- [x] `css/components/viewer-ui-controls.css` - removed the hotspot control box shadow and converted hotspot text shadows from soft blur to hard-stroke only.
- [x] `css/components/viewer-ui-controls.css` - restored a small hard-edge hotspot button shadow so controls stay visible without returning to the diffuse blur.
- [x] `css/components/viewer-ui-controls.css` - replaced the hotspot button shadow with a crisp dark border and removed shadow dependency from hotspot visibility.
- [x] `src/components/ReactHotspotLayer.res` - added a viewer scene-id fallback from adapter metadata to the live viewer scene so the React hotspot overlay still renders on older project loads.
- [x] `src/components/ViewerManager/ViewerManagerHotspots.res` - changed hotspot sync to compare against a resolved viewer scene id instead of metadata only.
- [x] `src/components/ViewerManager/ViewerManagerSceneLoad.res` - changed active scene reconciliation to use the resolved viewer scene id fallback too.
- [x] `css/components/viewer-ui-controls.css` - removed the full border stroke and restored the angled hard-shadow hotspot treatment.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The sequence-picker work is separate and already verified. This task is specifically about hotspot hover timing regression after CSS refactoring, likely around the main hotspot hover controls in the builder UI. Start from the current hotspot hover classes and any shared CSS rules that target `.group-hover`, `--open-delay`, or `--exit-delay`.
