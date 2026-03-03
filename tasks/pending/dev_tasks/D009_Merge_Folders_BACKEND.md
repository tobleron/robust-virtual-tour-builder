# Task D009: Merge Folders BACKEND

## Objective
## 🧩 Merge Objective
**Role:** Architecture Cleanup Bot
**Goal:** Reduce File Fragmentation (Read Tax).
**Constraint:** Combined file must not exceed 800 LOC.
**Optimal State:** Related small modules are unified into a single context window, reducing token consumption.

## Tasks

### 🔧 Action: Merge Fragmented Folders
**Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module file (e.g., `geocoding.res`). CRITICAL: Delete the now-empty `backend/src/services/geocoding/` folder to reduce directory nesting tax and strip any existing '@efficiency' tags.

- [ ] Folder: `backend/src/services/geocoding` (Metric: Recursive Feature Pod: 2 files in subtree sum to 180 LOC (fits in context). Max Drag: 4.14)
    - `backend/src/services/geocoding/../../backend/src/services/geocoding/mod.rs`
    - `backend/src/services/geocoding/../../backend/src/services/geocoding/osm.rs`

## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D009/verification.json` (files at `_dev-system/tmp/D009/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D009/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-merge snapshots for recursive cluster `backend/src/services/geocoding`
- `backend/src/services/geocoding/osm.rs` (2 functions, fingerprint d3cbc084dc46f9e912bfd53d3335e6af69325a63ebd50569374016ef71326bf0)
    - Grouped summary:
        - call_osm_nominatim × 1 (lines: 40)
        - format_address_from_json × 1 (lines: 2)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
- `backend/src/services/geocoding/mod.rs` (6 functions, fingerprint 7aa26080b2fea105c2f710bf3f41ec9c7fd190b46d564bfe9479c1e87f0e8e0a)
    - Grouped summary:
        - reverse_geocode × 1 (lines: 11)
        - test_clear_cache_internal × 1 (lines: 91)
        - test_coordinate_rounding_internal × 1 (lines: 83)
        - test_geocoder_suite_sequential × 1 (lines: 34)
        - test_lru_eviction_internal × 1 (lines: 61)
        - test_reverse_geocode_with_cache_internal × 1 (lines: 44)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
