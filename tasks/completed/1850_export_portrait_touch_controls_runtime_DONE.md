## Objective

Implement the approved portrait-mode exported-tour control system in the real runtime. Any portrait viewport should use the compact 3-mode selector and portrait navigation controls, while landscape modes keep the current export UI unchanged.

## Context

- The artifact preview in `artifacts/Export_RMX_kamel_al_kilany_080326_1528_v5.2.4 (2)/desktop/index.html` established the desired portrait mobile layout and interactions.
- The real export runtime now supports a shell split foundation in `src/systems/TourTemplates/TourScriptViewport.res`, with `classic` and `portrait-adaptive` shells active and `landscape-touch` reserved for a later pass.
- Portrait mode no longer uses the old keyboard/list shortcut panel. It uses a centered intro selector, docked top-left mode orbs, clickable floor pills, and a portrait joystick.
- Touch drag speed was restored to the original feel, while post-release momentum is now tuned separately through the export Pannellum config and library patch.
- Looking mode should be unavailable in portrait and touch-friendly shells because swipe navigation already covers that interaction model.

## Implementation Requirements

- Add a dedicated portrait runtime gate using the existing export viewport detection.
- In portrait mode:
  - Replace the old shortcut list with a centered intro selector using three circular mode orbs in this order:
    - `Semi-Auto`
    - `Manual`
    - `Auto`
  - Make `Semi-Auto` the default selected mode and restore the old once-per-scene manual animation behavior for that mode.
  - Keep `Manual` as the short post-arrival focus-pan mode with no full waypoint playback.
  - Keep `Auto` as the home-resetting auto-tour mode, with the existing `Auto -> 1x -> 1.7x -> stop` cycle on repeated taps.
  - While the centered intro selector is visible, hide the other portrait UI and grayscale the tour background.
  - After selection, animate the selector back to the top-left docked position and restore the rest of the portrait UI.
  - Keep the selector docked inside the portrait stage frame, stacked vertically at the top-left, rather than fixed to the browser window.
  - Keep the floor pills clickable and route them to the first scene on the selected floor using stable scene numbering.
  - Keep the bottom-center up/down joystick using the same arrow visual language as the existing shortcut arrows.
- Restore touch drag speed to the original value and increase only post-release momentum.
- Disable looking mode UI and activation paths while portrait or touch-friendly export shells are active.
- Preserve all existing export behavior outside portrait mode and keep the code structured for a later `landscape-touch` shell without changing desktop mode now.
- Do not change landscape UI in this task.

## Verification

- Focused export runtime tests updated for viewport shell helpers, portrait styling, momentum config, and exported control hosts.
- Export runtime build passes.
- Portrait export CSS and runtime script coverage updated.
- `npm run test:frontend` passes.
- `npm run build` passes.
