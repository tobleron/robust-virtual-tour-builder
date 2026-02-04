# TASK: _dev-system Analyzer Self-Improvement & Hardening

**Priority**: 🟢 Low (Non-blocking, internal tooling)
**Estimated Effort**: Large (6-8 hours across multiple sessions)
**Dependencies**: None
**Category**: Tooling & Infrastructure

---

## 1. Problem Statement

The `_dev-system` analyzer is a sophisticated AI-native governance engine, but it currently:

1. **Violates its own rules**: `main.rs` is 860 LOC (should be < 400).
2. **Has path normalization bugs**: `analyzer_state.json` contains malformed paths.
3. **Lacks incremental analysis**: Full codebase scan on every run.
4. **Uses hard-coded relative paths**: Non-portable structure.
5. **Has minimal test coverage**: Critical formulas untested.
6. **Uses `unwrap()`/`expect()`**: Flagged as forbidden in its own config.

---

## 2. Improvement Areas

### A. Self-Apply LOC Limits (Refactor `main.rs`) ⭐ HIGH PRIORITY

**Current State**: `main.rs` = 860 LOC

**Target Structure**:
```
analyzer/src/
├── main.rs              # ~100 LOC: Orchestrator only
├── config.rs            # ~80 LOC: Config loading & validation
├── discovery.rs         # ~150 LOC: File scanning & registry building
├── analysis.rs          # ~150 LOC: Drag, Limit, Hotspot calculation
├── task_generator.rs    # ~200 LOC: WorkUnit synthesis
├── merger.rs            # ~100 LOC: Merge candidate detection
├── flusher.rs           # ~80 LOC: Plan file output
├── drivers/             # (unchanged)
├── graph/               # (unchanged)
├── state.rs             # (unchanged)
├── resolver.rs          # (unchanged)
└── guard.rs             # (unchanged)
```

**Extraction Checklist**:
- [ ] Extract `EfficiencyConfig`, `Settings`, `Templates` structs to `config.rs`
- [ ] Extract Phase 1 (Discovery & Analysis) to `discovery.rs`
- [ ] Extract `calculate_dynamic_limit`, drag formulas to `analysis.rs`
- [ ] Extract `sync_all_architectural_tasks`, `WorkUnit` generation to `task_generator.rs`
- [ ] Extract recursive cluster detection to `merger.rs`
- [ ] Extract `flush_plans` to `flusher.rs`
- [ ] `main.rs` becomes pure orchestrator calling phases in sequence

### B. Fix Path Normalization 🟡 MEDIUM PRIORITY

**Issue**: Paths stored with `..` segments, causing duplicates:
```json
"backend/src/auth/../../backend/src/auth/service.rs"
```

**Fix**: Canonicalize paths at registry entry:
```rust
use std::path::Path;

fn normalize_path(p: &str) -> String {
    let path = Path::new(p);
    if let Ok(canonical) = path.canonicalize() {
        // Strip project root prefix if present
        canonical.to_string_lossy().to_string()
    } else {
        // Fallback: manual cleanup
        p.replace("/../", "/").replace("/..", "")
    }
}
```

**Also**:
- Add validation to reject non-path strings in `analyzer_state.json`
- Clean existing `analyzer_state.json` of malformed entries

### C. Add Test Coverage 🟡 MEDIUM PRIORITY

**Missing Tests**:
1. **Drag Formula** - Verify `(1.0 + nesting*0.5 + density*1.2 + state*6.0) * penalty`
2. **Dynamic Limit** - Test various taxonomy/drag combinations
3. **Hysteresis** - Ensure 15% buffer prevents split-merge loops
4. **Shadow Protection** - Verify orchestrator+folder detection
5. **Path Normalization** - Edge cases with `..` and symlinks

**Test File**: `_dev-system/analyzer/tests/formula_tests.rs`

```rust
#[test]
fn test_drag_formula_basic() {
    let drag = calculate_drag(0, 0.5, 0.0, 0, 1.0);
    assert!((drag - 1.0).abs() < 0.01);
}

#[test]
fn test_dynamic_limit_high_state() {
    // High state count should severely limit LOC
    let limit = calculate_dynamic_limit(5.0, 0.5, 1.0, 400.0, ...);
    assert!(limit < 200);
}

#[test]
fn test_hysteresis_prevents_split_merge_loop() {
    // File at limit * 1.10 should NOT trigger split
    let loc = 440;
    let limit = 400;
    let split_threshold = (limit as f64 * 1.15) as usize;
    assert!(loc < split_threshold); // Should not split
}
```

