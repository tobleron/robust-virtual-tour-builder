# 🐛 TROUBLESHOOTING: Hotspot Move UX & Persistence (T1562)

## 📋 Problem Statement
After moving hotspots to a React-managed layer:
1.  **Menu Retention**: The hotspot action buttons (HUD) remain visible and follow the mouse during "Move" mode, cluttering the view.
2.  **Commit Failure**: Clicking a new location often fails to persist the move, reverting the hotspot to its original position.
3.  **Unclosed Popover**: If the move is started from the action menu Popover, it might stay open as it anchors to the moving hotspot.

## 🔗 Related Context
- `src/components/ReactHotspotLayer.res`
- `src/components/PreviewArrow.res`
- `src/components/HotspotActionMenu.res`
- `src/Main.res` (Global click listener)

## 🎯 Objective
- Ensure a clean "Move" experience where only the moving cursor/hotspot is visible.
- Ensure clicking the panorama reliably commits the new location.
- Ensure any open menus/popovers close immediately when movement starts.

## ✅ Acceptance Criteria
- Starting movement closes the Popover action menu.
- During movement, sub-buttons (Delete, Toggle) are hidden.
- Clicking the panorama surface commits the move.
- The hotspot persists at the new location after commit.
- `npm run build` passes.

## 🔬 Hypothesis (Ordered Expected Solutions)
- [x] **H1: Event Swallowing**: Confirmed. Clicks were being blocked by the hotspot's interactive area. Fixed by making the center button `pointer-events-none` during move.
- [x] **H2: Hover Persistence**: Confirmed. Hotspot following the mouse kept the `:hover` state active. Fixed by removing the `group` class and hiding sub-buttons during move.
- [x] **H3: Popover Anchor Drift**: Fixed by adding an explicit close effect when movement is detected.

## 🧪 Reproduction & Investigation Plan
1. [x] Check `ReactHotspotLayer.res` div `pointer-events`.
2. [x] Check `PreviewArrow.res` visibility logic.
3. [x] Verify `Main.res` listener behavior.

## 📝 Activity Log
- [x] Task initialized.
- [x] Roots causes for move persistence and menu "clinginess" identified.
- [x] Applied surgical pointer-events fix to `PreviewArrow.res` (Center button `none` during move).
- [x] Refined `PreviewArrow.res` to suppress UI expansion during movement.
- [x] Added menu-close guard to `HotspotMenuLayer.res`.
- [x] Verified compilation success.

## 📜 Code Change Ledger
| File Path | Change Summary | Revert Note |
|-----------|----------------|-------------|
| `src/components/ReactHotspotLayer.res` | Reverted pointer-events-none on parent div to keep sub-elements interactive. | Restore pointer-events-none |
| `src/components/PreviewArrow.res` | Disabled 'group' class and center button pointer-events during move. Hid sub-buttons. | Restore group class and sub-buttons |
| `src/components/HotspotMenuLayer.res` | Added auto-close effect for Popover when movement starts. | Remove isMoving effect |

## 🔄 Rollback Check
- [ ] Confirmed CLEAN.
