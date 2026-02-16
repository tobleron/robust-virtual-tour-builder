# 1425 - Migrate App Hotspot Navigation to Stable Scene IDs

## Objective
Adopt scene-id-based hotspot targeting across the application (not only export) while preserving compatibility with legacy name-based projects.

## Scope
- Extend hotspot model with optional `targetSceneId`.
- Serialize/deserialize `targetSceneId` in project persistence.
- Ensure new/edited links store `targetSceneId`.
- Update runtime lookup/navigation logic to prefer id and fallback to name.
- Keep legacy projects functional during migration.

## Implementation Checklist
- [x] Add `targetSceneId: option<string>` to `Types.hotspot` and default constructors.
- [x] Update JSON encoders/decoders for hotspot `targetSceneId`.
- [x] Update link creation/edit flows to write canonical `targetSceneId`.
- [x] Update hotspot consumers (navigation/menus/preview/simulation) to resolve target scene by id first.
- [x] Update scene rename/deletion logic to keep compatibility with both id and name links.
- [x] Run build and fix all compile/runtime regressions.

## Change Log (for Revert)
- [x] `src/core/Types.res` - hotspot schema extended with `targetSceneId`.
- [x] `src/core/HotspotTarget.res` - new shared resolver (`id` first, then canonicalized fallback by name/reference).
- [x] `src/core/SceneInventory.res` - active scenes and inventory entries now hydrate canonical hotspot target ids.
- [x] `src/core/JsonParsersEncoders.res` / `src/core/JsonParsersDecoders.res` - persistence contract updated.
- [x] `src/components/LinkModal.res` - new links write `targetSceneId` and timeline stores canonical target id.
- [x] `src/components/HotspotManager.res`, `src/components/HotspotActionMenu.res`, `src/components/PreviewArrow.res`, `src/components/ViewerManagerLogic.res`, `src/systems/Scene/SceneSwitcher.res`, `src/systems/Simulation/SimulationNavigation.res`, `src/systems/Simulation/SimulationMainLogic.res`, `src/systems/Navigation/NavigationUI.res` - hotspot target resolution switched to id-first via `HotspotTarget`.
- [x] `src/core/HotspotHelpers.res`, `src/core/SceneOperations.res`, `src/core/SceneNaming.res` - delete/rename behaviors adapted for id-linked hotspots.
- [x] `src/systems/TourTemplates.res` - export now consumes `hotspot.targetSceneId` when present.
- [x] Tests/fixtures updated for new hotspot field (`targetSceneId`).

## Validation
- [x] `npm run build`

## Completion Note
This task should remain compatibility-safe: old projects with missing `targetSceneId` must still navigate correctly.
