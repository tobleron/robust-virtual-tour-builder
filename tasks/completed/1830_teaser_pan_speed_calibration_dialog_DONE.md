# 1830 Teaser Pan Speed Calibration Dialog

## Objective
Add teaser-generation speed calibration controls to the teaser dialog so users can choose the panning speed before generating a teaser, while preserving the existing default teaser behavior when no alternate speed is chosen.

## Scope
- Inspect the current teaser speed source and document the baseline behavior in code-level terms.
- Extend the teaser dialog request model to capture a user-selected pan-speed preset.
- Update the teaser dialog UI so style selection and pan-speed calibration happen before teaser generation starts.
- Apply the selected teaser pan speed only to teaser generation timing, without changing regular viewer/navigation pan behavior.
- Verify the integration with a full build.

## Constraints
- Keep the existing modal/event-bus architecture.
- Keep teaser generation deterministic.
- Avoid changing unrelated navigation timing.
- Defer unit-test rewrites unless required for responsible verification; record affected modules in the shared deferred test-review task.

## Verification
- `npm run build`
