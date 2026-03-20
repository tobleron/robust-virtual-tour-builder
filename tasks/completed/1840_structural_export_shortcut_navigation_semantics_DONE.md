# 1840 Structural Export Shortcut Navigation Semantics

## Objective
Replace the exported-tour glass-panel `up/down` shortcut resolution with a stable scene-semantics model so visible navigation no longer depends on transient arrival context such as `sourceSceneId` or revisit sequence cursor.

## Scope
- Export runtime only.
- Focus on glass-panel shortcut targets and the keyboard shortcut state they drive.
- Do not change auto-tour manifest traversal or scene playback selection logic unless a dependency is unavoidable.

## Required Outcomes
- [x] Home scene always resolves `up` to the first forward scene and never exposes a `down` backtrack target.
- [x] Interior scenes resolve `up/down` from stable scene ordering plus local hotspot connectivity, not from the most recent arrival source.
- [x] Dead-end or return-only scenes expose a single sensible escape target without duplicate `up/down` rows.
- [x] Manual shortcut navigation still updates orientation/sequence state correctly after moving between scenes.
- [x] Export-template regression coverage documents the new helper and the removal of direct panel dependence on `resolveBacktrackTarget`.

## Verification
- [x] `npx vitest run tests/unit/TourTemplates_v.test.bs.js`
- [x] `npm run build`

## Notes
- Stable user-facing scene numbers already exist in exported scene payloads and should be preferred over transient traversal context for panel semantics.
- Arrival/source context should remain available for orientation and return-link handling, but it should not directly decide the visible arrow direction.
