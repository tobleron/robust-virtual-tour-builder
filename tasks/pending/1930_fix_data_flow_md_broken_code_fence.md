# 1930 — Fix DATA_FLOW.md Broken Code Fence Structure

**Priority:** 🟠 P1  
**Effort:** 10 minutes  
**Origin:** Codebase Analysis 2026-03-22

## Context

Lines 343–367 in `DATA_FLOW.md` have a broken code fence structure. Two lines about `shutdown.rs` and `metrics.rs` are orphaned between two code fences — they belong to the "Infrastructure, Metadata & Quota" flow section but appear after the CI Budget Governance section's closing fence.

## Scope

### Current (Broken)

```markdown
  → [backend/src/api/health.rs] provides service diagnostics    ← End of Infra section (missing)

### CI Budget Governance
...
```                                                               ← CI section closes here
  → [backend/src/services/shutdown.rs] graceful exit             ← ORPHANED
  → [backend/src/metrics.rs] processes performance metrics       ← ORPHANED
```                                                               ← STRAY closing fence
```

### Fix

Move lines 365–366 (`shutdown.rs` and `metrics.rs`) back into the Infrastructure code block, before the closing fence on line 343. Remove the stray closing fence on line 367.

### Steps

1. Open `DATA_FLOW.md`
2. Move the `shutdown.rs` and `metrics.rs` lines to after line 343 (inside the Infrastructure code block)
3. Delete the stray closing ``` on line 367
4. Verify the document renders correctly in a markdown preview

## Acceptance Criteria

- [ ] All code fence blocks in DATA_FLOW.md are properly opened and closed
- [ ] `shutdown.rs` and `metrics.rs` are inside the Infrastructure section's code block
- [ ] No stray closing fences exist
