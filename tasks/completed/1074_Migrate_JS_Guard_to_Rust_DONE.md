# Task 1074: Migrate JavaScript Project Guard to Rust Analyzer

## Objective
Port the legacy JavaScript logic from `scripts/guard/` into the `_dev-system/analyzer` Rust application. This will consolidate all project governance into a single high-performance engine and ensure features like "Unified Test Tasks" are preserved.

## Logic to Port
### 1. Core Task Engine (`scripts/guard/utils.js`)
- [ ] **Sequential ID Generation**: Implement `get_next_id()` in Rust. Scan `tasks/` recursively for `\d+_` prefixes and return `max + 1`.
- [ ] **Duplicate Prevention**: Implement `task_exists(pattern)` in Rust. Scan `tasks/` (excluding `completed/`) for filename matches.
- [ ] **Unified Task Appending**: Implement `append_to_unified_task(task_name, description)` in Rust.
    - Path: `tasks/pending/tests/*Test_Generation_Unified.md`
    - Logic: If file exists, append ` - [ ] task_name (description)` if not already present.

### 2. Map Consistency Engine (`scripts/guard/check-map.js`)
- [ ] **MAP.md Parsing**: Robustly extract paths from `MAP.md` (Regex: `\ \[.*? \]\[(.*?)\)`).
- [ ] **Unmapped Detection**: Compare disk state (`src/`, `backend/src/`) against `MAP.md`.
- [ ] **Auto-Update**: Append unmapped files to `## 🆕 Unmapped Modules` section in `MAP.md`.
- [ ] **Task Creation**: Create a "Classify New Map Entries" task if unmapped files found.

### 3. Test Gap Engine (`scripts/guard/check-tests.js`)
- [ ] **Pattern Matching**: Map `src/Foo.res` to `tests/unit/Foo_v.test.res`.
- [ ] **Stale Detection**: Compare `mtime` of source vs test.
- [ ] **Implementation Hints**: Port the `getHints(content)` logic (FFmpeg, Pannellum, EventBus, Fetch, DOM hints).
- [ ] **Task Routing**: Use the "Unified Task" engine for new/update test tasks.

## Integration & Cleanup
- [ ] **Main Integration**: Wire these checks into `_dev-system/analyzer/src/main.rs`.
- [ ] **Commit Hook Update**: Update `scripts/commit.sh`, `scripts/fast-commit.sh`, and `scripts/triple-commit.sh` to trigger the Rust analyzer instead of `node scripts/guard/index.js`.
- [ ] **Deprecation**: Delete `scripts/guard/` directory once verification passes.

## Requirements
- Maintain exact filename patterns for tasks.
- Ensure ReScript (`.res`) and Rust (`.rs`) files are both covered.
- Preserved implementaton hints for AI agents.
