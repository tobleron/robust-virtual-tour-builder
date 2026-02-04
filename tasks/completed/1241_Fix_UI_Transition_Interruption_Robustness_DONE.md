# Task 1241: Fix UI Transition Interruption Robustness

## Objective
Improve the robustness of UI transitions when interrupted by rapid keyboard or mouse input (e.g., Escape key).

## Problem Analysis
- The `NavigationFSM` gets stuck in the `Preloading` state when a transition is interrupted or aborted by an external action (like pressing 'Escape').
- `ReBindings.AbortController` is used in `useThrottledAction`, but the aborted state isn't propagated back to the FSM to transition it back to `Idle`.

## Proposed Solution
- Add an `Aborted` event to `NavigationFSM.res` that transitions any state back to `Idle`.
- In `NavigationController.res` or where the 'Escape' key is handled, dispatch the `Reset` or `Aborted` event to the FSM.
- Ensure `isInteractionPermitted` in `Hooks.res` correctly reflects the restored stability.

## Acceptance Criteria
- [ ] UI remains functional after rapid interruptions during transitions.
- [ ] The application doesn't get stuck in a "Preloading" or "Transitioning" state.
- [ ] Corresponding test in `robustness.spec.ts` passes.
