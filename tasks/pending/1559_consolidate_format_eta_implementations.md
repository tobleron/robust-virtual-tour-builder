# 1559 — Add Duplicate ETA formatEta Consolidation

## Priority: P2 — Code Quality

## Objective
Consolidate duplicate `formatEta` implementations across the codebase into the canonical `EtaSupport.res` module.

## Context
During codebase review, two separate `formatEta` implementations were found:

1. **`src/systems/EtaSupport.res` (lines 46-62)** — Takes `int` (seconds), formats as "Xh Xm", "Xm Xs", or "Xs".
2. **`src/systems/TeaserOfflineCfrRenderer.res` (lines 44-57)** — Takes `float` (milliseconds), converts to seconds, formats as "ETA Xm Xs" or "ETA Xs" or "Almost done".

These are slightly different (input types, output format), but represent unnecessary duplication. Both should use a single canonical implementation.

## Recommended Approach
1. Enhance `EtaSupport.formatEta` to optionally prepend "ETA " prefix
2. Add `EtaSupport.formatEtaMs(~etaMs: float): string` as a convenience wrapper
3. Replace `TeaserOfflineCfrRenderer.formatEta` with a call to `EtaSupport.formatEtaMs`

## Acceptance Criteria
- [ ] Single `formatEta` implementation exists (in `EtaSupport.res`)
- [ ] `TeaserOfflineCfrRenderer.res` uses `EtaSupport` instead of its own implementation
- [ ] "Almost done" message preserved for ≤0 seconds case
- [ ] Builds cleanly

## Files to Modify
- `src/systems/EtaSupport.res` — add `formatEtaMs` variant
- `src/systems/TeaserOfflineCfrRenderer.res` — remove local `formatEta`, use `EtaSupport`
