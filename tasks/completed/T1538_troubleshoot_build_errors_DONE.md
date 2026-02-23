# T1538 Troubleshoot Build Errors

## Assignee

- Codex

## Objective

- Resolve current build failures related to missing fields and Belt array usage, ensuring the project compiles cleanly.

## Boundary

- Frontend ReScript modules touched by the failing build (Types, Navigation graph/state, TourLogic, TestUtils, and related state fixtures).

## Owned Interfaces

- `Types.state`, `NavigationGraph`, `TourLogic`, `TestUtils`, and any selectors/imports that rely on `nextSceneSequenceId`.

## No-Touch Zones

- Rust backend files and unrelated UI components.

## Hypothesis (Ordered Expected Solutions)

- [ ] Fix missing `nextSceneSequenceId` field usage in `NavigationGraph` initialization/state updates so tests and serialization happy.
- [ ] Update `TestUtils` default state to include the same required fields and align with current `Types.state` structure.
- [ ] Replace incorrect `Belt.Array.forAll` usage in `TourLogic` with `Belt.Array.every` to match API.

## Activity Log

- [x] Ran current build to capture failure diagnostics (missing `sequenceId`/`nextSceneSequenceId` fields and invalid `Belt.Array.forAll`).
- [x] Propagated `sequenceId`/`nextSceneSequenceId` defaults across Types, Scene helpers, UploadReport, and all affected test fixtures.
- [x] Replaced the unsupported `Belt.Array.forAll` call in `TourLogic` and ensured localization of unused-vars/collection helpers in downstream helpers.
- [x] Re-ran `npm run build` to confirm the toolchain now compiles cleanly (includes rescript sync, build, and rsbuild steps).

## Code Change Ledger

- [x] Ensured `Types.state`, `SceneHelpers`, `UploadReport`, and the project parser expose `nextSceneSequenceId` so the new field is always present.
- [x] Added `sequenceId` defaults to scene fixtures across tests (Teaser, UtilityBar, Simulation, Panorama, Exporter, ViewerManager, HotspotManager, etc.) and kept `TestUtils` symbols reusable.
- [x] Swapped the unsupported `Belt.Array.forAll` usage for `Belt.Array.every` and a safe `Js.String.split` based digit check in `TourLogic`.
- [x] Cleaned up helper iterations/unused variables in `SceneNaming` and `UploadFinalizer`.

## Rollback Check

- [ ] Not performed yet.

## Context Handoff

- (Place a 3-sentence summary here if troubleshooting runs out of time.)
