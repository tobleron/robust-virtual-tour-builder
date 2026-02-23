# 1524 - Cross-Operation ETA + Toast Theming Hardening

## Objective
Implement a unified ETA experience so users get persistent, reliable ETA toasts for Upload, Export, and Teaser generation, with operation-specific metrics and stable smoothing behavior.

## Scope
- Upload ETA reliability hardening (retain existing improvements, reduce jumps further where needed)
- Export ETA support with operation-specific metrics (scene packaging + upload/network phases)
- Teaser ETA support with operation-specific metrics (manifest/render frame throughput)
- Persistent ETA toast lifecycle management (start/update/end/cancel/fail)
- ETA toast visual theming (dark orange) via palette token + targeted styling

## Functional Requirements
- [ ] ETA toast appears at operation start as: "Calculating ETA..."
- [ ] ETA toast updates to explicit remaining time using hours/minutes/seconds as appropriate
- [ ] ETA toast remains visible until the operation is terminal (success/fail/cancel)
- [ ] ETA toast text must not include percentage values
- [ ] Upload ETA uses all available inferred metrics (progress slope + item completion + in-flight pressure)
- [ ] Export ETA uses phase-aware metrics (scene count progression, upload byte progression, progress slope)
- [ ] Teaser ETA uses render workload metrics (frames complete/remaining + rolling frame duration)
- [ ] ETA updates are throttled and smoothed to avoid unstable jumps

## Non-Functional Requirements
- [ ] No regressions in existing operation lifecycle or notification queue behavior
- [ ] ReScript compile with zero warnings
- [ ] Build succeeds (`npm run build`)

## Files Expected
- `src/components/Sidebar/SidebarLogicHandler.res`
- `src/systems/Exporter.res`
- `src/systems/TeaserLogic.res`
- `src/systems/TeaserOfflineCfrRenderer.res`
- `src/components/NotificationCenter.res`
- `css/variables.css`
- `css/components/ui.css`
- (Optional shared module for ETA calculations/toast lifecycle under `src/systems/`)

## Validation
- [ ] Upload run shows stable ETA progression and terminal dismissal
- [ ] Export run shows ETA from start to completion
- [ ] Teaser run shows ETA from start to completion
- [ ] No repeated 429/circuit-breaker regression introduced by ETA logic
