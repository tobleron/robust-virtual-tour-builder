# 1929 — Replace Belt.Array.getExn with Safe Array Access

**Priority:** 🟠 P1  
**Effort:** 45 minutes  
**Origin:** Codebase Analysis 2026-03-22

## Context

The project's coding vitals mandate: *"Use `Option`/`Result` explicitly. NO `unwrap()`, `panic!`"*. However, 7 call sites use `Belt.Array.getExn`, which throws a JavaScript exception on out-of-bounds access. This is especially dangerous in `PersistenceLayerRecovery.res`, where a corrupt IndexedDB state could crash the recovery system — the one system that must never crash.

## Scope

### Call Sites to Fix

| File | Line | Current Code |
|---|---|---|
| `src/utils/PersistenceLayerRecovery.res` | 46 | `Belt.Array.getExn(sliceResults, 0)` |
| `src/utils/PersistenceLayerRecovery.res` | 50 | `Belt.Array.getExn(sliceResults, 1)` |
| `src/utils/PersistenceLayerRecovery.res` | 54 | `Belt.Array.getExn(sliceResults, 2)` |
| `src/utils/PersistenceLayerRecovery.res` | 58 | `Belt.Array.getExn(sliceResults, 3)` |
| `src/core/AppContextProviderHooks.res` | 59 | `queuedActions->Belt.Array.getExn(0)` |
| `src/utils/WorkerPoolCore.res` | 79 | `pool.workers->Belt.Array.getExn(idx)` |
| `src/utils/WorkerPoolCore.res` | 188 | `Belt.Array.getExn(parts, 0)` |

### Pattern

Replace each `getExn` with `Belt.Array.get` + appropriate `Option` handling:

```rescript
// BEFORE (crashes on out-of-bounds)
let worker = pool.workers->Belt.Array.getExn(idx)

// AFTER (safe with explicit handling)
switch pool.workers->Belt.Array.get(idx) {
| Some(worker) => // use worker
| None =>
  Logger.error(~module_="WorkerPoolCore", ~message="Worker index out of bounds", ())
}
```

### Steps

1. Fix all 7 call sites listed above
2. For `PersistenceLayerRecovery.res`, add graceful degradation on missing slices
3. For `AppContextProviderHooks.res`, the single-action case is guaranteed by the `| 1 =>` guard; still replace for hygiene
4. For `WorkerPoolCore.res`, add bounds-checking with Logger.error on failure
5. Run `npm run build` to verify compilation
6. Run `npm run test:frontend` to check for regressions

## Acceptance Criteria

- [ ] Zero `Belt.Array.getExn` calls remain in `src/` (verify with grep)
- [ ] All replaced sites use `Belt.Array.get` + explicit `Option` handling
- [ ] `npm run build` passes with zero warnings
- [ ] Existing tests pass
