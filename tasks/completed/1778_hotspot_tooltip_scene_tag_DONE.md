# 1778 Hotspot Tooltip Scene Tag

## Objective
Surface the destination scene tag linked by every navigation hotspot without the leading `#`, but only during idle, manual navigation. In the builder-stage viewer the label should always be visible (in a subtle HUD style) and in exported tours it should appear as a hover tooltip once the cursor lingers long enough; both exposures must be gated by the same safety checks so they never show during uploads, exports, teaser/headless renders, or any auto-tour/animation playback.

## Scope
- Builder viewer: render a small, always-visible label in the top-left of each hotspot (white text, thin stroke shadow, no dissolve) with padding between the hotspot and the text, showing the linked scene tag without `#`.
- Exported tours: show the same tag text as a tooltip only after 1.2 seconds of mouse hover, and hide it immediately when the cursor leaves.
- Use the hotspot target scene tag (stripping any leading `#`) as the canonical label for both contexts.
- Guards: require the global operation tracker to report no uploads/exports/teaser generation in flight, and suppress the label when any auto-tour or animation playback mode is active.
- Apply the guard logic identically across builder-stage interactions and exported tour navigation so nothing leaks into blocking operations or automated playback.

## Acceptance Criteria
- Builder viewer shows a persistent white label with thin stroke shadow in the hotspot's top-left area, padded from the hotspot, displaying the destination scene tag without `#` whenever no blocking operation/auto playback is happening.
- Exported tours show the tooltip after 1.2 seconds of hover (manual navigation only) using the same label logic, and it disappears if the cursor leaves or guard conditions fail.
- Both contexts enforce the blocking-operation and auto-tour/animation suppression so nothing appears during exports, recordings, or automated tours.
- Tooltip/label implementation works without additional configuration for exported tours; it piggybacks on existing navigation UI layers.

## Verification
- [ ] `npm run build` completes without errors.
- [ ] Builder viewer label and exported tooltip verified manually (normal navigation) while remaining suppressed during uploads/exports/teaser/auto tours.
- [ ] Any new telemetry/state hooks introduced are logged via the Logger module per standards.
