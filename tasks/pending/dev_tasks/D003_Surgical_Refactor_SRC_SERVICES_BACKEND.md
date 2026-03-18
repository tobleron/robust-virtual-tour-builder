# Task D003: Surgical Refactor SRC SERVICES BACKEND

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

- [ ] - **../../backend/src/services/portal.rs** (Metric: [Nesting: 3.60, Density: 0.02, Coupling: 0.00] | Drag: 4.66 | LOC: 3436/400  ⚠️ Trigger: Oversized beyond the preferred 350-450 LOC working band.) → 🏗️ Split into 9 modules (target 350-450 LOC each, center ~400 LOC, floor 220 LOC)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D003_Surgical_Refactor_SRC_SERVICES_BACKEND/verification.json` (files at `_dev-system/tmp/D003_Surgical_Refactor_SRC_SERVICES_BACKEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D003_Surgical_Refactor_SRC_SERVICES_BACKEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/services/portal.rs`
- `backend/src/services/portal.rs` (89 functions, fingerprint 081f0264874a87dd70fc4d5bb225d324ca985580fd6655eb50595a8580092b16)
    - Grouped summary:
        - access_link_summary × 1 (lines: 534)
        - access_session_for_token × 1 (lines: 2905)
        - admin_access_link_summary × 1 (lines: 806)
        - assign_tour_to_customer × 1 (lines: 2286)
        - assigned_tour_ids_for_customer × 1 (lines: 1288)
        - assignment_access_url × 1 (lines: 563)
        - assignment_by_customer_and_tour × 1 (lines: 1091)
        - assignment_by_id × 1 (lines: 1149)
        - assignment_by_short_code × 1 (lines: 1037)
        - assignment_effective_expiry × 1 (lines: 578)
        - assignment_from_lookup_row × 1 (lines: 1203)
        - assignment_is_active × 1 (lines: 587)
        - assignment_view_by_id × 1 (lines: 2110)
        - authenticate_access_token × 1 (lines: 2889)
        - boost_portal_launch_branding × 1 (lines: 710)
        - build_customer_overview × 1 (lines: 1301)
        - bulk_assign_tours_to_customers × 1 (lines: 2352)
        - create_access_link_in_tx × 1 (lines: 1581)
        - create_customer × 1 (lines: 1655)
        - create_library_tour_from_zip × 1 (lines: 2491)
        - create_or_activate_assignment_link × 1 (lines: 2141)
        - current_access_link_for_customer × 1 (lines: 994)
        - current_customer_and_access_link_by_slug × 1 (lines: 1015)
        - customer_access_link_summary × 1 (lines: 546)
        - customer_assignment_rows × 1 (lines: 1394)
        - customer_assignment_view × 1 (lines: 1498)
        - customer_public × 1 (lines: 829)
        - customer_tour_assignment_view × 1 (lines: 596)
        - dedupe_ids × 1 (lines: 738)
        - delete_access_links × 1 (lines: 1883)
        - delete_customer × 1 (lines: 2591)
        - delete_library_tour × 1 (lines: 2656)
        - detect_portal_package_root × 1 (lines: 3319)
        - encode_portal_cover_webp × 1 (lines: 3160)
        - ensure_assignment_short_code × 1 (lines: 1338)
        - ensure_portal_cover_path × 1 (lines: 3166)
        - ensure_settings_row × 1 (lines: 927)
        - extract_portal_package × 1 (lines: 3217)
        - gallery_view_for_customer × 1 (lines: 2985)
        - generate_portal_cover_thumbnail × 1 (lines: 3107)
        - generate_unique_short_code × 1 (lines: 514)
        - init_storage × 1 (lines: 420)
        - inject_base_href × 1 (lines: 690)
        - is_portal_admin × 1 (lines: 837)
        - list_customer_assignments_view × 1 (lines: 2094)
        - list_customers × 1 (lines: 1320)
        - list_library_tours × 1 (lines: 1917)
        - list_tour_assignments_view × 1 (lines: 2102)
        - load_assignment_record_for_customer_tour × 1 (lines: 1991)
        - load_authorized_portal_tour × 1 (lines: 854)
        - load_customer_session × 1 (lines: 2942)
        - load_portal_launch_document × 1 (lines: 3046)
        - load_settings × 1 (lines: 942)
        - log_audit × 1 (lines: 3371)
        - log_audit_event × 1 (lines: 3394)
        - make_short_code × 1 (lines: 473)
        - next_available_library_tour_slug × 1 (lines: 2463)
        - normalize_recipient_type × 1 (lines: 440)
        - parse_expiry × 1 (lines: 452)
        - portal_launch_entry_candidates × 1 (lines: 662)
        - portal_library_tour_dir × 1 (lines: 424)
        - portal_storage_root × 1 (lines: 414)
        - public_access_code × 1 (lines: 527)
        - public_customer_view × 1 (lines: 2921)
        - reactivate_assignment_link × 1 (lines: 2248)
        - regenerate_access_link × 1 (lines: 1794)
        - resolve_access_token × 1 (lines: 2723)
        - resolve_portal_asset × 1 (lines: 3080)
        - revoke_access_links × 1 (lines: 1846)
        - revoke_assignment_link × 1 (lines: 2171)
        - sanitize_relative_path × 1 (lines: 3342)
        - sanitize_relative_path_blocks_parent_segments × 1 (lines: 3431)
        - sha256_hex × 1 (lines: 467)
        - short_code_exists × 1 (lines: 486)
        - should_keep_portal_relative_path × 1 (lines: 3311)
        - slugify × 1 (lines: 458)
        - slugify_normalizes_and_strips_noise × 1 (lines: 3425)
        - tour_assignment_rows × 1 (lines: 1446)
        - tour_recipient_assignment_view × 1 (lines: 629)
        - tour_recipient_view × 1 (lines: 1543)
        - unassign_tour_from_customer × 1 (lines: 2316)
        - update_assignment_expiry × 1 (lines: 2210)
        - update_customer × 1 (lines: 1739)
        - update_library_tour_status × 1 (lines: 2548)
        - update_settings × 1 (lines: 950)
        - upsert_assignment_link × 1 (lines: 2008)
        - validate_existing_customer_ids × 1 (lines: 748)
        - validate_existing_tour_ids × 1 (lines: 777)
        - validate_slug × 1 (lines: 430)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
