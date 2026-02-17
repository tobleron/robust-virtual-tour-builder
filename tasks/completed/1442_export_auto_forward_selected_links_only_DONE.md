# 1442 - Export auto-forward from selected link mode only

## Objective
Implement export runtime behavior so scenes auto-advance only when the active scene's selected navigation link is configured as auto-forward (double-chevron) in the builder. This is export-only behavior for customer tours.

## Scope
- Export runtime (`src/systems/TourTemplates.res`): add/align scene-level auto-advance resolution from authored hotspot metadata.
- Preserve simulation behavior (builder preview) as-is.
- Ensure manual-forward links remain manual in exported tours.
- Keep existing waypoint animation path and timing parity.

## Requirements
- If current scene has an authored next link marked auto-forward, exported tour must advance automatically after arrival.
- If current scene has only manual links, exported tour must not auto-advance.
- No changes to simulation mode logic in builder.
- No regression in export hotspot click navigation.

## Verification
- Build passes: `npm run build`.
- Manual sanity: exported tour auto-advances only for scenes flagged auto-forward via double-chevron.

## Notes
This task covers customer-facing export runtime behavior only. Any additional authoring UX changes are out of scope.
