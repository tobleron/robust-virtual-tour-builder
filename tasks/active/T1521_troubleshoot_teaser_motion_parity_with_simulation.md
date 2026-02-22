# T1521 - Troubleshoot Teaser Motion Parity vs Simulation Dynamics

## Objective
Fix deterministic frontend teaser motion so output follows simulation dynamics exactly (same path interpolation, timing phases, and transition behavior), instead of simplified style-based crossfade-only behavior.

## Hypothesis (Ordered Expected Solutions)
- [x] Teaser manifest generation is style-driven (`clipDuration/transitionDuration`) and does not encode simulation path math (`NavigationGraph.calculatePathData` + trapezoidal easing), causing motion mismatch.
- [x] Teaser playback state interpolation (`getManifestStateAt`) is segment-linear and omits simulation-specific phases (wait-before-pan, pan via path distance, blink-hold), resulting in simplified transitions.
- [x] Deterministic renderer scene switch logic applies generic crossfade timing without simulation-equivalent pre/post-pan timing windows.
- [x] Backend/headless manifest playback path still follows legacy segment logic and must be aligned to same simulation-driven manifest semantics for parity.

## Activity Log
- [x] Compare live simulation execution path (`SimulationMainLogic`, `NavigationGraph`, `NavigationRenderer`) with deterministic teaser path (`TeaserManifest`, `TeaserPlayback`, `TeaserLogic`).
- [x] Refactor manifest generation to derive from simulation move logic and path data.
- [x] Refactor manifest interpolation/playback to use simulation-equivalent timing phases.
- [x] Split deterministic teaser architecture into style-specific modules plus an isolated offline CFR renderer module.
- [x] Add teaser style selection prompt in sidebar teaser flow and wire selected style into teaser generation.
- [x] Rebuild ReScript and run targeted teaser unit suite after style/renderer refactor.
- [x] Remove teaser inter-shot pause by overriding post-transition pre-pan wait in cinematic style.
- [x] Add teaser-specific modal sizing behavior to prevent style-option overflow.
- [x] Add deterministic teaser HUD overlay rendering (room tag + floor indicators) and adjust logo rendering style.
- [x] Replace hardcoded teaser HUD pixel sizes with HD-reference scaling math (reference stage -> teaser output transform).
- [x] Align teaser floor HUD behavior with export logic (floor sequence + only floors-in-use).
- [x] Add teaser input-lock mode to block user pointer interaction during deterministic capture.
- [x] Mirror simulation UX lock by greying out and disabling sidebar during teaser mode.
- [x] Mirror export UX lock by greying out and disabling sidebar during export mode.
- [x] Add colorful operation-specific progress styling for teaser/export processing UI cards.
- [x] Preserve colorful teaser/export progress card while sidebar lock greys out the rest of sidebar UI.
- [x] Ensure sidebar `Cancel` remains clickable during export lock (overlay constrained to viewer region).
- [x] Make progress `Cancel` control visually red for teaser/export operation cards.
- [ ] Validate with `x445.zip` teaser generation and check for visible parity improvements.
- [x] Run targeted build/tests.

