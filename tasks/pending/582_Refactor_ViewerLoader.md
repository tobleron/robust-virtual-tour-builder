# Task 582: Refactor ViewerLoader (Lifecycle Management)

## 🚨 Trigger
Project "Surgical Edit" Initiative.
File \`src/components/ViewerLoader.res\` handles Pannellum Lifecycle, Scene Swapping, Crossfades, and Error Recovery in one giant file.

## Objective
Split the lifecycle phases into distinct managers.

## Required Refactoring
1. **SceneTransitionManager.res**: Handle the DOM-level crossfade and visibility toggles.
2. **PannellumLifecycle.res**: Isolate the \`viewer.init()\` and \`viewer.destroy()\` calls.
3. **SceneLoader.res**: Handle the async pre-fetching and validation logic.

## Safety & Constraints
- **Visual Smoothness**: The scene swap must NOT flicker.
- **Race Conditions**: Verify rapid scene switching doesn't break state.
