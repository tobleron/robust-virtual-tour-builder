# 1526 - ETA Toast Orange Tuning + Standard Format + Cancel Reset

## Objective
Refine ETA toast UX by (1) making ETA toast theming visibly orange (not brown), (2) enforcing a consistent message format across operations, and (3) guaranteeing ETA toast dismissal/reset when upload is cancelled.

## Scope
- ETA toast color palette tuning for clearer orange identity.
- Unified ETA text format for all operations:
  - `Uploading: ETA ...`
  - `Exporting: ETA ...`
  - `Generating teaser: ETA ...`
- Upload cancellation hardening so ETA toast is always dismissed on cancel terminal paths.

## Functional Requirements
- [ ] ETA toast background is updated to a more orange tone.
- [ ] ETA toast format is standardized as `<Operation>: ETA <adaptive time>`.
- [ ] Adaptive time remains `h/m`, `m/s`, or `s` based on duration.
- [ ] Upload cancel path dismisses ETA toast reliably (no stale persistent toast).
- [ ] Existing export/teaser terminal paths still dismiss ETA toasts.

## Non-Functional Requirements
- [ ] ReScript compile without warnings.
- [ ] Build passes (`npm run build`).
- [ ] No regressions in existing notification queue behavior.

## Files Expected
- `src/systems/EtaSupport.res`
- `src/components/Sidebar/SidebarLogicHandler.res`
- `src/systems/TeaserLogic.res`
- `css/variables.css`

## Validation
- [ ] Upload start shows `Uploading: Calculating ETA...`, then `Uploading: ETA ...`.
- [ ] Export start shows `Exporting: Calculating ETA...`, then `Exporting: ETA ...`.
- [ ] Teaser start shows `Generating teaser: Calculating ETA...`, then `Generating teaser: ETA ...`.
- [ ] Upload cancellation removes ETA toast immediately and does not leave stale toast.
