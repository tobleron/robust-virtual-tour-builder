# Task 580: Refactor ViewerUI (Aggressive Separation of Concerns)

## 🚨 Trigger
Project "Surgical Edit" Initiative.
File \`src/components/ViewerUI.res\` is a "God Object" (579 lines) handling Layout, Notification, Context Menus, and Simulation State.

## Objective
Decompose \`ViewerUI.res\` into specialized sub-components. Aim for < 200 lines per file.

## Required Sub-Components
1. **ViewerHUD.res**: Pure UI for Play/Stop buttons and utility bar.
2. **NotificationLayer.res**: Logic for Toast/Notification subscription and rendering.
3. **LabelMenu.res**: Encapsulate the entire Context Menu logic (Label setting).
4. **SnapshotOverlay.res**: Handle the flash/snapshot transition visual logic.

## Safety & Constraints
- **Zero Functionality Change**: The user behavior must remain exactly identical.
- **Incremental**: Extract one component at a time, verify, commit.
- **Pass Props**: Avoid prop-drilling hell; use \`AppContext\` hooks inside the new components if appropriate, but keep them decoupled.
