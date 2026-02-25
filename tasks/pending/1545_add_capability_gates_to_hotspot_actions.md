# 1545 — Add Capability.Policy Gates to Hotspot Actions (PreviewArrow.res)

## Priority: P1 — Hardening

## Objective
Gate hotspot move, delete, and auto-forward toggle actions behind `Capability.Policy.evaluate()` to prevent data corruption during system-blocking states.

## Context
Currently, `PreviewArrow.res` handlers only check `isMovingAny` before allowing hotspot modifications. They do NOT check:
- Whether the app is in `SystemBlocking` mode (upload, export, project load)
- Whether `CanMutateProject` is allowed by the Capability Policy
- Whether active operations (via `OperationLifecycle`) conflict

This means a user could modify hotspots during a project load or export, leading to state inconsistencies.

## Acceptance Criteria
- [ ] `handleRightClick` (auto-forward toggle) checks `Capability.Policy.evaluate(~capability=CanEditHotspots, ...)`
- [ ] `handleDeleteClick` checks `Capability.Policy.evaluate(~capability=CanMutateProject, ...)`
- [ ] `handleMoveClick` checks `Capability.Policy.evaluate(~capability=CanMutateProject, ...)`
- [ ] `handleMainClick` (navigate) checks `Capability.Policy.evaluate(~capability=CanNavigate, ...)`
- [ ] When blocked, show a non-intrusive notification: "Please wait for current operation to finish"
- [ ] Builds cleanly

## Implementation Guide
1. At the top of each handler, read `appMode` from state and active operations from `OperationLifecycle.getOperations()`
2. Call `Capability.Policy.evaluate(~capability=..., ~appMode=..., ops)`
3. If `false`, show notification and return early
4. Reference: `SidebarLogicHandler.res` line 408-425 for the same pattern used in upload gating

## Files to Modify
- `src/components/PreviewArrow.res`

## Testing
- Manually trigger an export, then try to delete/move a hotspot → should be blocked
- Existing `Capability_v.test.res` validates the policy logic; this task only wires it into the UI
