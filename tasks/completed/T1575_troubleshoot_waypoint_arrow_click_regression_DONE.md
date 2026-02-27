# T1575 — Troubleshoot Waypoint Arrow Click Regression

- [ ] **Hypothesis (Ordered Expected Solutions)**
- [ ] Restore pointer events for interactive SVG arrow marker elements while keeping guide polylines non-interactive.
- [ ] If needed, scope pointer-events restoration only to IDs that represent preview arrows (`arrow_*`) to avoid menu overlap regressions.
- [ ] Validate z-index/layer precedence still keeps hotspot action controls clickable after restoration.

- [ ] **Activity Log**
- [ ] Confirmed regression source in `src/systems/SvgManager.res` (`drawArrow` and `drawPlus` set to `pointer-events: none`).
- [ ] Patch renderer to re-enable clickability for arrow/plus markers.
- [ ] Rebuild and run targeted unit checks for hotspot/preview behaviors.

- [ ] **Code Change Ledger**
- [ ] `src/systems/SvgManager.res`: revert interactive marker pointer-events from `none` to `auto`; restore cursor pointer for marker click affordance.  
  Revert note: if overlap returns, keep lines non-interactive and add ID-scoped pointer handling instead of global disable.

- [ ] **Rollback Check**
- [ ] Pending (will confirm CLEAN or REVERTED non-working changes after verification).

- [ ] **Context Handoff**
- [ ] Regression began after defensive overlap patch disabled pointer events on all SVG markers.
- [ ] Waypoint preview relies on arrow marker clicks routed by `HotspotLayer` listener (`id` prefix `arrow_`), so pointer disable breaks navigation trigger.
- [ ] Fix path is to keep line paths non-interactive but restore marker interactivity and re-verify menu overlap behavior.
