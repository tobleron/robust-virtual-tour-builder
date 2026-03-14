# 1857 Deferred Unit Test Alignment For Landscape Touch Export Variant

## Reason

Landscape-touch export UI is being introduced as a new standalone calibration path and is expected to change over several short UI iterations. Source verification should stay fast during that calibration window, with unit-test alignment deferred until the shell behavior and styling settle.

## Source Files Touched

- `src/components/Sidebar/SidebarBase.res`
- `src/components/Sidebar/SidebarPublishOptionsContent.res`
- `src/components/Sidebar/SidebarExportLogic.res`
- `src/systems/Exporter/ExporterPackagingTemplates.res`
- `src/systems/TourTemplateHtml.res`
- `src/systems/TourTemplates/TourScriptViewport.res`
- `src/systems/TourTemplates/TourScriptUIMap.res`
- `src/systems/TourTemplates/TourScriptUINav.res`
- `src/systems/TourTemplates/TourStyles.res`
- `backend/src/api/project_multipart_files.rs`
- `backend/src/services/project/package.rs`
- `backend/src/services/project/package_assets.rs`
- `backend/src/services/project/package_output.rs`
- `backend/src/services/project/package_utils.rs`

## Deferred Test Files / Areas

- `tests/unit/TourTemplateScripts_v.test.res`
- `tests/unit/TourTemplateStyles_v.test.res`
- `tests/unit/TourTemplates_v.test.res`
- `tests/unit/Exporter_v.test.res`
- backend package output tests covering root launcher / desktop standalone variants

## Verification During Calibration

- `npm run build`
- `cd backend && cargo check`

## Follow-Up

- Add assertions for the new `desktop_blob_2k_landscape_touch` profile mapping.
- Add export HTML/script assertions for forced `landscape-touch` shell selection.
- Add CSS assertions for landscape-touch docking, floor controls, and joystick placement above the logo.
- Add backend package assertions for the new `desktop_landscape_touch/` output and dynamic root launcher links.
