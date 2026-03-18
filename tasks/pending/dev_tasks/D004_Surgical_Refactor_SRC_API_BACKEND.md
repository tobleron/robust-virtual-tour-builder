# Task D004: Surgical Refactor SRC API BACKEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** Reduce estimated modification risk below the applicable drag target without fragmenting cohesive modules.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules only when the resulting split stays within the preferred size policy.
**Optimal State:** The file remains a clear 'Orchestrator' or 'Service' boundary, with only truly dense or isolated logic moved to specialized siblings.

### 🎯 Targets (Focus Area)
The Semantic Engine has identified the following specific symbols for refactoring:

## Tasks

### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../backend/src/api/portal.rs** (Metric: [Nesting: 2.40, Density: 0.02, Coupling: 0.01] | Drag: 3.46 | LOC: 874/400  ⚠️ Trigger: Oversized beyond the preferred 350-450 LOC working band.) → 🏗️ Split into 2 modules (target 350-450 LOC each, center ~400 LOC, floor 220 LOC)


### 🔧 Action: De-bloat
**Directive:** Right-size Surface: Keep the module as the orchestration boundary and extract only adjacent sections that reduce file length without fragmenting the public API.

- [ ] - **../../backend/src/api/config_routes.rs** (Metric: [Nesting: 0.60, Density: 0.00, Coupling: 0.01] | Drag: 1.60 | LOC: 735/400  ⚠️ Trigger: Oversized beyond the preferred 350-450 LOC working band.) → 🏗️ Split into 2 modules (target 350-450 LOC each, center ~400 LOC, floor 220 LOC) [Size-only candidate; drag already within target.]


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D004_Surgical_Refactor_SRC_API_BACKEND/verification.json` (files at `_dev-system/tmp/D004_Surgical_Refactor_SRC_API_BACKEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D004_Surgical_Refactor_SRC_API_BACKEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/api/portal.rs`
- `backend/src/api/portal.rs` (43 functions, fingerprint 3a5d936a41daa56f8162d3588e4a9a40efd3e5e30b95946d36a2f6fc0dc3dc40)
    - Grouped summary:
        - access_link_redirect × 1 (lines: 665)
        - access_tour_redirect × 1 (lines: 744)
        - admin_assign_customer_tour × 1 (lines: 435)
        - admin_bulk_assign_tours × 1 (lines: 471)
        - admin_create_customer × 1 (lines: 223)
        - admin_create_customer_tour_link × 1 (lines: 364)
        - admin_delete_access_links × 1 (lines: 517)
        - admin_delete_customer × 1 (lines: 533)
        - admin_delete_library_tour × 1 (lines: 543)
        - admin_get_assignment × 1 (lines: 349)
        - admin_get_customer_tours × 1 (lines: 319)
        - admin_get_settings × 1 (lines: 257)
        - admin_get_tour_recipients × 1 (lines: 334)
        - admin_list_customers × 1 (lines: 214)
        - admin_list_library_tours × 1 (lines: 277)
        - admin_reactivate_assignment_link × 1 (lines: 419)
        - admin_regenerate_access_link × 1 (lines: 483)
        - admin_revoke_access_links × 1 (lines: 501)
        - admin_revoke_assignment_link × 1 (lines: 383)
        - admin_unassign_customer_tour × 1 (lines: 453)
        - admin_update_assignment_expiry × 1 (lines: 401)
        - admin_update_customer × 1 (lines: 239)
        - admin_update_library_tour_status × 1 (lines: 302)
        - admin_update_settings × 1 (lines: 266)
        - admin_upload_library_tour × 1 (lines: 286)
        - current_portal_session × 1 (lines: 112)
        - customer_public × 1 (lines: 553)
        - customer_session × 1 (lines: 561)
        - customer_sign_out × 1 (lines: 582)
        - customer_tour_asset × 1 (lines: 648)
        - customer_tour_launch × 1 (lines: 607)
        - customer_tours × 1 (lines: 589)
        - ensure_gallery_session × 1 (lines: 138)
        - ensure_slug_matches_session × 1 (lines: 128)
        - normalized_requested_slug × 1 (lines: 186)
        - portal_public_base_url × 1 (lines: 148)
        - read_portal_zip_upload × 1 (lines: 825)
        - require_portal_admin × 1 (lines: 96)
        - safe_next_path × 1 (lines: 158)
        - safe_tour_path × 1 (lines: 178)
        - store_portal_session × 1 (lines: 190)
        - user_access_redirect × 1 (lines: 711)
        - user_tour_access_redirect × 1 (lines: 789)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `backend/src/api/config_routes.rs`
- `backend/src/api/config_routes.rs` (3 functions, fingerprint b90713ffb2446f9c0b1751ab2a6dfe0aa73393d9ae43f5c6b6d1d29d4d6332df)
    - Grouped summary:
        - configure_api × 2 (lines: 14, 543)
        - configure_portal_api × 1 (lines: 545)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
