# 1797 Canonical Traversal Sequence Unification

## Objective
Unify hotspot sequencing under a canonical traversal model with valid-only reorder options, while preserving export legacy runtime behavior and preventing regressions in simulation/teaser traversal.

## Scope
- Add canonical traversal module for forward/return/non-traversal classification.
- Refactor HotspotSequence to consume canonical traversal outputs.
- Constrain LinkModal sequence options to admissible values only.
- Preserve current export runtime behavior by default; add safe compatibility scaffolding.
- Align visual pipeline ordering source to canonical sequence once traversal is stable.
- Add/adjust tests for traversal order, return classification, and reorder safety.

## Acceptance
- Default hotspot numbers are deterministic and stable.
- Return links are non-numbered and remain functional (including auto-forward return links).
- Sequence reorder UI prevents invalid causality-breaking selections.
- Existing export auto-forward once/session behavior remains unchanged by default.
- Build passes with zero warnings.
