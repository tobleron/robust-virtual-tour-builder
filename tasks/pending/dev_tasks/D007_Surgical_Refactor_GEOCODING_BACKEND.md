# Task D007: Surgical Refactor GEOCODING BACKEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 1.80 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.
**Optimal State:** The file becomes a pure 'Orchestrator' or 'Service', with complex math/logic moved to specialized siblings.

### 🎯 Targets (Focus Area)
The Semantic Engine has identified the following specific symbols for refactoring:

## Tasks

### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../backend/src/services/geocoding/cache.rs** (Metric: [Nesting: 2.40, Density: 0.04, Coupling: 0.02] | Drag: 3.87 | LOC: 380/300) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D007/verification.json` (files at `_dev-system/tmp/D007/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D007/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/services/geocoding/cache.rs`
- `backend/src/services/geocoding/cache.rs` (19 functions, fingerprint a64447b3c2614d1b23c46e01888e24c0efcd524c7c479879bc672bc08a5fdf6c)
    - Grouped summary:
        - cache_contains_key × 1 (lines: 313)
        - check_cache × 1 (lines: 245)
        - clear_cache × 1 (lines: 237)
        - decode_cache_payload × 1 (lines: 47)
        - decode_cache_payload_handles_invalid_legacy_cache_shape × 1 (lines: 341)
        - decode_cache_payload_reads_entries_format × 1 (lines: 354)
        - evict_lru_entry × 1 (lines: 112)
        - get_cache_entry_access_count × 1 (lines: 319)
        - get_cache_file_path × 1 (lines: 108)
        - get_cache_len × 1 (lines: 307)
        - get_current_timestamp × 1 (lines: 101)
        - get_evictions_count × 1 (lines: 325)
        - get_hits_count × 1 (lines: 331)
        - get_info × 1 (lines: 140)
        - load_cache_from_disk × 1 (lines: 191)
        - manual_insert × 1 (lines: 289)
        - round_coords × 1 (lines: 94)
        - save_cache_to_disk × 1 (lines: 149)
        - update_cache × 1 (lines: 265)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
