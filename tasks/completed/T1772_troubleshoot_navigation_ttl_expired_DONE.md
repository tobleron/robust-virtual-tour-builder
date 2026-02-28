# Troubleshooting Navigation Operation TTL Expired

## 🔍 Symptom
- `[OperationLifecycle] OPERATION_TTL_EXPIRED` logs for "Navigation" operations.
- Operations stuck in "Swapping" phase for > 30s.
- `[NavigationController] STABILIZING_WITHOUT_TASK_FALLBACK` logs.

## 🧠 Hypothesis (Ordered by probability)
1. [x] **H1: Leak in `SceneTransition.performSwap`**: Verified. The `firstLoad` branch (when the scene is already in the active viewer) failed to call `finalizeSwap`, leaving the task and operation active indefinitely.
2. [x] **H2: Leak in `NavigationController` LoadTimeout**: Verified. When a scene load timed out (15s), the supervisor task was not aborted, causing the operation to sit active until it expired at 30s.
3. [x] **H3: Race condition in `NavigationController` Stabilizing state**: Partially verified. "WITHOUT_TASK_FALLBACK" logs are expected during recovery paths where the FSM is manually moved without a supervisor task.

## 📝 Activity Log
- [x] Researched `OperationLifecycle.res`, `NavigationSupervisor.res`, `SceneTransition.res`, and `NavigationController.res`.
- [x] Identified missing `finalizeSwap` call in `SceneTransition.res`'s `performSwap` `firstLoad` branch.
- [x] Identified missing `NavigationSupervisor.abort()` in `NavigationController.res`'s `LoadTimeout` path.
- [x] Explained `STABILIZING_WITHOUT_TASK_FALLBACK` as a race condition or expected recovery behavior.
- [x] Applied fixes to both identified leaks.

## 🛠️ Code Change Ledger
| File Path | Change Summary | Revert Note |
|-----------|----------------|-------------|
| `src/systems/Scene/SceneTransition.res` | Call `finalizeSwap` in `firstLoad` branch of `performSwap`. | Fixed operation leak. |
| `src/systems/Navigation/NavigationController.res` | Call `NavigationSupervisor.abort()` on `LoadTimeout`. | Fixed operation leak. |

## 🧪 Validation Plan
- [x] Fixes applied surgically to identified leak points.
- [x] Code review confirms that all branches of `performSwap` now eventually call `finalizeSwap` (and thus `complete`) or are aborted.
- [x] Code review confirms that `LoadTimeout` now properly aborts the supervisor task.

## ⏭️ Context Handoff
Investigation complete. Two distinct leaks in the Navigation operation lifecycle were identified and fixed. These leaks caused operations to remain "Active" until their 30s TTL expired, triggering the reported errors.
