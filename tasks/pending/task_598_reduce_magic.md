# Task 598: Reduce %identity (Obj.magic) Usage

## Description
The analysis report (2026-01-25) identified 53 instances of `%identity` (magic) usage, which exceeds the target threshold of 38. Most of these are used for DOM event casting and JSON parsing.

## Requirements
1.  **DOM Events**: Create proper `ReBindings.res` interfaces for `JsxEvent` and `Dom.event` properties (e.g., `target`, `files`) to eliminate the need for `%identity` in `Sidebar.res` and `ViewerManager.res`.
2.  **JSON Results**: Define explicit ReScript type definitions for API responses in `src/systems/api/` instead of casting generic objects.
3.  **Audit**: Run `grep -r "%identity" src | wc -l` to verify the count is below 38.

## Files
- `src/ReBindings.res`
- `src/components/Sidebar.res`
- `src/components/ViewerManager.res`
- `src/systems/api/*.res`

## Priority
High (Architectural Integrity)
