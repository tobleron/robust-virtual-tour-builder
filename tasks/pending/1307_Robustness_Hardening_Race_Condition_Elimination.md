# [1307] Robustness Hardening: Race Condition Elimination & Reliability Fixes (Master Task)

## Executive Analysis

A full-codebase audit (194 ReScript files + Rust backend) was conducted to assess race condition elimination. **Race conditions are NOT eliminated with 100% reliability.** While the navigation system's TransitionLock is battle-hardened (all known deadlocks fixed), several other subsystems contain verified concurrency issues that can cause silent data loss, incorrect processing, and resource leaks.

**Important context:** JavaScript is single-threaded, so these are NOT traditional multi-threaded data races. They are:
- Callback-ordering issues (timers firing in unexpected sequence)
- Stale closures (captured variables become outdated across async boundaries)
- Read-modify-write across async yields (state read, async pause, write with stale data)
- Array mutation during synchronous iteration (listener arrays)
- Unwaited Promises leaving side effects incomplete

The work has been divided into the following sub-tasks for better management and tracking:

## Sub-Tasks

### [1307.1] Frontend Quick Wins (Tier 1)
- **Status:** Completed
- **Link:** `tasks/completed/1307.1_Robustness_Frontend_Quick_Wins_DONE.md`
- **Scope:**
  - Fix 1.1: AsyncQueue Result Ordering Bug
  - Fix 1.2: OperationJournal Unwaited Saves
  - Fix 1.3: PersistenceLayer Data Loss on App Close
  - Fix 1.4: GlobalStateBridge subscribe() In-Place Mutation
  - Fix 1.5: PersistenceLayer Subscriber Leak

### [1307.2] Backend Quick Wins (Tier 2)
- **Status:** Pending
- **Link:** `tasks/pending/1307.2_Robustness_Backend_Quick_Wins.md`
- **Scope:**
  - Fix 2.1: Backend Auth expect() Panics
  - Fix 2.2: FFmpeg/Chrome Zombie Process Leak
  - Fix 2.3: Backend Quota Check-Then-Act Race

### [1307.3] Structural Improvements (Tier 3)
- **Status:** Pending
- **Link:** `tasks/pending/1307.3_Robustness_Structural_Improvements.md`
- **Scope:**
  - Fix 3.1: CircuitBreaker Non-Atomic State Transitions
  - Fix 3.2: Service Worker Stale Cache Strategy
  - Fix 3.3: Backend Geocoding Cache Potential Deadlock

---

## TIER 4: Deferred / Low Priority

These are verified issues but have low probability of manifesting or require disproportionate effort:

| Issue | Why Deferred |
|-------|-------------|
| ViewerState concurrent mutations from hooks | React batches effect execution; verified no user-facing symptoms |
| SceneTransition cleanup vs reuse timing | `setCleanupTimeout(None)` cancellation is effective; no crashes reported |
| TransitionLock callback-during-release | Callbacks are simple logging/cleanup; no state corruption observed |
| EventBus reentrant dispatch | `Belt.Array.concat` creates new arrays; forEach iterates snapshot safely |
| Navigation Supervisor pattern (Task 1306) | Current TransitionLock is stable; deferred until problems re-emerge |

---

## Verification Plan

After all sub-tasks are complete:
1. `npm run build` - Zero warnings
2. `npm run test:frontend` - All unit tests pass
3. `cd backend && cargo test` - All backend tests pass
4. Manual test: Rapid-fire scene clicks (10+ in 2 seconds) - no freeze, no wrong scene
5. Manual test: Upload 5+ images concurrently - verify correct metadata pairing
6. Manual test: Close tab during editing - reopen and verify session recovered
7. `cd backend && cargo clippy` - No new warnings

## Architectural Notes for Future Scalability

1. **No architectural overhaul needed.** The FSM-based navigation, dual-viewer pool, and reducer pattern are sound. The issues are implementation-level, not architectural.
2. **For heavy usage:** The backend's per-IP rate limiting (30 req/sec) and upload quota system are appropriate. Fix 2.3 (atomic quota) is the only blocker for multi-user concurrency.
3. **For scaling beyond single-server:** The Rust backend is stateless except for the geocoding LRU cache and upload tracker. Both use `RwLock` which is single-process only. If scaling to multiple instances, these would need Redis or similar. Not needed now.
4. **AbortController standardization:** Currently used only in Export. Could be extended to SceneLoader/SceneTransition for cleaner cancellation, but TransitionLock works fine. Revisit only if Task 1306 trigger conditions are met.
