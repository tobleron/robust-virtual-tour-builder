# Refactor SvgManager Safety

## Context
The Code Quality Assessment identified unsafe type casting in `src/systems/SvgManager.res`.
```rescript
Dict.set(globalCache.elementMap, id, (Obj.magic(None): Dom.element))
```
This is a dangerous hack to "delete" keys or set them to none-like values while breaking the type system.

## Objective
Refactor `SvgManager.res` to use type-safe patterns for cache management.

## Plan
1.  **Analyze Cache**: specific usages of `elementMap`.
2.  **Refactor Type**: Change `elementMap` value type to `option<Dom.element>` OR use `Js.Dict` bindings that support deletion if available/safe.
    - *Alternative*: If `ReBindings.Dict` is strict, wrap the value or use a `Map` structure.
3.  **Remove Magic**: Replace `Obj.magic(None)` with proper `None` (if type changed) or `Dict` removal.
4.  **Verify**: Ensure the "Virtual DOM" substitute logic still works correctly (elements are re-created or reused properly).
5.  **Test**: Run `npm test` to verify `SvgManager` tests passes.
