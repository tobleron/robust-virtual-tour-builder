# T1817 Troubleshoot Dev-System Task Generator

- Assignee: Codex
- Objective: Fix `_dev-system/analyzer` so generated dev tasks are ordered by real execution dependencies and invalid tasks are not emitted.
- Boundary: `_dev-system/analyzer/` plus tests and generated analyzer fixtures only; no product feature changes.

## Hypothesis (Ordered Expected Solutions)
- [x] Task ordering is currently too coarse because the generator sorts mostly by task kind and filename, not by a richer dependency/validity score derived from touched paths and consumer/provider relationships.
- [x] Invalid structural or dead-code tasks are being emitted because JS/HTML dependency discovery is missing import edges, causing reachable files such as `src/site/PageFramework.js` to be treated as unreachable.
- [x] Invalid merge tasks are being emitted because merge candidate detection does not reject empty/root-level folders or semantically unrelated file clusters before task synthesis.
- [x] The task writer lacks a final validation gate to suppress malformed task specs even when earlier phases mis-detect candidates.

## Activity Log
- [x] Inspect analyzer task-generation, merge-detection, and dependency-discovery code paths.
- [x] Reproduce the bad ordering and invalid-task output locally.
- [x] Patch dependency discovery and/or dead-code detection for JS imports.
- [x] Patch merge/task-spec validation and ordering heuristics.
- [x] Patch split detection so medium-sized high-drag modules can surface without lowering the global soft floor.
- [x] Narrow the drag-aware split trigger so protected entrypoints, data/umbrella modules, and CSS do not flood the queue with low-signal surgical work.
- [x] Add or update tests covering stale dead-code detection, invalid merge suppression, and stable task ordering.
- [x] Run analyzer tests and a real analyzer pass to verify task output.

## Code Change Ledger
- [x] `_dev-system/analyzer/src/drivers/html.rs`: replaced line-local import parsing with multiline-aware import collection plus regex extraction for `import ... from`, side-effect imports, and `require(...)`; added regression test for `PageFramework.js` style imports.
- [x] `_dev-system/analyzer/src/merger.rs`: added merge-scope validity guards to reject empty scopes, scanned-root scopes, and shallow/root-level cluster targets; added unit test coverage.
- [x] `_dev-system/analyzer/src/task_generator.rs`: added final generated-task validation, attached dependency-graph-based task ordering on top of existing overlap ordering, and added tests for consumer-after-provider ordering plus invalid merge suppression.
- [x] `_dev-system/analyzer/src/task_generator.rs`: fixed surgical-task key collisions for same-basename folders (for example `css/components` vs `src/components`) so generated tasks no longer overwrite each other; added regression test.
- [x] `_dev-system/analyzer/src/task_generator.rs`: distinguished size-only surgical candidates from real drag hotspots in task wording, so files like `backend/src/api/mod.rs` are now labeled as right-sizing work instead of false complexity hotspots; added regression tests.
- [x] `_dev-system/analyzer/src/main.rs`: added a secondary drag-aware surgical trigger guarded by minimum LOC so medium-sized high-drag modules now surface without raising `soft_floor_loc`; added regression tests for oversized, drag-risk, and ignored-small-file behavior.
- [x] `_dev-system/analyzer/src/main.rs`: narrowed drag-risk emission with exemptions for protected/max-loc files, `data-model` surfaces, `mod.rs`/`models.rs`, and CSS, plus stronger under-limit thresholds for non-hotspot files; added regression tests for protected entrypoints, CSS, and umbrella/data modules.
- [x] `_dev-system/analyzer/src/main.rs`: passed the built dependency graph into task synchronization so ordering uses real file dependencies.
- [x] `docs/_pending_integration/v5.2.0_Logical_Review_Report.md`: moved the historical D014 review note out of `tasks/pending/dev_tasks/` so generated queue numbering stays clean.
- [x] `docs/_pending_integration/ANALYZER_SPLIT_MERGE_OPTIMIZATION_RECOMMENDATION.md`: documented the recommended next optimization path for AI-agent-oriented split/merge calibration, including why `soft_floor_loc` should stay at 300 until split detection becomes truly drag-aware.

## Rollback Check
- [x] Confirmed CLEAN (tests pass and regenerated analyzer output removed the bad `PageFramework` dead-code task, removed the invalid empty-scope merge task, and compacted the dev-task numbering after moving the historical note).

## Context Handoff
The analyzer now recognizes multiline JS imports, so `src/site/PageFramework.js` remains only as an ambiguity/classification item instead of a false dead-code task. Generated merge tasks reject empty or root-level scopes, key collisions between same-basename folders are gone, task ordering incorporates actual file dependency edges, and split detection can now surface medium-sized high-drag modules without lowering the global `soft_floor_loc` while still exempting protected entrypoints, data/umbrella surfaces, and CSS noise. The remaining improvement area is task granularity and naming polish, but the queue is materially closer to a stable AI-agent execution plan now.
