# Task: 803 - Test: Scene Loader & Transition Orchestration (New + Update)

## Objective
Validate the entire scene loading lifecycle, including viewer configuration, asset preloading, and transition events.

## Merged Tasks
- 778_Test_SceneLoaderLogic_New.md
- 792_Test_SceneLoaderLogicConfig_New.md
- 793_Test_SceneLoaderLogicEvents_New.md
- 794_Test_SceneLoaderLogicReuse_New.md
- 779_Test_SceneLoaderTypes_New.md
- 697_Test_SceneSwitcher_Update.md
- 698_Test_SceneTransitionManager_Update.md

## Technical Context
Scene loading is the most sensitive part of the UX. Grouping these ensures that the interaction between `SceneLoaderLogic` (orchestration), `Config` (params), and `Events` (hooks) is seamless.

## Implementation Plan
1. **LogicConfig**: Verify Pannellum URL generation and orientation parameters.
2. **LogicEvents**: Test hotspot injection and load-success event handling.
3. **LogicReuse**: Verify viewer instance pooling and context-switching logic.
4. **Transition Manager**: Test the DOM-swapping logic between active and preloading viewports.
5. **Types**: Ensure type safety across the loader boundaries.

## Verification Criteria
- [ ] Successfully loads mock scenes in test environment.
- [ ] Hotspot injection is verified via event mocks.
- [ ] Transition timing matches expectations.
