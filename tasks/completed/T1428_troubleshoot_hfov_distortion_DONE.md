# T1428 - Troubleshoot HFOV Distortion and 3-State Viewer Policy

## Objective
Align builder + export viewers to a strict 3-state model with fixed control sizes:
- Desktop: normal button sizes, HFOV 90.
- Tablet/Medium (same 640-stage model as export 2k/hd): small button sizes, HFOV 90.
- Mobile Portrait: small button sizes, HFOV 65.

## Hypothesis (Ordered Expected Solutions)
- [x] P1: Enforce deterministic state classes in builder lifecycle (`desktop/tablet/portrait`) using container-space breakpoints instead of fluid scaling.
- [x] P2: Bind builder HFOV exclusively to mode (`90` for desktop/tablet, `65` for portrait) through a single helper.
- [x] P3: Replace export fallback heuristics with explicit export state classes and same binary HFOV policy.
- [x] P4: Fix invalid CSS selectors that mixed media conditions with body selectors, which prevented state rules from applying reliably.
- [x] P5: Verify build/tests and confirm no regressions in generated export templates.

## Activity Log
- [x] Audited active troubleshooting tasks (`T1427`, `T1428`) and current uncommitted diff from last triple commit (`faba844e`).
- [x] Refactored builder state assignment and HFOV application in lifecycle.
- [x] Updated viewer HFOV source-of-truth to mode-class based resolution.
- [x] Reworked layout and HUD CSS to apply small controls only in tablet/portrait.
- [x] Reworked export template CSS/runtime state handling (`export-state-desktop/tablet/portrait`) and removed overlap fallback logic.
- [x] Updated affected unit tests to match new export style/runtime output.
- [x] Run full build and targeted tests.

## Code Change Ledger
| File Path | Change Summary | Revert Note |
|-----------|----------------|-------------|
| `src/components/ViewerManager/ViewerManagerLifecycle.res` | Replaced overlap fallback logic with deterministic 3-state class assignment and binary HFOV apply on init/resize. | `git checkout -- src/components/ViewerManager/ViewerManagerLifecycle.res` |
| `src/systems/ViewerSystem.res` | `getCorrectHfov()` now keys from viewer mode classes (portrait=65, else=90). | `git checkout -- src/systems/ViewerSystem.res` |
| `css/layout.css` | Added desktop/tablet aliases and portrait layout rules tied to explicit state classes. | `git checkout -- css/layout.css` |
| `css/components/viewer-ui.css` | Fixed invalid state media syntax; applied fixed small sizes for utility/floor buttons + room label + logo in tablet/portrait. | `git checkout -- css/components/viewer-ui.css` |
| `css/components/ui.css` | Fixed invalid state media syntax for notification sizing and positioning. | `git checkout -- css/components/ui.css` |
| `src/systems/TourTemplates.res` | Replaced export fallback mode with explicit export state classes; enforced binary HFOV and state-driven compact UI in exports. | `git checkout -- src/systems/TourTemplates.res` |
| `tests/unit/TourTemplateStyles_v.test.res` | Updated CSS expectations to class-driven desktop/tablet/portrait export layout. | `git checkout -- tests/unit/TourTemplateStyles_v.test.res` |
| `tests/unit/TourTemplates_v.test.res` | Updated generated HTML/CSS assertions for new export state model. | `git checkout -- tests/unit/TourTemplates_v.test.res` |

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
- Builder and export now share the same conceptual 3-mode policy with binary HFOV (`90` landscape states, `65` portrait only).
- Tablet/medium and portrait states both use compact floor/utility control sizing; desktop keeps normal sizes.
- Verification completed with `npm run build` and targeted tour-template unit tests passing.
