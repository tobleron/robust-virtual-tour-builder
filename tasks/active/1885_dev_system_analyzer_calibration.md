# 1885 Dev System Analyzer Calibration

## Objective
Recalibrate `_dev-system` so it favors cohesive Rust and ReScript modules in the `350-450 LOC` band, uses per-language drag targets, and resists generating low-value tiny split recommendations.

## Scope
- `_dev-system/config/efficiency.json`
- `_dev-system/analyzer/src/`
- `_dev-system/README.md`
- `_dev-system/ARCHITECTURE.md`

## Required Changes
- Add per-language drag targets for Rust and ReScript.
- Move the preferred module centerline from `300` to `400`.
- Protect against extracted child modules below `220 LOC`.
- Keep drag as an estimated modification-risk heuristic, not a claim about direct AI capability.
- Sanitize analyzer history so malformed paths and stale noisy failure signals do not distort drag.

## Acceptance Criteria
- [ ] Analyzer config supports language-specific drag targets.
- [ ] Generated task wording uses the `350-450 LOC` working band and `~400 LOC` centerline.
- [ ] Files at or below `450 LOC` are not split purely for size.
- [ ] Split recommendations avoid child-module averages below `220 LOC`.
- [ ] Analyzer history preserves valid file records and drops malformed path entries.
- [ ] `_dev-system/analyzer` tests pass after the calibration changes.

## Verification
- `cargo test -q` in `_dev-system/analyzer`
- `cargo run -q` in `_dev-system/analyzer`

## Notes
- Keep this task in `tasks/active/` until explicit user sign-off.
