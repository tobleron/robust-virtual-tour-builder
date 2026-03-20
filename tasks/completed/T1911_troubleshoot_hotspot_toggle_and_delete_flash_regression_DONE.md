# T1911 Troubleshoot Hotspot Toggle And Delete Flash Regression

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [ ] Numbered hotspot rendering now suppresses the center forward icon, so the old auto-forward double-flash + icon swap still runs logically but is no longer visible.
  - [ ] The drawer closes during toggle/delete action timing, hiding the flicker animation on the secondary button before it finishes.
  - [ ] Later hover-drawer persistence changes altered visibility timing, so the old flicker classes are still applied but not kept on-screen long enough to read.

- [ ] **Activity Log**
  - [x] Compare current `PreviewArrow` logic against older working commits.
  - [x] Confirm whether the flicker/swap state still exists in code.
  - [x] Patch the hotspot UI so action animations remain visible during toggle/delete.
  - [x] Verify with `npm run build`.

- [ ] **Code Change Ledger**
  - [x] `src/components/PreviewArrow.res` - kept the drawer open during toggle/delete animation, exposed the center icon during auto-forward swap, and added a whole-hotspot collapse state for delete. Revert by dropping `isDeleting`/`effectiveDrawerOpen` and restoring the original center-content and root class behavior.
  - [x] `src/components/PreviewArrowSupport.res` - delayed the auto-forward state flip until mid-swap and delayed hotspot removal until after the whole-hotspot collapse. Revert by restoring the immediate `setLocalIsAF` and direct post-flash `RemoveHotspot` dispatch.

- [ ] **Rollback Check**
  - [x] Confirmed CLEAN or REVERTED non-working changes.

- [ ] **Context Handoff**
  - [x] The old hotspot UX had a visible double-flash on auto-forward toggle followed by a center-icon swap, and a visible flash on trash before deletion.
  - [x] Current code still contains flicker/swap state, so the regression is likely presentation timing and sequence-label rendering rather than the action handlers themselves.
  - [x] Continue in `src/components/PreviewArrow.res` first; CSS changes should be secondary unless the component-level forced-open state proves insufficient.
