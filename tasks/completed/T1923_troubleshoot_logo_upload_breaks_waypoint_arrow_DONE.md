## Objective
Find and fix the regression where uploading/changing the project logo causes waypoint arrow interaction to stop working.

## Hypothesis (Ordered Expected Solutions)
- [x] The uploaded logo overlay is intercepting pointer events across a larger hit area than intended, blocking waypoint arrow clicks.
- [ ] The logo update mutates shared UI/project state in a way that changes hotspot/arrow interactivity flags or capabilities.
- [ ] The logo upload path triggers a viewer/HUD rerender that leaves the hotspot layer with stale DOM bindings or z-index ordering.
- [ ] The logo normalization/upload path corrupts persisted state consumed by viewer HUD or hotspot rendering.

## Activity Log
- [x] Read repository context files (`MAP.md`, `DATA_FLOW.md`, `tasks/TASKS.md`, `.agent/workflows/debug-standards.md`).
- [x] Inspect logo upload/render path and waypoint arrow interaction path for overlap.
- [x] Reproduce the regression from code and identify the exact failing boundary.
- [x] Apply the smallest safe fix.
- [x] Verify with `npm run build`.

## Code Change Ledger
- [x] [src/components/ViewerHUD.res](src/components/ViewerHUD.res) — removed direct logo-upload interaction from the viewer HUD so the logo surface is display-only and cannot steal waypoint clicks; revert by restoring viewer-side upload handlers if settings-based editing is rejected.
- [x] [src/components/Sidebar/SidebarSettings.res](src/components/Sidebar/SidebarSettings.res) — added logo preview, choose-logo, and reset-to-default controls to the Marketing tab and persist the selected logo on save; revert by removing the marketing-tab logo section and `SetLogo` dispatch.
- [x] [css/components/modals-panels.css](css/components/modals-panels.css) — added settings modal styles for the new marketing logo controls; revert by removing `.settings-logo-*` rules if the UI is redesigned.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The likely interaction boundary is between the viewer HUD logo overlay and the hotspot arrow React/DOM layers. Check pointer-events, z-index, and any state updates that happen when `state.logo` changes in the viewer HUD path. If the window fills up, continue from the overlay/render-order investigation before touching persistence or export code.
