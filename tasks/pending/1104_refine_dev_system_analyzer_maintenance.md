# Task: Refine Dev-System Analyzer Maintenance

## Objective
Implement 4 critical refinements to the `_dev-system` analyzer to ensure task accuracy, prevent task pollution, and maintain a high-integrity architectural graph.

## Acceptance Criteria
- [ ] **Idempotent Synchronization**: Modify `main.rs` to replace task sections based on file paths rather than appending strings. If a file is currently healthy (LOC < Limit), any existing surgical task for it should be automatically removed.
- [ ] **Unified Merge Logic**: Consolidate the two separate merge loops (Shallow folder merge and Deep Feature Pod clustering) into a single prioritized pass to eliminate redundant folder recommendations.
- [ ] **Sanity Guard for Entry Points**: Ensure files listed in `entry_points` or tagged with `@efficiency-role: orchestrator` are never flagged as "Unreachable," even if implicit dependency extraction fails.
- [ ] **Task Cleanup**: Clear the `tasks/pending/` directory of stale `Surgical_Refactor` and `Merge_Folders` tasks to reset the baseline after analyzer logic improvements.

## Technical Notes
- **File**: `_dev-system/analyzer/src/main.rs`
- **Location 1**: `sync_architectural_category` function needs to handle multi-line replacement of file-specific entries rather than simple appending.
- **Location 2**: The loops for `recursive_groups` and `dir_stats` should be merged with a clear priority (Complex Feature Pods > Shallow Folder Merges).
- **Location 3**: `find_dead_code` logic in `graph/mod.rs` should explicitly preserve entry points provided via config.
- **Reasoning**: Current task pollution (multiple entries for same file, stale deletion tasks for reachable files) creates high "Read Tax" for AI agents and reduces trust in the analyzer's output.
