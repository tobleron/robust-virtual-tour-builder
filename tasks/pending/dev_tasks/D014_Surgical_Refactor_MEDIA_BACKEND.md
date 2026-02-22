# Task D014: Surgical Refactor MEDIA BACKEND

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

- [ ] - **../../backend/src/api/media/video.rs** (Metric: [Nesting: 3.00, Density: 0.06, Coupling: 0.03] | Drag: 4.55 | LOC: 414/300) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../backend/src/api/media/video_logic.rs** (Metric: [Nesting: 3.00, Density: 0.07, Coupling: 0.01] | Drag: 4.67 | LOC: 967/300) → 🏗️ Split into 4 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D014/verification.json` (files at `_dev-system/tmp/D014/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D014/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/api/media/video.rs`
- `backend/src/api/media/video.rs` (15 functions, fingerprint 10f42073366d2df0e0b95001ea09f1ab79933219a3cd4c8d9bffa055f64050b2)
    - Grouped summary:
        - extract_auth_token × 1 (lines: 16)
        - extract_auth_token_falls_back_to_cookie × 1 (lines: 291)
        - extract_auth_token_prefers_authorization_header × 1 (lines: 282)
        - generate_teaser × 1 (lines: 51)
        - parse_motion_manifest × 1 (lines: 32)
        - parse_motion_manifest_decodes_valid_payload × 1 (lines: 314)
        - parse_motion_profile × 1 (lines: 28)
        - parse_motion_profile_decodes_camel_case_payload × 1 (lines: 299)
        - parse_motion_profile_rejects_invalid_payload × 1 (lines: 308)
        - transcode_video × 1 (lines: 222)
        - validate_motion_manifest × 1 (lines: 36)
        - validate_motion_manifest_accepts_valid_manifest × 1 (lines: 394)
        - validate_motion_manifest_rejects_empty_shots × 1 (lines: 381)
        - validate_motion_manifest_rejects_invalid_fps × 1 (lines: 358)
        - validate_motion_manifest_rejects_invalid_version × 1 (lines: 345)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `backend/src/api/media/video_logic.rs`
- `backend/src/api/media/video_logic.rs` (16 functions, fingerprint ffb3f85250c5367e7e71b3c7f9a5d1493aac2a1cc2799c96dd68a9f1cb80f177)
    - Grouped summary:
        - apply_capture_mode × 1 (lines: 165)
        - capture_frames_cdp × 1 (lines: 295)
        - capture_frames_polling × 1 (lines: 494)
        - content_type × 1 (lines: 132)
        - drop × 1 (lines: 153)
        - extension × 1 (lines: 125)
        - from_str × 1 (lines: 118)
        - generate_teaser_sync × 1 (lines: 605)
        - get_ffmpeg_command × 1 (lines: 946)
        - headless_backend_origin × 1 (lines: 161)
        - new × 1 (lines: 143)
        - resolve_capture_viewport × 1 (lines: 179)
        - start_script_content × 1 (lines: 270)
        - take × 1 (lines: 147)
        - teaser_output_format_parses_mp4_and_defaults_to_webm × 1 (lines: 955)
        - transcode_video × 1 (lines: 207)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
