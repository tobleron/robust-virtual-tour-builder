# T1836 Troubleshoot Desktop 2K Export Regression

## Objective
Identify why the packaged desktop 2K export no longer runs after the recent export runtime/minification changes and restore working desktop export behavior without regressing the web export variants.

## Hypothesis (Ordered Expected Solutions)
- [ ] The new backend HTML minification is breaking the desktop blob export specifically by minifying inline JavaScript in a way that changes runtime behavior.
- [x] The desktop blob HTML builder is embedding data in a form that the minifier rewrites unsafely, while the web-only export path remains unaffected.
- [x] The recent auto-tour manifest/runtime changes introduced an export script assumption that is valid in the web export but invalid in the desktop blob variant.
- [ ] Desktop-specific asset rewriting or blob bootstrap logic is emitting malformed HTML/JS after the recent changes.
- [ ] The provided artifact contains a packaging-time corruption unrelated to source generation, such as truncated inline assets or invalid replacement output.

## Activity Log
- [x] Re-read project docs/process and started a dedicated troubleshooting task.
- [x] Locate the user-provided artifact bundle inside `artifacts/`.
- [x] Inspect desktop bundle HTML/bootstrap script and compare against web export path.
- [x] Reproduce the failure locally from the artifact and capture the runtime bootstrap error in headless Chromium.
- [x] Trace the failure to generated script ordering: `autoTourManifest` was declared after `TourScriptNavigation` read it at top level.
- [x] Trace the secondary desktop-only asset rewrite bug: CSS first-scene background still referenced `../../assets/images/...`, producing broken `../../data:image...` URLs in the blob package.
- [x] Patch the smallest safe fix and verify desktop export plus normal build.
- [x] Verify frontend export template with targeted unit test and full frontend build.
- [x] Verify backend desktop blob packager with focused Rust test and `cargo check`.

## Code Change Ledger
- [x] `src/systems/TourTemplateHtml.res` - Reordered `scenesData` and `autoTourManifest` declarations ahead of the runtime script so desktop export bootstrap no longer hits temporal-dead-zone failure. Revert if this creates any render-script dependency regression.
- [x] `tests/unit/TourTemplates_v.test.res` - Added regression assertion that `autoTourManifest` is declared before `autoTourSteps` consumes it. Revert if test proves brittle after template refactors.
- [x] `backend/src/services/project/package_utils.rs` - Rewrote desktop blob packaging to replace both runtime `assets/images/...` paths and CSS `../../assets/images/...` paths with data URIs, preventing broken `../../data:image...` lookups. Revert if desktop packaging ever stops emitting the CSS background path.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The provided desktop artifact failed immediately because `TourScriptNavigation` read `autoTourManifest` before the export template declared it, causing a temporal-dead-zone `ReferenceError` at startup. The same artifact also revealed a desktop-only packaging bug where CSS still referenced `../../assets/images/...`, so blob replacement produced invalid `../../data:image...` URLs for the first-scene background. The source and packager are now patched; the next real-world confirmation is to regenerate a fresh desktop 2K export and open that new package.
