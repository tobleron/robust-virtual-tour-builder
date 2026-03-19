# Project Dev System (`_dev-system`)

The `_dev-system` is the repo's advisory analyzer. It scans the codebase, measures modification risk, and writes guidance tasks when a file looks too risky to edit safely in one pass.

## What It Does

- Scans the configured roots in `_dev-system/config/efficiency.json`
- Measures LOC, nesting, density, role, and recent failure history
- Calculates a dynamic LOC limit per file
- Generates advisory tasks in `tasks/pending/dev_tasks/`
- Keeps analyzer state in `_dev-system/analyzer_state.json`

## Current Configuration

| Setting | Current Value | Meaning |
|---|---:|---|
| `base_loc_limit` | `400` | Default centerline for cohesive modules |
| `soft_floor_loc` | `400` | Preferred working band center |
| `hard_ceiling_loc` | `800` | Absolute upper bound |
| `min_extracted_module_loc` | `220` | Minimum useful extracted child module size |
| `drag_target` | `2.2` | Global fallback drag target |
| `drag_target` for ReScript | `2.4` | Language-specific target |
| `drag_target` for Rust | `2.6` | Language-specific target |
| `merge_score_threshold` | `1.2` | Merge-task sensitivity |
| `hysteresis` | `1.15 / 0.85` | Split/move buffer to avoid flip-flopping |

## How The Analyzer Thinks

```text
Code change
  -> scan files
  -> infer role + measure drag
  -> compare against dynamic limit
  -> emit task if the file is meaningfully over target
  -> write task into tasks/pending/dev_tasks/
```

### Drag

Drag is a heuristic, not a direct measure of AI capability. It is a modification-risk score built from:

- nesting depth
- logic density
- state density
- directory depth
- recent failure history

Higher drag means the analyzer is more cautious about recommending direct edits.

### Dynamic Limit

The analyzer does not use one static LOC limit for everything. It adjusts the limit with:

- the base size policy
- the file's taxonomy role
- the cohesion bonus
- the current drag score

For cohesive Rust and ReScript modules, the preferred band is `350-450 LOC`, with `400 LOC` as the centerline.

## Task Types

- `Surgical Refactor`: split or simplify a risky module
- `Merge Folders`: combine fragmented sibling modules when that reduces read tax
- `Violation Fix`: remove a forbidden pattern
- `Ambiguity Resolution`: assign a clear architectural role
- `Structural Refactor`: flatten deep path hierarchies when needed

## Workflow

1. Run `./scripts/dev-system.sh` or the analyzer directly.
2. Review `MAP.md` and `DATA_FLOW.md` first for context.
3. Open the generated dev task in `tasks/pending/dev_tasks/`.
4. Make the smallest safe architectural change.
5. Re-run `npm run build` and the analyzer to confirm the task disappears or changes.

## Reading The Output

- A task is advisory guidance, not a blocking project task.
- The analyzer is conservative on purpose.
- If a file is already cohesive and near the preferred band, the analyzer should prefer keeping it intact.
- If a file is both large and dense, it should get a stronger split suggestion.

## One-Line Summary

The `_dev-system` is a guardrail that keeps the repo readable and editable for both humans and AI agents.
