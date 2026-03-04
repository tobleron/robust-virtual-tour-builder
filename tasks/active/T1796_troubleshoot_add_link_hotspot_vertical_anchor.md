# T1796 Troubleshoot Add-Link Hotspot Vertical Anchor

- [x] **Hypothesis (Ordered Expected Solutions)**
  - [x] New hotspot creation uses crosshair pitch directly, while legacy behavior expected bottom-of-guidebar offset.
  - [ ] A recent normalization path clears `displayPitch` and makes rendered marker snap to center anchor.
  - [ ] Offset constant sign/regression caused opposite shift after recent UI/placement tweaks.

- [x] **Activity Log**
  - [x] Traced add-link capture through `Main.res` viewer-click listener and `LinkModal` save path.
  - [x] Confirmed mismatch: `Main.res` was persisting raw `detail.pitch` (crosshair center), bypassing rod-tip offset logic used elsewhere.
  - [x] Patched event payload in `ViewerAdapter` to include `clientX/clientY`.
  - [x] Patched `Main.res` linking flow to re-project pitch using `clientY + Constants.linkingRodHeight` via `Viewer.mouseEventToCoords` before writing draft points.
  - [x] Verified compilation/build with `npm run res:build` and `npm run build`.

- [x] **Code Change Ledger**
  - [x] `src/systems/Viewer/ViewerAdapter.res`
    - Extended dispatched `viewer-click` detail payload with `clientX` and `clientY`.
  - [x] `src/Main.res`
    - Added `clientX/clientY` to `ViewerClickEvent.detail`.
    - In add-link draft capture path, replaced raw pitch usage with adjusted pitch projected from rod-tip offset (`linkingRodHeight`).

- [x] **Rollback Check**
  - [x] Confirmed CLEAN for this troubleshooting scope (no temporary debug edits left).

- [x] **Context Handoff**
  - [x] Root cause was split capture logic: `Main.res` add-link path used crosshair center pitch instead of rod-tip projection.
  - [x] Fix is surgical and localized to viewer-click payload + add-link draft capture projection.
  - [x] User should visually verify new hotspot now lands at bottom of yellow bar during add-link mode.
