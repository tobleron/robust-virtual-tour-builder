# Task 571: UI Performance - Debounce High-Frequency State Updates

## Objective
Implement debouncing for UI inputs that trigger global state updates to prevent "input lag" caused by full-app re-renders.

## Requirements
- Identify high-frequency inputs (e.g., "Project Name" in Sidebar).
- Implement local state management for these inputs.
- Use a debounced effect to dispatch the global action.

## Success Criteria
- Typing speed is unaffected by the complexity of the app's render tree.
- Global state is eventually consistent with the local input.
