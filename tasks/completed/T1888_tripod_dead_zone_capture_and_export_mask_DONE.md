# T1888 Tripod Dead Zone Capture and Export Mask

## Hypothesis
- [ ] The builder needs a temporary live pose HUD overlay so the current pitch/yaw/hfov can be observed while aiming the camera downward to identify the tripod-safe dead zone.
- [ ] The export pipeline can reuse the same dead-zone configuration once the live capture values are known, preventing the tripod stand from being visible in exported tours.
- [ ] The viewer/export camera floor-limit should be implemented as a shared dead-zone rule rather than a builder-only visual trick.

## Activity Log
- [ ] Inspect the live viewer HUD and bindings for a low-risk way to surface current camera pose.
- [ ] Add a temporary overlay to the builder viewer that displays live pitch/yaw/hfov and any dead-zone guidance needed for coordinate capture.
- [ ] Wire the eventual dead-zone limit into the export template path so exported tours cannot look below the safe floor.
- [ ] Verify the builder still compiles and the export template path still builds after the HUD/dead-zone changes.

## Code Change Ledger
- [ ] `src/components/ViewerHUD.res`: add temporary live pose HUD support and a cleanup path for later removal.
- [ ] `src/bindings/ViewerBindings.res`: reuse existing viewer pose bindings if any new accessor is required for the overlay.
- [ ] `src/systems/TourTemplateHtmlSupportRender.res`: add export-side dead-zone markup or shared configuration plumbing.
- [ ] `src/systems/TourTemplates/TourStyles.res`: add export CSS for the dead-zone mask/overlay if needed.
- [ ] `src/systems/TourTemplates/TourScriptViewport.res`: add any export runtime logic needed to enforce the safe floor.

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED any temporary-only builder HUD additions before finalizing the dead-zone feature.

## Context Handoff
- The builder already exposes viewer pitch, yaw, and hfov through existing bindings, so a live pose HUD can be added without invasive viewer changes.
- The export tour is assembled through the template/render/style helpers, so the same dead-zone configuration can be pushed into exported tours once the capture values are known.
- This task should keep portal deployment behavior untouched; the requested change is for the builder viewer and exported tours only.