## Code Change Ledger
- [x] `src/core/Types.res`: extended `motionShot` with `pathData`, `waitBeforePanMs`, and `blinkAfterPanMs` for simulation-phase manifest semantics.
- [x] `src/core/JsonParsersDecoders.res`: added decoder support for motion-shot `pathData` and timing fields.
- [x] `src/core/JsonParsersEncoders.res`: added encoder support for motion-shot `pathData` and timing fields.
- [x] `src/systems/TeaserManifest.res`: added `generateSimulationParityManifest` based on `SimulationMainLogic.getNextMove` + `NavigationGraph.calculatePathData`; preserved legacy generator for compatibility.
- [x] `src/systems/TeaserPlayback.res`: replaced manifest interpolation with simulation-phase timeline (`wait -> pan(trapezoidal) -> blink -> crossfade`) and aligned `playManifest` to the same state engine.
- [x] `src/systems/TeaserLogic.res`: switched deterministic teaser generation from style/pathfinder manifest to simulation-parity manifest generation; added `startHeadlessTeaserWithStyle` and style-aware manifest routing via renderer registry.
- [x] `src/systems/TeaserOfflineCfrRenderer.res`: extracted deterministic CFR render loop from `TeaserLogic` into isolated module for renderer-style composability.
- [x] `src/systems/TeaserRendererRegistry.res`: added style-to-render pipeline routing abstraction.
- [x] `src/systems/TeaserStyleCatalog.res`: introduced teaser style catalog (IDs, labels, availability).
- [x] `src/systems/TeaserStyleCinematic.res`: cinematic style manifest builder.
- [x] `src/systems/TeaserStyleFastShots.res`: placeholder module for future fast-shots style.
- [x] `src/systems/TeaserStyleSimpleCrossfade.res`: placeholder module for future simple-crossfade style.
- [x] `src/components/Sidebar/SidebarActions.res`: teaser modal style picker added; style selection piped into teaser execution request.
- [x] `src/components/Sidebar.res`: switched teaser call to `Teaser.startHeadlessTeaserWithStyle` with selected style.
- [x] `src/systems/Teaser.res`: added stable facade wrappers and exported `startHeadlessTeaserWithStyle`.
- [x] `src/systems/TeaserStyleCinematic.res`: removed inter-shot pause by setting `waitBeforePanMs=0` for shots after the first shot.
- [x] `css/components/modals.css`: added `.modal-teaser-style` layout rules to prevent teaser option button overflow.
- [x] `src/bindings/GraphicsBindings.res`: added canvas text bindings used for deterministic teaser HUD drawing.
- [x] `src/systems/TeaserRecorder.res`: reworked watermark rendering to minimal shadow style and added HUD drawing helpers for room label + floor nav.
- [x] `src/systems/TeaserOfflineCfrRenderer.res`: now supplies per-frame overlay state (`roomLabel`, `activeFloor`) and removed fixed scene-switch waits to avoid injected pauses.
- [x] `src/utils/Constants.res`: added `Constants.Teaser.HudReference` constants so teaser HUD sizing maps to HD export reference metrics.
- [x] `src/systems/TeaserRecorder.res`: implemented reference-space HUD scaling (X/Y + uniform) for logo, top room tag, and floor buttons instead of fixed absolute px values.
- [x] `src/systems/TeaserOfflineCfrRenderer.res`: precomputes floors-in-use and passes visible floor IDs into teaser overlay payload.
- [x] `src/systems/TeaserRecorder.res`: floor nav now renders only visible floors, in export-consistent floor ordering.
- [x] `src/components/ViewerManager.res`: passes `isTeasing` into lifecycle effect wiring.
- [x] `src/components/ViewerManager/ViewerManagerLifecycle.res`: toggles global `teaser-mode` class while teaser is active.
- [x] `css/components/viewer.css`: adds `teaser-mode` pointer-event lock styles to prevent viewer interaction during capture.
- [x] `css/layout.css`: applies simulation-equivalent sidebar dim/disable treatment for `body.teaser-mode`.
- [x] `src/App.res`: toggles `body.export-mode` class while AppFSM is in `SystemBlocking(Exporting(_))`.
- [x] `css/layout.css`: applies sidebar dim/disable treatment for `body.export-mode`.
- [x] `src/components/Sidebar/SidebarProcessing.res`: introduces progress theme classification based on operation phase (teaser/export/default).
- [x] `css/components/ui.css`: adds colorful teaser/export specific progress palettes (fill, spinner, phase, percentage styling).
- [x] `src/components/Sidebar/SidebarProcessing.res`: marks processing container with `sidebar-processing-card` class for lock-style exclusion.
- [x] `css/layout.css`: switches from parent grayscale filter to child grayscale filtering and excludes `.sidebar-processing-card` from desaturation.
- [x] `css/layout.css`: lock overlay in `export-mode` now starts at viewer boundary (`left: 340px`) so sidebar cancel remains interactive.
- [x] `src/components/Sidebar/SidebarProcessing.res`: cancel button restyled to red actionable chip with explicit `pointer-events-auto`.
- [x] `tests/unit/TeaserManifest_v.test.res`: updated manifest fixture to include newly required `motionShot` fields.
- [x] `tests/unit/TeaserManager_v.test.res`: updated manager expectations and teaser manifest mocks for simulation-parity generation path.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Deterministic teaser flow now reads a simulation-native motion manifest and evaluates frame states using simulation-equivalent phase timing and camera interpolation math. The renderer has been isolated into `TeaserOfflineCfrRenderer`, and teaser styles are now modularized through a style catalog + registry (`Cinematic` implemented, future styles stubbed). Remaining validation is functional QA with `artifacts/x445.zip` to confirm motion parity visually against simulation in the running app with the new style picker path.
