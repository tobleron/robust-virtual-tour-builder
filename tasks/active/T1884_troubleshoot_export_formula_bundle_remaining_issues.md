# T1884 Troubleshoot Export Formula Bundle Remaining Issues

## Objective
Record and resolve the remaining problems that appeared while the export was still split between a baseline web package and an optional testing-formula bundle. The bundle path has now been superseded by the formula-default web package flow, so this task is historical troubleshooting context rather than current feature work.

## Hypothesis (Ordered Expected Solutions)
- [ ] Fix any remaining backend packaging compile or contract mismatches for the new `web_package_testing_formula` profile.
- [ ] Fix any export-dialog or publish-profile wiring gaps that prevent the extra bundle from being emitted correctly.
- [ ] Fix any generated-runtime or packaging-output path mismatch causing the comparison bundle to be missing or malformed.

## Activity Log
- [x] Reproduced and fixed two ReScript call-site arity errors in `src/systems/Exporter/ExporterPackagingTemplates.res`.
- [x] Verified `npm run build` passes after the ReScript fixes.
- [x] Ran backend build verification for the Rust packaging changes.
- [x] Fixed `backend/src/services/project/package_utils.rs` deployment-readme helper syntax break.
- [x] Fixed `backend/src/services/project/package.rs` missing wrapper for the testing-formula deployment readme helper.
- [x] Verified `cargo build` passes after the Rust fixes.
- [x] Inspected generated export/profile wiring for the new testing-formula fields and output paths.
- [x] Found and fixed the runtime export failure in `backend/src/api/project_multipart_files.rs` by whitelisting the new testing-formula multipart fields so they are parsed as strings instead of scene uploads.
- [x] Verified `cargo build` and `npm run build` pass after the multipart parser fix.

## Code Change Ledger
- [x] `src/systems/Exporter/ExporterPackagingTemplates.res` - removed invalid unlabeled `()` arguments from labeled-only helper calls. Revert if helper signature changes back to unit-taking form.
- [x] `backend/src/services/project/package_utils.rs` - corrected malformed `format!` return structure in the shared web-bundle deployment readme helper. Revert if the helper is rewritten to a different string-construction pattern.
- [x] `backend/src/services/project/package.rs` - added the missing wrapper exposing `create_web_only_testing_formula_deployment_readme` to sibling packaging modules. Revert if packaging modules are refactored to call `package_utils` directly.
- [x] `backend/src/api/project_multipart_files.rs` - added `html_*_testing_formula`, `html_index_testing_formula`, and `embed_codes_testing_formula` to the multipart string-field whitelist. Revert if the export schema changes again.

## Rollback Check
- [x] Confirmed CLEAN. The current troubleshooting edits compile on both frontend and backend paths.
- [x] Confirmed CLEAN after runtime export parser fix.

## Context Handoff
The troubleshooting pass resolved the compile issues and the actual runtime export failure introduced while the comparison bundle existed. The root cause was the multipart parser not recognizing the new formula HTML fields, so it was treating them as uploaded image files and the export failed when the comparison bundle was selected. That bundle path is no longer part of the current product direction; both `cargo build` and `npm run build` pass on the formula-default export flow.
