# 1881 Quality-Aware Export Profile Selection for 4K/2K Fallback

## Objective
Replace the current naive adaptive web-package entry logic that falls back to `2k` on small phones with a quality-aware runtime selector that prefers sharpness first and only uses `2k` when the expected visible detail remains acceptable.

## Required Changes
- Update the adaptive entry script in the export packaging flow so it no longer uses only coarse-pointer + short-edge heuristics.
- Estimate whether `2k` would become visibly soft for the current device/viewport before choosing it.
- Prefer `4k` whenever the predicted portrait/detail math suggests `2k` would be under-resolved.
- Use memory/network hints only as secondary tie-breakers after the quality threshold is satisfied.
- Keep the fallback short and self-contained in the generated entry HTML.

## Verification
- `npm run build`
- Confirm the generated web-package index script prefers `4k` for quality-sensitive portrait cases.
- Confirm constrained devices can still fall back to `2k` when the predicted detail remains acceptable.

## Notes
- This task should not implement the full portrait HFOV formula rewrite from task `1879`.
- It should align with the current export/runtime assumptions well enough to avoid obviously soft `2k` portrait loads.

## Implementation Notes
- Updated [src/systems/Exporter/ExporterPackagingTemplates.res](src/systems/Exporter/ExporterPackagingTemplates.res) so the adaptive web-package entry script no longer falls back to `2k` from a simple coarse-pointer + small-phone heuristic.
- The runtime selector now:
  - estimates the portrait-stage width for the `2k` package,
  - predicts the current portrait HFOV using the existing tiered export assumptions,
  - computes whether `2k` would provide enough visible source pixels for the expected display width,
  - forces `4k` whenever `2k` would be under-resolved,
  - only allows `2k` when quality remains acceptable and the browser also reports constrained conditions such as low memory, save-data, or slower effective connection types.
- Updated the generated entry-page and embed-code copy so it now describes `2k` as a constrained-device fallback rather than a generic small-phone fallback.

## Verification Status
- The active ReScript watcher recompiled [src/systems/Exporter/ExporterPackagingTemplates.bs.js](src/systems/Exporter/ExporterPackagingTemplates.bs.js), and the generated output contains the new `qualityAcceptable`, `effectiveType`, and `navigator.deviceMemory` selection logic.
- A second `npm run build` was not forced because the repository already has an active ReScript watch process, and starting a parallel full build would conflict with that compiler lock.
