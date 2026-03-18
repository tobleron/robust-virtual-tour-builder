# 1879 Dynamic Portrait HFOV Formula Default For Web Package

## Objective
Make the formula-based portrait HFOV the default behavior for generated web packages while keeping the legacy tiered portrait HFOV code in the app as unused rollback-only dead code. The export dialog should stay simple and should not expose a separate formula toggle.

This task is specifically about the exported tour runtime, not the local builder viewer.

## Problem Statement
The current exported tour runtime still contains a tiered portrait HFOV branch in [src/systems/TourTemplates/TourScriptViewport.res](src/systems/TourTemplates/TourScriptViewport.res), but the approved direction is to make the formula branch the normal behavior for generated web packages.

The legacy branch remains useful as rollback-only dead code, but it should not be user-selectable and it should not generate a second export folder.

The goal is to keep the export UX simple while making the formula the default runtime path for web package exports.

## Scope
This task should modify the exported tour template pipeline in the repo, not ad-hoc external export files.

### Primary Implementation Targets
- [src/systems/TourTemplates/TourScriptViewport.res](src/systems/TourTemplates/TourScriptViewport.res)
- [src/systems/TourTemplateHtml.res](src/systems/TourTemplateHtml.res)
- [src/components/Sidebar/SidebarPublishOptionsContent.res](src/components/Sidebar/SidebarPublishOptionsContent.res)
- [src/components/Sidebar/SidebarBase.res](src/components/Sidebar/SidebarBase.res)
- [src/components/Sidebar/SidebarExportLogic.res](src/components/Sidebar/SidebarExportLogic.res)
- backend export packaging modules that write the `web_only/` bundle

### Secondary Validation Targets
- any export-template composition modules needed to ensure the viewport script is emitted correctly
- if necessary, related template helpers that consume `getCurrentHfov()`

## Required Changes

### 1. Make The Formula The Default Web Package Behavior
- Use the formula branch for the normal web package export.
- Remove the separate formula toggle from the export dialog.
- Do not emit a separate comparison folder for the formula.

### 2. Use Real Export Runtime Geometry
The calculation must use the actual exported tour stage dimensions from the runtime DOM:
- `#stage`

The implementation should not assume:
- only one fixed phone size
- only one fixed tablet size
- only one export package resolution

### 3. Keep Recalculation Lazy
Do not recalculate HFOV continuously during normal interaction.

The intended behavior is:
- compute when orientation/layout meaningfully changes
- cache the active portrait HFOV while the layout remains portrait-like
- reset or recompute when the layout returns to landscape or changes materially again

### 4. Prefer Observer/Event-Driven Updates
The runtime should use a viewport/layout change strategy appropriate to exported tours, such as:
- `ResizeObserver`
- orientation/layout change detection
- or a similarly bounded recalculation trigger

Important:
- do not assume `ResizeObserver` means exactly one callback per resize sequence
- the implementation should still avoid redundant recalculations by caching the last effective layout state

### 5. Preserve Existing `getCurrentHfov()` Contract
The rest of the export runtime already depends on:
- `getCurrentHfov()`

That function is consumed by other exported tour behaviors such as navigation and hotspot movement, so the change should preserve the existing public runtime contract while improving the portrait branch internally.

## Mathematical Direction

### Reference Model
The intended formula direction is based on scaling the rectilinear projection through:
- `tan(hfov / 2)`

Reference idea:
- start from the landscape reference HFOV already used by the export runtime
- adjust portrait horizontal coverage according to the stage aspect ratio
- convert back to degrees

### Important Constraint
Do **not** overstate the result as “mathematically guaranteed zero warping.”

Correct framing:
- reduce portrait edge distortion
- keep portrait horizontal coverage more mathematically consistent
- avoid abrupt tier jumps
- keep portrait edge behavior no worse than the intended design baseline

## Runtime Behavior

### Desired State Behavior
- Landscape:
  - use the normal export HFOV baseline
- Portrait:
  - compute the dynamic portrait HFOV once for the current effective layout
  - cache it
- Back to landscape:
  - clear the portrait-specific cached value
- Portrait again after change:
  - recompute using the new layout

### Stability Requirement
The implementation should avoid visible oscillation or jitter while resizing.

That means the code should:
- compare the current effective orientation/layout class before recalculating
- avoid repeated `setHfov` calls when the computed value has not materially changed

## Suggested Implementation Notes

### In [src/systems/TourTemplates/TourScriptViewport.res](src/systems/TourTemplates/TourScriptViewport.res)
- keep the legacy tiered portrait HFOV branch as unused rollback-only code
- make the formula branch the default runtime path
- add cached state for portrait HFOV if needed
- add layout/orientation change handling
- update `applyCurrentHfov()` so it only reapplies when a meaningful change occurred

### In [src/systems/TourTemplateHtml.res](src/systems/TourTemplateHtml.res)
- ensure the generated export script still initializes with `getCurrentHfov()`
- confirm the emitted runtime still sets:
  - initial `hfov`
  - `minHfov`
  - `maxHfov`
  consistently with the formula default

### In the builder export dialog
- keep only the existing web package checkbox
- do not expose any formula-specific checkbox
- leave the export UX unchanged apart from the formula becoming the default runtime behavior

## Acceptance Criteria
- [ ] The baseline web package export uses the formula HFOV behavior by default.
- [ ] The builder export dialog does not expose a separate formula checkbox.
- [ ] Exporting the web package does not add a second formula-specific folder.
- [ ] The web package derives portrait HFOV from a formula using actual stage dimensions.
- [ ] Recalculation happens on meaningful layout/orientation change, not continuously during normal viewing.
- [ ] Portrait HFOV remains stable once calculated for the current layout.
- [ ] Returning to landscape restores normal landscape HFOV behavior.
- [ ] Rotating or resizing back into portrait recomputes the portrait HFOV for the new layout.
- [ ] The change works through the repo’s export pipeline, not by patching generated export files by hand.

## Verification
- `npm run build`
- Export a tour from the actual repo pipeline and verify the generated runtime behavior.
- Manual checks:
  - portrait phone-like viewport
  - portrait tablet-like viewport
  - narrow landscape-to-portrait transition
  - rotate back to landscape
  - repeat transitions multiple times

## Practical Test Cases
- A narrow phone portrait viewport
- A portrait tablet viewport
- A browser resize that moves through the previous tier boundaries
- A wide panorama where edge stretching is easy to notice

## Rollback Plan
- Keep the legacy tiered portrait HFOV function in the app as dead code while the formula is validated.
- If the formula behaves worse than expected, restore the tiered function as the active branch and remove the dead-code-only assumption.

## Notes
- This task supersedes the earlier dummy-export testing approach.
- The implementation must happen in the repo so newly generated exports inherit the behavior automatically.
- This is an exported-tour runtime refinement, not a builder viewer change.
