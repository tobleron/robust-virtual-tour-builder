# Task 1457: StateSnapshot UUID Fix

**Masterplan**: Task 1448 (Network Stability Audit) — Issue 3.3  
**Phase**: 3 (Persistence & Recovery)  
**Depends on**: None  
**Blocks**: None

---

## Objective
Replace `Math.random()` with `Crypto.randomUUID()` for snapshot ID generation, aligning with the rest of the codebase.

## Problem
**Location**: `src/core/StateSnapshot.res` line 25

```rescript
let generateId = () => {
  Math.random()->Float.toString ++ "_" ++ Date.now()->Float.toString
}
```

The rest of the codebase uses `Crypto.randomUUID()` for ID generation (e.g., `AuthenticatedClient.res` line ~158). While collision probability is low with `Math.random()`, it's a style inconsistency and `Crypto.randomUUID()` provides proper UUID v4 guarantees.

## Implementation

```rescript
let generateId = () => {
  try {
    Crypto.randomUUID()
  } catch {
  | _ => "snap_" ++ Float.toString(Date.now()) ++ "_" ++ Float.toString(Math.random())
  }
}
```

This matches the exact fallback pattern used in `AuthenticatedClient.res`.

## Files to Modify

| File | Change |
|------|--------|
| `src/core/StateSnapshot.res` | Update `generateId` to use `Crypto.randomUUID()` with fallback |

## Acceptance Criteria

- [ ] `generateId()` uses `Crypto.randomUUID()` as primary ID source
- [ ] Fallback to `Math.random()` + `Date.now()` if `Crypto` is unavailable
- [ ] Prefix fallback IDs with `snap_` for debuggability
- [ ] Zero compiler warnings
