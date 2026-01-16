---
title: Fix ReScript Deprecations
status: pending
priority: medium
assignee: unassigned
---

# Fix ReScript Deprecations

## Objective
Clean up build warnings related to deprecated Standard Library features to ensure forward compatibility and a clean build log.

## Context
The `npm run res:build` output shows multiple warnings:
-   `Js.Math.min_int` -> `Math.Int.min`
-   `Js.Dict` -> `Dict`
-   `Js.Dict.set` -> `Dict.set`
-   Unused variables.

## Requirements
1.  **Automated Migration**: Run `npx rescript-tools migrate-all` (or equivalent provided by ReScript 11/12 tools).
2.  **Manual Fixes**: Address any warnings not caught by the tool.
    -   Replace `Js.Math` usages with Core `Math`.
    -   Replace `Js.Dict` with Core `Dict`.
    -   Remove or prefix unused variables (e.g., `regex` in `ExifReportGeneratorTest.res`) with `_`.
3.  **Verification**: Ensure `npm run res:build` completes with `0` warnings.

## Definition of Done
- [ ] Build output is clean (no "Warning number X").
- [ ] App functionality remains unchanged (Regression test via `test:frontend`).