### D. Eliminate `unwrap()` / `expect()` in Analyzer 🟢 LOW PRIORITY

**Current Usage**:
- `rescript.rs:250` - `expect("Scope stack should never be empty")`
- `main.rs` - Various `unwrap()` calls

**Fix**: Replace with proper error propagation:
```rust
// Before
let scope = self.scope_stack.last_mut().expect("...");

// After
let scope = self.scope_stack.last_mut().ok_or_else(|| anyhow!("Empty scope stack"))?;
```

### E. Incremental Analysis Mode 🟢 LOW PRIORITY (Future)

**Concept**: Only re-analyze files changed since last run.

**Implementation**:
1. Store `file_mtime_hash` in `analyzer_state.json`
2. On scan, compare modification times
3. Skip unchanged files (use cached metrics)
4. Re-run graph analysis if any file changed

**Benefit**: 10x faster for large codebases with minimal changes.

### F. Make Paths Configurable 🟢 LOW PRIORITY

**Current**: Hard-coded `../../tasks/pending`, `../plans/`, etc.

**Fix**: Add to `efficiency.json`:
```json
{
  "paths": {
    "tasks_pending": "./tasks/pending",
    "tasks_active": "./tasks/active",
    "plans_output": "./_dev-system/plans",
    "analyzer_state": "./_dev-system/analyzer_state.json"
  }
}
```

### G. ID Collision Hardening 🟡 MEDIUM PRIORITY

**Issue**: Race conditions between manual task creation and automated governor scans lead to duplicate task IDs (e.g., two tasks numbered 1218).

**Fix**:
1. **Centralize**: Move all ID logic to `guard::acquire_next_id`.
2. **Double-Check**: Ensure `acquire_next_id` scans for the highest ID *immediately* before file creation.
3. **Atomic Write**: Use a hidden state file `.next_id` in the `tasks/` directory as a secondary lock.
4. **Collision Detection**: If `id_NNN_*.md` already exists, skip `NNN` and find the next hole.

---

## 3. Verification Criteria

- [ ] `main.rs` is < 200 LOC after refactoring.
- [ ] `cargo build --release` completes with zero warnings.
- [ ] `cargo test` passes with > 80% formula coverage.
- [ ] No `unwrap()` or raw `panic!` in production code paths.
- [ ] `analyzer_state.json` contains only valid, normalized paths.
- [ ] Analyzer can run from project root with path overrides.
- [ ] **Collisions**: Manual creation of `tasks/pending/999_TEST.md` followed by analyzer run correctly generates an ID of `1000`.

---

## 4. File Checklist

- [ ] `_dev-system/analyzer/src/main.rs` - Slim to orchestrator
- [ ] `_dev-system/analyzer/src/config.rs` - New file
- [ ] `_dev-system/analyzer/src/discovery.rs` - New file
- [ ] `_dev-system/analyzer/src/analysis.rs` - New file
- [ ] `_dev-system/analyzer/src/task_generator.rs` - New file
- [ ] `_dev-system/analyzer/src/merger.rs` - New file
- [ ] `_dev-system/analyzer/src/flusher.rs` - New file
- [ ] `_dev-system/analyzer/tests/formula_tests.rs` - New file
- [ ] `_dev-system/config/efficiency.json` - Add paths config
- [ ] `_dev-system/analyzer_state.json` - Clean malformed entries
- [ ] `_dev-system/README.md` - Update with new structure

---

## 5. Incremental Approach

**Phase 1** (2h): Extract config, discovery, analysis
**Phase 2** (2h): Extract task_generator, merger, flusher
**Phase 3** (1h): Fix path normalization
**Phase 4** (2h): Add test coverage
**Phase 5** (1h): Eliminate unwrap, cleanup

---

## 6. References

- `_dev-system/analyzer/src/main.rs` (current monolith)
- `_dev-system/README.md` (design philosophy)
- `_dev-system/ARCHITECTURE.md` (system overview)
- `_dev-system/config/efficiency.json` (config schema)
