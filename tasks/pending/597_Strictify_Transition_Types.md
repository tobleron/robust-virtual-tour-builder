# Strictify Transition Types

## Context
The `transition` type in `src/core/Types.res` uses a string option for the transition type:
```rescript
type transition = { @as("type") type_: option<string>, ... }
```
This relies on "stringly typed" logic which is prone to typos and errors.

## Objective
Convert `transition.type_` to a Variant type.

## Plan
1.  **Define Variant**: Create `type transitionType = Cut | Fade | Zoom | Blur | None` (or similar based on actual usage).
2.  **Refactor Record**: Update `transition` record to use this variant.
3.  **Update Encoders/Decoders**: Since this data often comes from JSON, ensure `JsonTypes` or manual decoding logic handles the string-to-variant conversion.
4.  **Update Usage**: Update all reducer logic and components that check `transition.type_`.
5.  **Verify**: Ensure transitions still work in the viewer.
