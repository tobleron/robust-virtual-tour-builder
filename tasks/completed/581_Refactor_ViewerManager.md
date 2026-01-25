# Task 581: Refactor ViewerManager (Input Logic Separation)

## 🚨 Trigger
Project "Surgical Edit" Initiative.
File \`src/components/ViewerManager.res\` mixes raw Input Handling, Physics (Cursor Guide), and Business Logic (Linking).

## Objective
Isolate Input Handling and Physics from high-level Business Logic.

## Required Refactoring
1. **InputSystem.res**: Create a new system or hook that normalizes Mouse/Pointer events.
2. **LinkEditorLogic.res**: Move the "Linking Mode" click handlers here.
3. **CursorPhysics.res**: Move the yellow rod velocity smoothing logic here.

## Safety & Constraints
- **Regression Testing**: Test Mouse Interactions (Looking around) and Linking Mode (Adding lines) heavily.
- **Event Listeners**: Ensure \`removeEventListener\` is called correctly in new hooks.
