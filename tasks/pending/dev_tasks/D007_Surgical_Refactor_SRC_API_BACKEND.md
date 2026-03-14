# Task D007: Surgical Refactor SRC API BACKEND

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

- [ ] - **../../backend/src/api/portal.rs** (Metric: [Nesting: 2.40, Density: 0.02, Coupling: 0.02] | Drag: 3.47 | LOC: 690/300  ⚠️ Trigger: Drag above target (1.80); keep the module within the 250-350 LOC working band if you extract helpers.) → 🏗️ Split into 2 modules (target 250-350 LOC each, center ~300 LOC)

- [ ] - **../../backend/src/api/project_snapshot.rs** (Metric: [Nesting: 2.40, Density: 0.02, Coupling: 0.02] | Drag: 3.46 | LOC: 433/300  ⚠️ Trigger: Drag above target (1.80); keep the module within the 250-350 LOC working band if you extract helpers.) → Refactor in-place (keep near ~300 LOC)


### 🔧 Action: De-bloat
**Directive:** Right-size Surface: Keep the module as the orchestration boundary and extract only adjacent sections that reduce file length without fragmenting the public API.

- [ ] - **../../backend/src/api/config_routes.rs** (Metric: [Nesting: 0.60, Density: 0.00, Coupling: 0.01] | Drag: 1.60 | LOC: 665/392  ⚠️ Trigger: Oversized beyond the preferred 250-350 LOC working band.) → 🏗️ Split into 2 modules (target 250-350 LOC each, center ~300 LOC) [Size-only candidate; drag already within target.]


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D007_Surgical_Refactor_SRC_API_BACKEND/verification.json` (files at `_dev-system/tmp/D007_Surgical_Refactor_SRC_API_BACKEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D007_Surgical_Refactor_SRC_API_BACKEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/api/portal.rs`
- `backend/src/api/portal.rs` (34 functions, fingerprint 9e43f91ac94ab86ba5df1da0b68b957c8d641113da8ab4915101e2e8a78f3391)
    - Grouped summary:
        - access_link_redirect × 1 (lines: 493)
        - access_tour_redirect × 1 (lines: 567)
        - admin_assign_customer_tour × 1 (lines: 282)
        - admin_create_customer × 1 (lines: 186)
        - admin_delete_access_links × 1 (lines: 352)
        - admin_delete_customer × 1 (lines: 368)
        - admin_delete_library_tour × 1 (lines: 378)
        - admin_get_settings × 1 (lines: 220)
        - admin_list_customers × 1 (lines: 177)
        - admin_list_library_tours × 1 (lines: 240)
        - admin_regenerate_access_link × 1 (lines: 318)
        - admin_revoke_access_links × 1 (lines: 336)
        - admin_unassign_customer_tour × 1 (lines: 300)
        - admin_update_customer × 1 (lines: 202)
        - admin_update_library_tour_status × 1 (lines: 265)
        - admin_update_settings × 1 (lines: 229)
        - admin_upload_library_tour × 1 (lines: 249)
        - current_portal_session × 1 (lines: 99)
        - customer_public × 1 (lines: 388)
        - customer_session × 1 (lines: 396)
        - customer_sign_out × 1 (lines: 413)
        - customer_tour_asset × 1 (lines: 477)
        - customer_tour_launch × 1 (lines: 437)
        - customer_tours × 1 (lines: 419)
        - ensure_slug_matches_session × 1 (lines: 111)
        - normalized_requested_slug × 1 (lines: 159)
        - portal_public_base_url × 1 (lines: 121)
        - read_portal_zip_upload × 1 (lines: 641)
        - require_portal_admin × 1 (lines: 83)
        - safe_next_path × 1 (lines: 131)
        - safe_tour_path × 1 (lines: 151)
        - store_portal_session × 1 (lines: 163)
        - user_access_redirect × 1 (lines: 538)
        - user_tour_access_redirect × 1 (lines: 612)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `backend/src/api/project_snapshot.rs`
- `backend/src/api/project_snapshot.rs` (20 functions, fingerprint 2c82a577e88062e7dc2e04e281028bf340c4ef4551159aa0d40b18f3eb48cfa2)
    - Grouped summary:
        - count_hotspots × 1 (lines: 69)
        - default_snapshot_origin × 1 (lines: 14)
        - list_project_snapshots × 1 (lines: 352)
        - load_project_snapshot × 1 (lines: 373)
        - load_snapshot_history × 1 (lines: 128)
        - load_snapshot_history_files × 1 (lines: 138)
        - persist_snapshot_history × 1 (lines: 173)
        - persist_snapshot_history_upgrades_auto_origin_for_identical_manual_save × 1 (lines: 229)
        - project_tour_name × 1 (lines: 96)
        - prune_snapshot_history × 1 (lines: 164)
        - read_snapshot × 1 (lines: 268)
        - resolve_snapshot_path × 1 (lines: 275)
        - restore_project_snapshot × 1 (lines: 406)
        - scene_count × 1 (lines: 88)
        - snapshot_content_hash × 1 (lines: 108)
        - snapshot_history_dir × 1 (lines: 104)
        - snapshot_item_from_envelope × 1 (lines: 254)
        - sync_snapshot × 1 (lines: 316)
        - validate_snapshot_project × 1 (lines: 297)
        - write_current_snapshot × 1 (lines: 117)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `backend/src/api/config_routes.rs`
- `backend/src/api/config_routes.rs` (3 functions, fingerprint b90713ffb2446f9c0b1751ab2a6dfe0aa73393d9ae43f5c6b6d1d29d4d6332df)
    - Grouped summary:
        - configure_api × 2 (lines: 14, 508)
        - configure_portal_api × 1 (lines: 510)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
