# Task: 806 - Test: External Bindings & Facade Integrity (New + Update)

## Objective
Verify the correctness and safety of all external JavaScript/Web API bindings.

## Merged Tasks
- 744_Test_BrowserBindings_New.md
- 745_Test_DomBindings_New.md
- 746_Test_GraphicsBindings_New.md
- 747_Test_ViewerBindings_New.md
- 748_Test_WebApiBindings_New.md
- 796_Test_IdbBindings_New.md
- 605_Test_ReBindings_Update.md

## Technical Context
Testing bindings ensures that the low-level JS bridge is robust. Grouping these allows for a single consolidated mocking strategy for browser globals.

## Implementation Plan
1. **Browser/Dom**: Verify `window` and `document` property access.
2. **Idb/WebAPI**: Mock IndexedDB and Fetch APIs to verify ReScript wrappers call them correctly.
3. **Graphics/Viewer**: Test Canvas/SVG and Pannellum initialization parameters.

## Verification Criteria
- [ ] All binding wrappers have at least one smoke test.
- [ ] Nullable values from JS are correctly handled as `Option` types.
