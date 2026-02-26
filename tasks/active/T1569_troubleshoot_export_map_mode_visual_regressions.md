# T1569 Troubleshoot Export Map Mode Visual Regressions

- [ ] Hypothesis (Ordered Expected Solutions)
  - [x] Remove global map-mode dim overlay to eliminate blue full-screen tint.
  - [x] Preserve original glass-panel look in map mode while repositioning center and scaling proportionally.
  - [x] Disable looking mode on map open and maintain map usability with `e` exit shortcut.
  - [x] Keep `e exit map mode` as the final shortcut row in map mode for predictable scanning.
  - [x] Support map keyboard shortcuts for each floor tag while map mode is open (not only `e`).
  - [x] Match map shortcut colors to main glass panel by keeping all map shortcut keys/text white.
  - [x] When navigation starts from map mode, force Looking Mode ON for non-portrait, non-touch contexts.
  - [x] Detect touch-first devices in export runtime and default Looking Mode OFF (no mouse drift assumption).

- [ ] Activity Log
  - [x] Patch map-mode CSS to remove overlay and restore base panel visual style.
  - [x] Patch map open runtime behavior to disable looking mode.
  - [x] Verify build.
  - [x] Reorder map mode rows so `e exit map mode` renders at the bottom (including empty-state fallback).
  - [x] Re-verify build after shortcut-order refinement.
  - [x] Add map-mode keyboard routing so floor shortcut keys (`r`, `5..1`, `g`, `b`, `z`) navigate directly to mapped scenes.
  - [x] Update map shortcut styling so keys and `e exit map mode` text use white like the main panel.
  - [x] Verification note: `npm run build` blocked by active `rescript watch` lock (PID 3436 from dev `npm run res:watch`); validated bundle with `npx rsbuild build`.
  - [x] Add export runtime touch detection and expose `isExportTouchDevice()` for input policy decisions.
  - [x] Default Looking Mode OFF for touch-primary or portrait contexts at startup.
  - [x] Force Looking Mode ON only when a map-driven navigation occurs in non-touch, non-portrait contexts.
  - [x] Initialize Looking Mode UI state before first scene load so the indicator text/status reflects default policy immediately.
  - [x] Re-verify bundling; `npx rsbuild build` passes, full `npm run build` still blocked by active `rescript watch` lock (current PID 4907).
  - [x] Suppress one-time room-label rendering during auto-tour bootstrap navigation to Home to remove transient panel flash.
  - [x] Re-verify bundling; `npx rsbuild build` passes, full `npm run build` still blocked by active `rescript watch` lock (current PID 6871).
  - [x] Hide `home` shortcut when current scene is already Home (first scene) to avoid redundant action.
  - [x] Re-verify bundling; `npx rsbuild build` passes, full `npm run build` still blocked by active `rescript watch` lock (current PID 8281).
  - [x] Audit all Looking Mode ON/OFF transitions and normalize map-mode behavior to preserve manual/default preference after map close.
  - [x] Re-verify bundling; `npx rsbuild build` passes, full `npm run build` still blocked by active `rescript watch` lock (current PID 8281).
  - [x] Remove persistent side-effect from map open (`manualLookingMode=false`) and restore `lookingMode` from `manualLookingMode` on map close.

- [ ] Code Change Ledger
  - [x] `src/systems/TourTemplates/TourStyles.res` - removed map-mode global dim overlay, simplified map row visuals to match existing panel feel, kept centered square-ish proportional sizing without replacing panel chrome, and aligned map shortcut text colors with main panel white.
  - [x] `src/systems/TourTemplates/TourScriptUI.res` - map open disables looking mode (`manualLookingMode=false`, `lookingMode=false`, `updateLookingModeUI()`), map panel remains content-fit, `e exit map mode` renders last, map shortcut keys navigate scenes, and map-origin navigation now requests Looking Mode re-enable via `enableLookingModeAfterMapNavigation`.
  - [x] `src/systems/TourTemplates/TourScriptInput.res` - added `E` key handling for exit map mode, added map-mode key routing through `navigateExportMapShortcut`, kept map close behavior consistent with `Esc`, and defaulted Looking Mode based on touch/portrait policy with `shouldEnableLookingModeByDefault`.
  - [x] `src/systems/TourTemplates/TourScriptViewport.res` - introduced touch-primary input detection (`detectTouchPrimaryInput`, `isExportTouchDevice`) and state/class updates in `updateExportStateClasses`.
  - [x] `src/systems/TourTemplates.res` - apply `updateLookingModeUI()` immediately after `updateExportStateClasses()` so the initial indicator reflects touch/portrait defaults before first scene-load callback.
  - [x] `src/systems/TourTemplates/TourScriptUI.res` - added `suppressNextRoomLabelOnLoad` state and set it when auto-tour starts from non-home scene (bootstrap jump to Home).
  - [x] `src/systems/TourTemplates/TourScripts.res` - in viewer load handler, consume one-time suppression flag and skip room-label rendering for that load only.
  - [x] `src/systems/TourTemplates/TourScriptUI.res` - `updateNavShortcutsV2` now renders `h home` only when `sceneId` is not already the resolved home scene.
  - [x] `src/systems/TourTemplates/TourScriptUI.res` - map open now only sets runtime `lookingMode=false` temporarily; map close restores `lookingMode=manualLookingMode` and refreshes indicator UI.
  - [x] `src/systems/TourTemplates/TourScriptUI.res` - explicit fix applied so map mode no longer mutates manual preference state, only temporary runtime state.

- [ ] Rollback Check
  - [x] Confirmed CLEAN (no non-working edits retained; frontend build passes via `npx rsbuild build`, full `npm run build` currently blocked by active ReScript watch lock).

- [ ] Context Handoff
  - [x] Removed full-screen blue dim effect; map mode no longer introduces global overlay tint.
  - [x] Map stays centered and square-ish with proportional sizing across export viewport states while preserving glass-panel identity.
  - [x] Looking mode is explicitly disabled when entering map mode; map supports `e`/`Esc` exits and the `e exit map mode` row is pinned to the bottom of map shortcuts.
  - [x] Map floor shortcut keys now navigate while map mode is open (same keys shown in the panel), and all map shortcut text/key colors are white to match main panel styling.
  - [x] Map-driven navigation now turns Looking Mode back ON only on non-touch, non-portrait contexts.
  - [x] Export runtime now detects touch-first devices and defaults Looking Mode OFF (also OFF by default in portrait).
  - [x] Auto-tour start no longer flashes the room-label glass chip during the immediate jump back to Home; suppression is one-load only and scoped to this bootstrap transition.
  - [x] Home shortcut is no longer shown while the viewer is already on Home, reducing redundant clutter in shortcut panel.
  - [x] Looking Mode defaults are now consistent with user/manual intent after map mode exits (no persistent forced-OFF side effect from merely opening map).
