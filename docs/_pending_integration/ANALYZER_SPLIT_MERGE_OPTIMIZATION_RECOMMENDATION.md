# _dev-system Analyzer Split/Merge Optimization Recommendation

## Status
- Date: March 9, 2026
- Scope: `_dev-system/analyzer` split and merge calibration for AI-agent coding
- Goal: Reduce harmful file hopping without allowing modules to become large enough to waste context or increase edit-truncation risk.

## Executive Recommendation
- Keep `soft_floor_loc = 300` for now.
- Do **not** raise the floor to `350` yet.
- First, make split detection a true size-and-complexity policy instead of a mostly LOC-only policy.
- After that logic change lands, re-evaluate a floor increase to `325` or `350`.
- Leave merge configuration unchanged for now.

## Why This Is The Best Next Step

### 1. Current split detection is not truly complexity-aware
The current analyzer emits surgical tasks when file size exceeds the dynamic limit in `src/main.rs`, and the split gate is effectively:

```rust
if taxonomy != "unknown" && metrics.loc > limit {
    let split_threshold = (limit as f64 * 1.25) as usize;
    if metrics.loc > split_threshold {
        // emit surgical task
    }
}
```

Relevant code:
- `_dev-system/analyzer/src/main.rs`
- `_dev-system/analyzer/src/analysis.rs`

`drag_target = 1.8` is currently used for task wording and classification of size-only candidates, but it is **not** used to decide whether a file becomes a surgical task.

Consequence:
- Raising `soft_floor_loc` now would reduce task count, but mainly by hiding medium-sized high-drag files instead of solving the underlying calibration problem.

### 2. The current `300` floor is conservative, but it is protecting useful signals
Observed current repo behavior:
- Current surgical candidates: `31`
- Current total recommended splits: `74`

Modeled impact of changing only the floor:

| soft floor | active surgical candidates | total recommended splits |
|---|---:|---:|
| 250 | 31 | 80 |
| 275 | 31 | 77 |
| 300 | 31 | 74 |
| 325 | 21 | 51 |
| 350 | 16 | 39 |
| 400 | 9 | 24 |

The important inflection is between `300` and `350`:
- `325` already suppresses several legitimate ~400 LOC complexity-bearing files.
- `350` suppresses too many of them.
- `400` is clearly too lax for AI-agent editing in this repo.

### 3. Raising the floor now would remove useful protections
At `350`, the analyzer would stop flagging several files that are still realistically hard for AI agents to edit safely in one pass, including examples such as:
- `src/App.res`
- `src/components/PreviewArrow.res`
- `src/systems/OperationLifecycle.res`
- `src/systems/Simulation.res`
- `src/utils/Retry.res`

This is not because those files became safer. It happens because the detector is still mostly size-driven.

### 4. Merge logic is already appropriately conservative
Current merge output is sparse and safe:
- one current merge candidate
- guarded by projected-limit checks, subtree overlap checks, and recursive-cluster hysteresis

This is desirable for AI-agent workflows because over-merging causes context inflation and broader accidental edit radius.

Recommendation:
- keep `merge_score_threshold = 1.2`
- keep `hard_ceiling_loc = 800`
- do not tune merge until split logic is improved

## Scientific Framing For AI-Agent Editing

### Context-window reality
Approximate code-token ranges by LOC:
- `250 LOC` ~= `2500-3500` tokens
- `300 LOC` ~= `3000-4200` tokens
- `350 LOC` ~= `3500-4900` tokens
- `400 LOC` ~= `4000-5600` tokens
- `500 LOC` ~= `5000-7000` tokens
- `600 LOC` ~= `6000-8400` tokens

For agentic coding, the true cost is not just reading one file. The agent often also needs:
- at least one dependency/provider file
- at least one consumer/caller file
- nearby tests
- task context and error output

That means:
- `250` is usually safe but increases file hopping.
- `300` is a cautious default.
- `350` can be safe for low-drag orchestration modules.
- `400+` becomes risky unless the file is very shallow and stable.

### Best steady-state policy
The best long-term policy is **not** one global number.

For AI-agent work, the ideal steady state is:
- low-drag orchestrators/adapters: `350-450 LOC`
- high-drag logic modules: `250-300 LOC`
- merge only when the unified context remains comfortably below the hard ceiling and does not enlarge the edit radius too much

The current analyzer cannot fully express that policy yet.

## Recommended Optimization Plan

### Phase 1. Logic-first improvement
Add a secondary drag-based surgical trigger in `_dev-system/analyzer/src/main.rs`.

Target behavior:
- emit a surgical task when a file is very large relative to its limit, **or**
- emit a surgical task when drag is above `drag_target` and file size is still materially large

Recommended gate:
- keep the existing LOC-based trigger
- add a second trigger similar to:
  - `drag > drag_target`
  - and `metrics.loc >= 250`

Reason:
- this makes split detection genuinely size-and-complexity aware
- it preserves signal for hard medium-sized files before any floor increase

### Phase 2. Re-evaluate floor after the drag gate exists
Once the drag-based trigger is in place:
- test `soft_floor_loc = 325`
- then test `soft_floor_loc = 350`

Expected result:
- low-drag orchestrators and adapter facades can become less aggressively split
- high-drag files still remain flagged because of the drag gate

### Phase 3. Optional role-aware refinement
If further optimization is needed, prefer one of these over a large global floor increase:
- role-specific soft floors
- role-specific drag triggers
- a separate orchestration exception lane for shallow files with low drag and low hotspot density

This is better than pushing the whole repo toward `350+` indiscriminately.

## Concrete Recommendation To Apply Now

### Apply now
- Keep:
  - `soft_floor_loc = 300`
  - `merge_score_threshold = 1.2`
  - `hard_ceiling_loc = 800`
- Implement:
  - drag-based secondary surgical trigger

### Do not apply yet
- Do not raise `soft_floor_loc` to `350` before the drag trigger exists.
- Do not loosen merge policy yet.

## Expected Impact

If only the drag-based trigger is added:
- current large-file surgical queue should remain mostly stable
- some medium-sized but high-drag files may newly surface
- the queue becomes more scientifically aligned with AI-agent editing risk

If the floor is raised later to `325` or `350` after the drag trigger:
- total split count should fall
- file hopping should reduce
- low-drag orchestrator churn should decline
- complexity-heavy files should still stay visible

## Final Conclusion
For the analyzer as currently implemented, `300` is the best operating point.

It is not the best universal AI-agent module size in theory, but it is the best **current proxy** because the split detector is still mostly LOC-driven. The correct optimization path is:

1. make split detection genuinely drag-aware,
2. then raise the floor carefully,
3. leave merge unchanged until the split side is calibrated.
