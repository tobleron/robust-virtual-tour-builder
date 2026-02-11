# [1334] Consolidate Notification System — Remove Legacy, Eliminate Redundancy

## Priority: P1 (High)

## Context
The notification system currently has **5+ overlapping mechanisms** that evolved organically. This causes:
- **Toast storms**: Multiple notifications for a single user action
- **Confusion**: Developers don't know which notification path to use
- **Dead code**: "Legacy" modules that are still imported but serve no unique purpose

### Current Notification Mechanisms

| Module | Role | Status |
|--------|------|--------|
| `NotificationManager.res` | Queue-based dispatch (importance, dedup, throttle) | **Active — KEEP as sole dispatcher** |
| `NotificationQueue.res` | Queue data structure | **Active — KEEP** |
| `NotificationTypes.res` | Type definitions | **Active — KEEP** |
| `NotificationCenter.res` | Custom ReScript toast renderer | **Active — KEEP as sole renderer** |
| `NotificationContext.res` | React Context provider | **Legacy — REMOVE** |
| `NotificationLayer.res` | Progress event notification layer | **Legacy — REMOVE** |
| `EventBus.dispatch(ShowNotification(...))` | Pub/sub notification dispatch | **Evaluate — may be redundant** |

## Objective
Consolidate to a **single notification pipeline**:

```
Any Module → NotificationManager.dispatch(notification)
  → NotificationQueue (dedup + throttle + priority sort)
  → NotificationCenter (renders toasts inside ViewerUI HUD)
```

Remove `NotificationContext.res` and `NotificationLayer.res` entirely.

## Implementation

### Phase 1: Audit Current Usage

1. `grep -r "NotificationContext\." src/ --include="*.res"` — Find all consumers
2. `grep -r "NotificationLayer\." src/ --include="*.res"` — Find all consumers
3. `grep -r "EventBus.dispatch(ShowNotification" src/` — Find EventBus notification dispatchers
4. For each consumer, determine if it should migrate to `NotificationManager.dispatch(...)` or be removed

### Phase 2: Migrate Consumers

**For each file importing `NotificationContext`:**
- Replace with `NotificationManager.dispatch(...)` using the standard notification record type
- If it was using Context for "reading" notification state → use `NotificationManager` subscription instead

**For each file importing `NotificationLayer`:**
- Determine if the notification is still needed
- If yes → migrate to `NotificationManager.dispatch(...)` with appropriate `importance` level
- If no → remove the call entirely

**For `EventBus.dispatch(ShowNotification(...))` callers:**
- Replace with direct `NotificationManager.dispatch(...)` calls
- Remove the `ShowNotification` variant from `EventBus` event types (if no other consumers remain)

### Phase 3: Delete Legacy Modules

- [ ] Delete `src/components/NotificationContext.res` (and `.resi` if exists)
- [ ] Delete `src/components/NotificationLayer.res` (and `.resi` if exists)
- [ ] Remove from `rescript.json` sources if separately listed
- [ ] Remove any CSS specific to the legacy notification layer

### Phase 4: Clean Up Redundancy (Addresses Task 1327)

This task **supersedes** task 1327 (Refactor Notification Logic). Apply the 1327 improvements as part of this consolidation:
- Remove redundant "Upload Started" / "Upload Complete" toasts where sidebar progress is visible
- Consolidate network error messages in `AuthenticatedClient.res`
- Add `id` constants to `NotificationTypes.res` for throttling keys
- Adjust `importancePriority` rankings

## Relationship to Task 1327
Task 1327 proposes patching notification redundancy without removing the legacy modules. This task (1334) is the **architectural solution** that also addresses 1327's goals. When 1334 is completed, 1327 should be moved to completed with `_SUPERSEDED` suffix.

## Verification
- [ ] `grep -r "NotificationContext\." src/` returns **0 results** (excluding test files)
- [ ] `grep -r "NotificationLayer\." src/` returns **0 results** (excluding test files)
- [ ] No "toast storms" during: upload, export, scene switching, save/load
- [ ] `npm run build` passes cleanly
- [ ] E2E: `robustness.spec.ts` passes
- [ ] E2E: `upload-link-export-workflow.spec.ts` passes

## Files Affected
- `src/components/NotificationContext.res` → DELETE
- `src/components/NotificationLayer.res` → DELETE
- ~5-10 consumer files → migrate to `NotificationManager.dispatch(...)`
- `src/core/NotificationTypes.res` → add throttling IDs
- `MAP.md` → remove deleted modules
- `DATA_FLOW.md` → simplify notification flow

## Estimated Effort: 2 days
