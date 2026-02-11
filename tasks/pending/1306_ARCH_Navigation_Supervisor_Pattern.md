# [1306] Navigation Supervisor Pattern — Implementation Plan

## Status: PROMOTED from Postponed → Pending (Feb 11, 2026)

## Context
The navigation system uses a **Distributed Locking Mechanism** (`TransitionLock.res`) combined with **Reactive Side Effects** (React Hooks in `NavigationController.res` triggering `SceneLoader`). While functional, this architecture is susceptible to **Deadlocks** and **Race Conditions** because the synchronization logic is scattered across 4+ modules.

The deadlock risk is structural: if any code path that calls `TransitionLock.acquire()` fails to reach the corresponding `TransitionLock.release()`, the lock stays permanently held. This has already occurred in production.

## Objective
Replace the distributed lock pattern with a **Centralized Navigation Supervisor** that uses structured concurrency (AbortController/AbortSignal). The Supervisor owns the lifecycle of scene transitions:
- **Intent-Based**: Components send navigation requests, not direct commands.
- **Auto-Cancel**: New requests automatically cancel in-flight requests.
- **Zero Deadlocks**: No lock to acquire/release — the Supervisor either finishes or replaces a task.

## Architecture Change

```
BEFORE (Distributed Lock):
  Component → TransitionLock.acquire() → SceneLoader → SceneTransition → TransitionLock.release()
                      ↑ DEADLOCK if release() never reached

AFTER (Supervisor):
  Component → Supervisor.requestNavigation(sceneId)
                      → Auto-cancel previous task (AbortController.abort())
                      → SceneLoader (with AbortSignal) → SceneTransition
                      → Supervisor.complete(taskId)
                      ↑ ZERO DEADLOCK — no lock, just task replacement
```

## Affected Files

| File | Role | LOC |
|------|------|-----|
| `TransitionLock.res` | Current lock (to be deprecated) | 268 |
| `NavigationFSM.res` | FSM state machine (retained) | 127 |
| `NavigationController.res` | Hook-based side effects | 178 |
| `SceneLoader.res` | Scene loading + viewer creation | 390 |
| `SceneTransition.res` | DOM swap + cleanup | 190 |
| `SceneSwitcher.res` | Navigation entry point | 208 |
| `LockFeedback.res` | UI progress indicator | ~50 |
| + 6 read-only consumers | `isIdle()` checks | ~15 total |

## Subtasks (Execute in Order)

| # | Task | Scope | Est. |
|---|------|-------|------|
| **1328** | [Create NavigationSupervisor Module](./1328_NAV_SUP_1_Create_Supervisor_Module.md) | New module: types, state, core functions | 3-4h |
| **1329** | [Add AbortSignal Bindings](./1329_NAV_SUP_2_Add_AbortSignal_Bindings.md) | ReScript bindings for AbortController/Signal | 1h |
| **1330** | [Wire SceneLoader & SceneTransition](./1330_NAV_SUP_3_Wire_SceneLoader_To_Supervisor.md) | Dual-mode: add Supervisor path alongside TransitionLock | 4-6h |
| **1331** | [Switch Entry Points](./1331_NAV_SUP_4_Switch_Entry_Points_To_Supervisor.md) | Route SceneSwitcher, SceneItem, Simulation through Supervisor | 2-3h |
| **1332** | [Remove TransitionLock from Navigation](./1332_NAV_SUP_5_Remove_TransitionLock_From_Navigation.md) | Delete all TransitionLock calls from navigation pipeline | 3-4h |
| **1333** | [Migrate LockFeedback, Docs, Final QA](./1333_NAV_SUP_6_Migrate_LockFeedback_And_Update_MAP.md) | LockFeedback migration, MAP.md, DATA_FLOW.md, full E2E | 2-3h |

**Total Estimated Effort: 3-5 days**

## Migration Strategy: Dual-Mode (Safe Rollout)

Tasks 1328-1330 use a **dual-mode** approach: the Supervisor path is activated via an optional `~taskId` parameter. When `None`, the legacy `TransitionLock` path executes. This means:
- After Task 1330: Both paths work. You can test the Supervisor path without breaking the existing flow.
- After Task 1331: Supervisor is default. TransitionLock calls are still present as fallback.
- After Task 1332: TransitionLock is fully removed from navigation. Clean cut.

This approach ensures **zero regression risk** at every step.

## Benefits
1. **Zero Deadlocks**: No lock to get stuck — tasks are replaced, not blocked.
2. **Performance**: Rapid-fire clicks auto-cancel previous loads (saves bandwidth).
3. **Testability**: Supervisor logic is pure orchestration — unit-testable without DOM.
4. **Maintainability**: All navigation side effects in one module, not scattered across 4.
5. **Structured Concurrency**: AbortSignal enables clean resource cleanup on cancellation.

## Verification (Final — Task 1333)
- All 15 E2E test files pass
- `rapid-scene-switching.spec.ts` specifically validates the auto-cancel behavior
- Zero `TransitionLock` imports in navigation pipeline
- MAP.md and DATA_FLOW.md updated
