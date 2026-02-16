# T1423 - Troubleshoot Export Runtime Syntax Error (Unexpected token ',')

## Objective
Fix exported `index.html` runtime parse failure (`Unexpected token ','`) causing black viewer / Pannellum not initializing.

## Hypotheses (Expected Solutions Ordered by Probability)
- [x] **H1 (Highest)**: Regex literals embedded in `renderScriptTemplate` were serialized incorrectly in generated HTML JS, producing invalid syntax.
- [x] **H2**: Slash escaping in template string context altered intended regex tokens and broke parsing near normalization helpers.
- [x] **H3**: Replacing regex with explicit string operations will remove escaping fragility and keep behavior intact.

## Activity Log (Experiments / Edits)
- [x] Reproduced generated export HTML using `generateTourHTML(...)` and inspected failing lines around runtime helper functions.
- [x] Confirmed malformed emitted code in export output (`/^.?//`, `/^assets/images//`, and stripped extension regex).
- [x] Replaced regex-based scene-id normalization and extension stripping with deterministic string operations in `src/systems/TourTemplates.res`.
- [x] Rebuilt project (`npm run build`).
- [x] Re-generated sample export HTML and validated script parse via `node --check`.

## Code Change Ledger (for Surgical Revert)
- [x] `src/systems/TourTemplates.res` - Replaced regex in `normalizeSceneId` and `stripSceneExtension` with safe non-regex string logic (`replaceAll`, `startsWith`, `slice`, endsWith-loop). Revert path: restore old regex implementation if needed after escaping strategy is redesigned.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes before completion move.

## Context Handoff
- [x] Root cause was malformed regex emission in generated export JS, not Pannellum itself.
- [x] Export script now parses cleanly in isolated check (`node --check` on extracted script).
- [x] If any remaining runtime issues appear, capture the new console line and we can isolate logic-only bugs (not parser-level).
