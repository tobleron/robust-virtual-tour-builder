# Task 330: Update Unit Tests for LabelMenu.res - REPORT

## Objective
Update `tests/unit/LabelMenu_v.test.res` to ensure it covers recent changes in `LabelMenu.res`.

## Fulfilment
- Reviewed `src/components/LabelMenu.res` and identified logic for rendering room presets based on category and handling custom labels.
- Updated `tests/unit/LabelMenu_v.test.res` with comprehensive Vitest tests:
    - Verified correct rendering of "Outdoor" presets when scene category is outdoor.
    - Verified correct rendering of "Indoor" presets when scene category is indoor.
    - Verified that clicking "CLEAR LABEL" dispatches the correct `UpdateSceneMetadata` action.
- Refined global Shadcn mocks in `tests/unit/LabelMenu_v.test.setup.jsx` to properly support ReScript React component structure and child rendering.
- Verified all tests pass by running `npx vitest run tests/unit/LabelMenu_v.test.bs.js`.
