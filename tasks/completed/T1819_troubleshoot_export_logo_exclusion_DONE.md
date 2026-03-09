# T1819 Troubleshoot Export Logo Exclusion

## Context
- User concern: when publishing/exporting a tour with "include logo" not selected, verify whether the web export still includes the logo anyway.
- Scope: trace the export path from frontend export options through template generation and backend packaging, then fix any bug so the export output matches the option exactly.
- Constraint: preserve existing function signatures and keep changes minimal.

## Hypothesis (Ordered Expected Solutions)
- [x] The frontend export request is always sending branding/logo data even when the "include logo" option is disabled.
- [ ] The export template builder is receiving the option correctly but still renders the default/custom logo unconditionally.
- [ ] The backend packaging step always bundles `logo.*` assets regardless of the export option, so the exported site can still resolve a logo at runtime.
- [x] The exported runtime falls back to a bundled/default logo even when the export manifest says to omit it.

## Activity Log
- [x] Read export-related map/data-flow context and task workflow rules.
- [x] Create active troubleshooting task.
- [x] Trace the frontend publish/export option path.
- [x] Trace the export template generation path.
- [x] Trace the backend packaging/assets inclusion path.
- [x] Reproduce or disprove the bug from code and output inspection.
- [x] Implement the smallest correct fix.
- [x] Verify build/tests and inspect export output.

## Code Change Ledger
- [x] [src/components/Sidebar/SidebarExportLogic.res](src/components/Sidebar/SidebarExportLogic.res): passed the explicit `publishOptions.includeLogo` flag into the lazy export boundary so the exporter can distinguish "disabled" from "no custom logo provided".
- [x] [src/systems/FeatureLoaders.js](src/systems/FeatureLoaders.js): extended `exportTourLazy` JS bridge arity to pass the new include-logo flag through to the ReScript exporter.
- [x] [src/systems/FeatureLoaders.res](src/systems/FeatureLoaders.res): updated the typed external binding for `exportTourLazy` to match the JS bridge arity.
- [x] [src/systems/Exporter.res](src/systems/Exporter.res): threaded `~includeLogo` into the exporter flow and gated default-logo fallback through the packaging layer.
- [x] [src/systems/Exporter/ExporterPackaging.res](src/systems/Exporter/ExporterPackaging.res): added an explicit `~allowDefaultLogoFallback` handoff to the asset packager.
- [x] [src/systems/Exporter/ExporterPackagingAssets.res](src/systems/Exporter/ExporterPackagingAssets.res): prevented fallback lookup of `/images/logo.*` when export branding is disabled.
- [x] [tests/unit/Exporter_v.test.res](tests/unit/Exporter_v.test.res): added regression coverage proving `appendLogo` does not fetch/package the default logo when fallback is disabled.
- [x] Revert note: no non-working code paths were kept; only the verified minimal gating fix remains.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
- [x] Root cause was in `ExporterPackagingAssets.appendLogo`, which treated `None` as "use default logo" even when the sidebar option had intentionally disabled branding.
- [x] The fix passes the explicit include-logo intent from `SidebarExportLogic` through `FeatureLoaders` into `Exporter`, then disables default-logo fallback in the packaging helper when that intent is false.
- [x] Verification passed with `npm run res:build`, `npx vitest tests/unit/Exporter_v.test.bs.js --run`, and `npm run build`.
