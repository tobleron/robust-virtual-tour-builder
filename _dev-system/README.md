# `_dev-system`

`_dev-system` is the repository's analyzer for advisory refactors, merge suggestions, and architecture notes.

It does three things:

1. Scans the repo using the rules in `_dev-system/config/efficiency.json`
2. Measures file risk using drag, role, LOC, and recent history
3. Writes guidance into `tasks/pending/dev_tasks/`

## What Drag Means

Drag is an estimated modification-risk score.

It is **not** a measurement of AI model intelligence or capability. It is only a practical signal for when a file is likely to be annoying or unsafe to edit in one pass.

Current configuration uses:

- `base_loc_limit = 400`
- `soft_floor_loc = 400`
- `hard_ceiling_loc = 800`
- `min_extracted_module_loc = 220`
- `drag_target = 2.2` fallback
- `drag_target = 2.4` for ReScript
- `drag_target = 2.6` for Rust

## How It Works

```text
Codebase
  -> semantic scan
  -> role inference
  -> drag calculation
  -> dynamic LOC limit
  -> task synthesis
  -> tasks/pending/dev_tasks/
```

## Analyzer Outputs

- `Surgical Refactor` tasks for risky large modules
- `Merge Folders` tasks for fragmented sibling modules
- `Violation Fix` tasks for forbidden patterns
- `Ambiguity Resolution` tasks for unclear file roles
- `Structural Refactor` tasks for path-depth cleanup

## Configuration

The main config file is:

- [`config/efficiency.json`](config/efficiency.json)

The analyzer also keeps runtime state in:

- [`analyzer_state.json`](analyzer_state.json)

## Practical Use

1. Read `MAP.md` and `DATA_FLOW.md` first.
2. Run the analyzer.
3. Open the generated dev task.
4. Make the smallest coherent change.
5. Re-run build and analyzer checks.

## Notes

- The analyzer is intentionally conservative.
- Cohesive modules can stay larger than tiny helper fragments.
- Recent failure history is bounded so one bad run does not dominate the output.
