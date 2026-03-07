# Task D003: Surgical Refactor API BACKEND

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

- [ ] - **../../backend/src/api/auth.rs** (Metric: [Nesting: 2.40, Density: 0.03, Coupling: 0.01] | Drag: 3.44 | LOC: 2209/300) → 🏗️ Split into 8 modules (target ~300 LOC each)

- [ ] - **../../backend/src/api/project.rs** (Metric: [Nesting: 3.00, Density: 0.03, Coupling: 0.03] | Drag: 4.06 | LOC: 500/300) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D003/verification.json` (files at `_dev-system/tmp/D003/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D003/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/api/auth.rs`
- `backend/src/api/auth.rs` (63 functions, fingerprint 4901336e0c3a1d1ae3882d7a68c61d6583b930375d6518569f6addad4ccbcdd3)
    - Grouped summary:
        - app_base_url × 1 (lines: 369)
        - clear_auth_cookie × 1 (lines: 285)
        - compute_risk_decision × 1 (lines: 912)
        - config_bool × 1 (lines: 166)
        - config_i64 × 1 (lines: 159)
        - count_recent_failed_logins × 1 (lines: 725)
        - create_auth_cookie × 1 (lines: 275)
        - create_device_cookie × 1 (lines: 295)
        - dev_auth_bootstrap_enabled × 1 (lines: 533)
        - dev_auth_email × 1 (lines: 537)
        - dev_auth_name × 1 (lines: 549)
        - dev_auth_password × 1 (lines: 553)
        - dev_auth_username × 1 (lines: 543)
        - dev_signin × 1 (lines: 1580)
        - empty_login_context × 1 (lines: 473)
        - enforce_failed_login_rate_limit × 1 (lines: 814)
        - enforce_otp_issue_rate_limit × 1 (lines: 1048)
        - ensure_dev_bootstrap_user × 1 (lines: 1513)
        - evaluate_context_mismatch × 1 (lines: 885)
        - evaluate_geo_anomaly × 1 (lines: 852)
        - evaluate_ip_reputation × 1 (lines: 557)
        - extract_login_context × 1 (lines: 418)
        - find_trusted_device × 1 (lines: 641)
        - forgot_password × 1 (lines: 1657)
        - generate_otp_code × 1 (lines: 266)
        - hash_otp × 1 (lines: 261)
        - hash_password × 1 (lines: 233)
        - hash_token × 1 (lines: 251)
        - haversine_km × 1 (lines: 839)
        - is_local_dev_request × 1 (lines: 516)
        - is_local_request_host × 1 (lines: 507)
        - is_production × 1 (lines: 155)
        - issue_or_refresh_step_up_challenge × 1 (lines: 985)
        - issue_verification_email × 1 (lines: 373)
        - load_last_success_login_context × 1 (lines: 685)
        - log_auth_event × 1 (lines: 574)
        - log_login_attempt × 1 (lines: 613)
        - make_device_token × 1 (lines: 257)
        - me × 1 (lines: 1643)
        - normalize_email × 1 (lines: 178)
        - normalize_username × 1 (lines: 182)
        - otp_is_six_digits × 1 (lines: 2192)
        - parse_user_agent_family × 1 (lines: 487)
        - password_min_length_enforced × 1 (lines: 2181)
        - public_user × 1 (lines: 306)
        - resend_step_up_otp × 1 (lines: 2004)
        - resend_verification_email × 1 (lines: 1235)
        - reset_password × 1 (lines: 1705)
        - revoke_all_trusted_devices × 1 (lines: 2133)
        - send_email_or_log × 1 (lines: 318)
        - signin × 1 (lines: 1316)
        - signout × 1 (lines: 1636)
        - signup × 1 (lines: 1169)
        - token_hash_is_deterministic × 1 (lines: 2187)
        - upsert_trusted_device × 1 (lines: 1090)
        - user_agent_family_parse_works × 1 (lines: 2199)
        - username_validation_accepts_expected_slug × 1 (lines: 2171)
        - username_validation_rejects_reserved × 1 (lines: 2176)
        - validate_password × 1 (lines: 224)
        - validate_username × 1 (lines: 186)
        - verify_email × 1 (lines: 1266)
        - verify_password × 1 (lines: 242)
        - verify_step_up_otp × 1 (lines: 1784)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `backend/src/api/project.rs`
- `backend/src/api/project.rs` (18 functions, fingerprint 1e4ca1085013a207821e97a8233add0d2ee29ba07eb6301961000aed9172d3ee)
    - Grouped summary:
        - calculate_path × 1 (lines: 382)
        - cleanup_backend_cache × 1 (lines: 347)
        - count_hotspots × 1 (lines: 46)
        - create_tour_package × 1 (lines: 430)
        - drop × 3 (lines: 120, 141, 456)
        - keep × 1 (lines: 136)
        - list_dashboard_projects × 1 (lines: 274)
        - load_dashboard_project × 1 (lines: 327)
        - load_project × 1 (lines: 210)
        - new × 1 (lines: 132)
        - read_snapshot × 1 (lines: 73)
        - save_project × 1 (lines: 103)
        - scene_count × 1 (lines: 65)
        - sync_snapshot × 1 (lines: 238)
        - validate_project × 1 (lines: 403)
        - validate_snapshot_project × 1 (lines: 80)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
