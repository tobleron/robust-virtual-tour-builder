# 1558 — Replace Belt.Array.getExn with Safe Alternatives

## Priority: P1 — Runtime Safety

## Objective
Replace usages of `Belt.Array.getExn` with safe alternatives to prevent potential runtime crashes.

## Context
Project coding standards (GEMINI.md) mandate: "Use `Option`/`Result` explicitly. NO `unwrap()`, `panic!`, or `console.log`." `Belt.Array.getExn` is a function that will throw a runtime exception if the index is out of bounds, violating this rule.

Two usages found:

### 1. `src/systems/EtaSupport.res` line 27
```rescript
Some((Belt.Array.getExn(sorted, 1) +. Belt.Array.getExn(sorted, 2)) /. 2.0)
```
This is in the median calculation for 4 ETA candidates. The `sorted` array has exactly 4 elements (filtered to >0.0), so indices 1 and 2 are always valid ONLY when `Belt.Array.length(values) == 4` (line 25). However, if the sort/filter changes in the future, this is a ticking time bomb.

**Fix:** Replace with `Belt.Array.get(sorted, 1)` pattern-matched with `(Some(a), Some(b)) => ...`

### 2. `src/core/StateSnapshot.res` line 56
```rescript
let snapshot = Belt.Array.getExn(history.contents, i)
```
This is used in a loop `for i in ...`, where `i` is bounded by `Belt.Array.length(history.contents)`. Safe in practice, but violates standards.

**Fix:** Replace with `Belt.Array.get(history.contents, i)->Option.forEach(...)` or use `switch`.

## Acceptance Criteria
- [ ] Zero usages of `getExn` or `getUnsafe` in `src/` (verify with: `grep -rn "getExn\|getUnsafe" src/`)
- [ ] No change in behavior (identical outputs for valid inputs)
- [ ] Builds cleanly

## Files to Modify
- `src/systems/EtaSupport.res` (line 27)
- `src/core/StateSnapshot.res` (line 56)
