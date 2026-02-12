# [1354] State Boundary Migration Phase 2 (Bridge Decommission)

## Objective
Complete boundary hardening by removing `GlobalStateBridge` from non-bootstrap runtime paths.

## Scope
1. Migrate remaining direct `AppStateBridge` usage in non-bootstrap UI/systems to explicit interfaces.
2. Decommission `GlobalStateBridge` usage in runtime-critical modules.
3. Keep bridge only where strictly required during app bootstrap, if still needed.

## Target Files
- `src/core/GlobalStateBridge.res`
- `src/systems/TeaserLogic.res`
- `src/components/VisualPipeline.res`
- `src/components/UploadReport.res`
- `src/components/LinkModal.res`

## Verification
- `npm run build`
- run affected UI workflows: teaser, timeline operations, upload summary actions.

## Acceptance Criteria
- `GlobalStateBridge` removed from runtime-critical execution paths.
- Migration introduces zero new warnings and no regressions in linked flows.
