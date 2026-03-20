# T1892 Troubleshoot Dev Runtime Errors

## Objective
Reproduce and isolate the `npm run dev` errors or warnings reported after the contextual hotspot sequence change, then fix the underlying cause without regressing the build.

## Hypothesis
- [ ] The dev issue is caused by the new `LinkModal.res` sequence-context helper using a shape that is valid for `npm run build` but triggers a watch-mode or hot-reload edge case.
- [ ] The dev issue is unrelated to the hotspot change and is coming from an existing dev-system or watcher path surfaced only under `npm run dev`.
- [ ] The dev issue is a warning-only condition from one of the concurrently running dev processes, not a hard failure.

## Activity Log
- [x] Reproduced `npm run dev` and confirmed the failure was in the backend compile step.
- [x] Identified the failing area as the Rust auth/dev-login path, not the frontend or ReScript watch chain.
- [x] Fixed the missing auth facade wiring and dev helper functions.
- [x] Re-ran `cargo build` and `npm run dev` until the backend compiled and the full dev stack started cleanly.

## Code Change Ledger
- [x] `src/systems/HotspotSequence.res` - added contextual sequence helpers for the hotspot `#` picker.
- [x] `src/components/LinkModal.res` - switched the retarget sequence UI to the contextual helper.
- [x] `backend/src/api/auth.rs` - restored dev-login wiring, added config helpers, and added dev bootstrap helpers for local-only auth.
- [x] `backend/src/api/auth_utils.rs` - added `config_bool` for env-driven boolean configuration.
- [x] `backend/src/api/auth_flows_session_dev.rs` - rewired dev-login to use auth-module helpers instead of crate-root paths.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The current implementation change is limited to hotspot sequence selection and the global reorder engine. The user reports `npm run dev` still produces errors or warnings, so this task should focus on reproducing the exact dev-mode failure rather than the build path. Keep the investigation isolated from the active feature task unless the fix directly overlaps.

## Notes
- The existing production build passes.
- Keep the investigation focused on dev runtime behavior, not unrelated cleanup.
