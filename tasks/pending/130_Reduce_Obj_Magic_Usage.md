# Task: Eliminate Remaining Obj.magic Patterns

## Status
- **Priority:** MEDIUM
- **Estimate:** 6 hours
- **Category:** Tech Debt / Type Safety

## Description
There are currently 126 instances of `Obj.magic` in the ReScript codebase. These represent type-safety escape hatches that could hide runtime errors, especially at JSON and external library boundaries.

## Requirements
1.  **Audit Top Offenders:** Identify modules with the highest concentration of `Obj.magic` (likely `UploadProcessor.res`, `ExifParser.res`, and components handling external JS objects).
2.  **Schema-Based Parsing:** Replace `Obj.magic` casts of JSON data with validated parsing using a library like `rescript-schema` or `decco`, or implement manual `Belt.Result` based decoders.
3.  **Correct Bindings:** Improve `@scope` and `@val` bindings for external JS libraries (Pannellum, JSZip) to reduce the need for casting.

## Expected Outcome
- `Obj.magic` count reduced by at least 50% (Target: < 60).
- Improved compile-time detection of data structure changes.
