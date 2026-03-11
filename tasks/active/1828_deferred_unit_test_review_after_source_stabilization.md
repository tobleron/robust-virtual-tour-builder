# 1828 Deferred Unit Test Review After Source Stabilization

## Purpose
This is the single shared pending task for deferred unit-test review after iterative source-code changes. Reuse this task instead of creating new test-review tasks whenever source files are still being calibrated and build verification is being used as the primary short-cycle check.

## Reuse Rule
- Do not create another deferred test-review task for the same stabilization campaign.
- Append newly changed source files/modules to the checklist below as work continues.
- Execute this task only after the relevant source behavior is considered stable enough that updating tests will not be wasted churn.

## Current Deferred Review Targets
- [x] [src/site/PageFrameworkBuilder.js](src/site/PageFrameworkBuilder.js): covered by [tests/unit/PageFramework.test.js](tests/unit/PageFramework.test.js) for asset/logo/project normalization.
- [x] [src/systems/TourTemplateHtml.res](src/systems/TourTemplateHtml.res): covered by [tests/unit/TourTemplates_v.test.res](tests/unit/TourTemplates_v.test.res), [tests/unit/TourTemplateScripts_v.test.res](tests/unit/TourTemplateScripts_v.test.res), and [tests/unit/TourTemplateStyles_v.test.res](tests/unit/TourTemplateStyles_v.test.res).
- [x] [src/systems/TourTemplates/TourData.res](src/systems/TourTemplates/TourData.res): covered by [tests/unit/TourData_v.test.res](tests/unit/TourData_v.test.res) for target-ref resolution and manifest/data encoding.
- [x] [src/systems/TourTemplates/TourScriptCore.res](src/systems/TourTemplates/TourScriptCore.res): covered by [tests/unit/TourTemplates_v.test.res](tests/unit/TourTemplates_v.test.res) emitted-runtime assertions.
- [x] [src/systems/TourTemplates/TourScriptHotspots.res](src/systems/TourTemplates/TourScriptHotspots.res): covered by [tests/unit/TourTemplates_v.test.res](tests/unit/TourTemplates_v.test.res) emitted-runtime assertions.
- [x] [src/systems/TourTemplates/TourScriptInput.res](src/systems/TourTemplates/TourScriptInput.res): covered by [tests/unit/TourTemplateScripts_v.test.res](tests/unit/TourTemplateScripts_v.test.res) and [tests/unit/TourTemplates_v.test.res](tests/unit/TourTemplates_v.test.res).
- [x] [src/systems/TourTemplates/TourScriptNavigation.res](src/systems/TourTemplates/TourScriptNavigation.res): covered by [tests/unit/TourTemplates_v.test.res](tests/unit/TourTemplates_v.test.res) emitted-runtime assertions.
- [x] [src/systems/TourTemplates/TourScriptUIMap.res](src/systems/TourTemplates/TourScriptUIMap.res): covered by [tests/unit/TourTemplates_v.test.res](tests/unit/TourTemplates_v.test.res) emitted-runtime assertions.
- [x] [src/systems/TourTemplates/TourScriptUINav.res](src/systems/TourTemplates/TourScriptUINav.res): covered by [tests/unit/TourTemplates_v.test.res](tests/unit/TourTemplates_v.test.res) emitted-runtime assertions.
- [x] [src/systems/TourTemplates/TourScripts.res](src/systems/TourTemplates/TourScripts.res): covered by [tests/unit/TourTemplateScripts_v.test.res](tests/unit/TourTemplateScripts_v.test.res).
- [x] [backend/src/api/project_snapshot.rs](backend/src/api/project_snapshot.rs): covered by its inline Rust unit test `persist_snapshot_history_upgrades_auto_origin_for_identical_manual_save`.
- [x] [src/components/Sidebar.res](src/components/Sidebar.res): covered by [tests/unit/Sidebar_v.test.res](tests/unit/Sidebar_v.test.res) and [tests/unit/SidebarSync_v.test.res](tests/unit/SidebarSync_v.test.res).
- [x] [src/components/Sidebar/SidebarActions.res](src/components/Sidebar/SidebarActions.res): covered indirectly by [tests/unit/Sidebar_v.test.res](tests/unit/Sidebar_v.test.res) teaser modal/action flow assertions.
- [x] [src/components/Sidebar/SidebarActionsSupport.res](src/components/Sidebar/SidebarActionsSupport.res): covered indirectly by [tests/unit/Sidebar_v.test.res](tests/unit/Sidebar_v.test.res) teaser modal/action flow assertions.
- [x] [src/systems/FeatureLoaders.res](src/systems/FeatureLoaders.res): covered by [tests/unit/FeatureLoaders.test.js](tests/unit/FeatureLoaders.test.js) for lazy teaser/export/EXIF argument forwarding.
- [x] [src/systems/Teaser.res](src/systems/Teaser.res): covered by [tests/unit/TeaserWiring.test.js](tests/unit/TeaserWiring.test.js) and [tests/unit/Teaser_v.test.res](tests/unit/Teaser_v.test.res).
- [x] [src/systems/TeaserHeadlessLogic.res](src/systems/TeaserHeadlessLogic.res): covered by [tests/unit/TeaserHeadlessLogic.test.js](tests/unit/TeaserHeadlessLogic.test.js) for cinematic-only pan-speed application.
- [x] [src/systems/TeaserManagerLogic.res](src/systems/TeaserManagerLogic.res): covered by [tests/unit/TeaserWiring.test.js](tests/unit/TeaserWiring.test.js).
- [x] [src/systems/TeaserStyleConfig.res](src/systems/TeaserStyleConfig.res): covered by [tests/unit/TeaserStyleConfig_v.test.res](tests/unit/TeaserStyleConfig_v.test.res).

## Execution Notes
- Prefer updating existing relevant test files before creating new ones.
- Keep test changes scoped to behavior that is now stable in source.
- If a source file changes again before this task is executed, update this task instead of patching tests immediately unless the user explicitly requests test alignment now.

## Verification When Executed
- `npm run test:frontend`
- `cd backend && cargo test persist_snapshot_history_upgrades_auto_origin_for_identical_manual_save`
- any narrower targeted suite needed for the touched module family

## Exit Criteria
- Deferred source files above either have aligned coverage or are explicitly documented as intentionally relying on build/manual verification only.
- The checklist reflects the final stable behavior rather than intermediate calibration states.
