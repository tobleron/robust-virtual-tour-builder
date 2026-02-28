# 1615 Restore Visual Pipeline Square Scene Switch

## Objective
Restore behavior where clicking a visual pipeline square switches the active scene to the scene represented by that square.

## Scope
- Visual pipeline click handling
- Unit tests and E2E/spec assertions to prevent regression
- No changes to unrelated navigation controls

## Acceptance Criteria
- Clicking a visual pipeline square triggers scene switch to the mapped scene.
- Scene switching remains stable with existing navigation locks/guards.
- Existing UI interactions (scene list, hotspot navigation, map mode) are not regressed.
- Unit and E2E checks include this behavior.

## Verification
- [x] Targeted unit tests covering visual pipeline click-to-switch
- [x] Existing navigation-related unit tests still pass
- [ ] Build passes (blocked locally while ReScript watch process is already running: PID 91896)
