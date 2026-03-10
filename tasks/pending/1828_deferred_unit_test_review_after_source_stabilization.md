# 1828 Deferred Unit Test Review After Source Stabilization

## Purpose
This is the single shared pending task for deferred unit-test review after iterative source-code changes. Reuse this task instead of creating new test-review tasks whenever source files are still being calibrated and build verification is being used as the primary short-cycle check.

## Reuse Rule
- Do not create another deferred test-review task for the same stabilization campaign.
- Append newly changed source files/modules to the checklist below as work continues.
- Execute this task only after the relevant source behavior is considered stable enough that updating tests will not be wasted churn.

## Current Deferred Review Targets
- [ ] [src/site/PageFrameworkBuilder.js](src/site/PageFrameworkBuilder.js): review/add frontend coverage for builder data normalization changes.
- [ ] [src/systems/TourTemplateHtml.res](src/systems/TourTemplateHtml.res): review export-generation unit coverage against current authored behavior.
- [ ] [src/systems/TourTemplates/TourData.res](src/systems/TourTemplates/TourData.res): review sequence-edge/data-shape test coverage.
- [ ] [src/systems/TourTemplates/TourScriptCore.res](src/systems/TourTemplates/TourScriptCore.res): review export runtime helper and auto-tour timing constant coverage after speed multiplier changes.
- [ ] [src/systems/TourTemplates/TourScriptHotspots.res](src/systems/TourTemplates/TourScriptHotspots.res): review export hotspot navigation/arrival behavior tests.
- [ ] [src/systems/TourTemplates/TourScriptInput.res](src/systems/TourTemplates/TourScriptInput.res): review export keyboard navigation coverage.
- [ ] [src/systems/TourTemplates/TourScriptNavigation.res](src/systems/TourTemplates/TourScriptNavigation.res): review export traversal/sequence engine coverage.
- [ ] [src/systems/TourTemplates/TourScriptUIMap.res](src/systems/TourTemplates/TourScriptUIMap.res): review export map/shortcut coverage.
- [ ] [src/systems/TourTemplates/TourScriptUINav.res](src/systems/TourTemplates/TourScriptUINav.res): review export shortcut-panel coverage.
- [ ] [src/systems/TourTemplates/TourScripts.res](src/systems/TourTemplates/TourScripts.res): review export load-script/runtime wiring coverage.
- [ ] [backend/src/api/project_snapshot.rs](backend/src/api/project_snapshot.rs): review/add backend unit tests for snapshot-origin dedupe behavior.
- [ ] [src/components/Sidebar.res](src/components/Sidebar.res): review teaser request wiring coverage for dialog-selected speed/style settings.
- [ ] [src/components/Sidebar/SidebarActions.res](src/components/Sidebar/SidebarActions.res): review sidebar teaser action coverage for extended teaser request payload.
- [ ] [src/components/Sidebar/SidebarActionsSupport.res](src/components/Sidebar/SidebarActionsSupport.res): review teaser settings modal coverage for style/speed selection behavior.
- [ ] [src/systems/FeatureLoaders.res](src/systems/FeatureLoaders.res): review lazy teaser-loader binding coverage for extended argument ordering.
- [ ] [src/systems/Teaser.res](src/systems/Teaser.res): review teaser facade coverage for speed-calibrated headless teaser options.
- [ ] [src/systems/TeaserHeadlessLogic.res](src/systems/TeaserHeadlessLogic.res): review motion-manifest retiming coverage for teaser pan-speed presets.
- [ ] [src/systems/TeaserManagerLogic.res](src/systems/TeaserManagerLogic.res): review manager wiring coverage for passing speed options to headless teaser generation.
- [ ] [src/systems/TeaserStyleConfig.res](src/systems/TeaserStyleConfig.res): review preset selection and manifest retiming coverage for teaser pan-speed calibration.

## Execution Notes
- Prefer updating existing relevant test files before creating new ones.
- Keep test changes scoped to behavior that is now stable in source.
- If a source file changes again before this task is executed, update this task instead of patching tests immediately unless the user explicitly requests test alignment now.

## Verification When Executed
- `npm run test:frontend`
- `cd backend && cargo test`
- any narrower targeted suite needed for the touched module family

## Exit Criteria
- Deferred source files above either have aligned coverage or are explicitly documented as intentionally relying on build/manual verification only.
- The checklist reflects the final stable behavior rather than intermediate calibration states.
