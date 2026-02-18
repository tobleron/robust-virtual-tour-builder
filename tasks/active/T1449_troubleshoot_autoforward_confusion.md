# Troubleshooting Task: T1449 - Auto-forward Confusion

## Hypothesis
- [ ] **Stale Navigation State**: The auto-forward intent or status in `NavigationState` is not being properly cleared when a transition completes or when entering a non-autoforward scene.
- [ ] **Race Condition / Missing Abort**: A pending auto-forward transition from a previous scene is not being aborted when the user manually navigates or when a regular transition occurs.
- [ ] **Incorrect Intent Selection**: The logic that triggers auto-forward is picking up an 'auto-forward' hotspot that doesn't belong to the current scene or is misidentified.

## Activity Log
- [ ] Initial research into `NavigationState.res` and `SceneSwitcher.res`.
- [ ] Audit `NavigationSupervisor.res` for auto-forward handling and cancellation.
- [ ] Test scene transitions with and without auto-forward hotspots.

## Code Change Ledger
| File Path | Change Summary | Revert Note |
|-----------|----------------|-------------|
|           |                |             |

## Rollback Check
- [ ] (Confirmed CLEAN or REVERTED non-working changes)

## Context Handoff
User reported that a scene without auto-forward hotspots auto-advanced after a scene that *did* have one. Investigating state persistence and transition logic.
