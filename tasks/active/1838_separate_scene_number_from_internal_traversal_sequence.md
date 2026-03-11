# 1838 Separate Scene Number From Internal Traversal Sequence

## Objective
Separate user-facing scene numbering from internal traversal sequence so the builder and exported tours continue to use traversal order internally, while labels and hotspot badges shown to users remain stable per-scene numbers.

## Scope
- Keep traversal sequence logic intact for smart engine, auto-tour, backtracking, and revisit handling.
- Introduce or derive a stable per-scene visible number for user-facing builder/export labels and hotspot badges.
- Remove any edge-case patches that become unnecessary once user-facing numbering no longer depends on traversal-step sequence.

## Acceptance Criteria
- Builder room labels show stable scene numbers rather than logical traversal-step sequence when loops or wrap-back links exist.
- Exported room labels show stable scene numbers rather than logical traversal-step sequence when loops or wrap-back links exist.
- Exported hotspot faces show stable destination scene numbers for end users, while `R` remains reserved for return links.
- Internal traversal sequence values remain available for smart-engine navigation and auto-tour state.
- Existing auto-tour, revisit, and backtrack behavior does not regress.

## Verification
- `npm run res:build`
- `npx vitest run tests/unit/TourTemplates_v.test.bs.js`
- any additional narrow unit tests needed for builder label/badge logic
- `npm run build`

## Notes
The intended UX is one stable number per visible scene for the user. Traversal sequence remains an internal implementation detail and should not leak into builder/export labeling just because a later logical revisit points back to an earlier scene.
