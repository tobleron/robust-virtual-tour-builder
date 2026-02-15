# 1410: Performance/Security - Telemetry Backpressure and Governance

## Objective
Control telemetry overhead and prevent observability traffic from competing with product-critical requests.

## Context
- `src/utils/Constants.res` enables diagnostic mode by default (`startInDiagnosticMode = true`).
- `src/utils/LoggerTelemetry.res` starts a 2s periodic flush timer.
- `src/utils/Logger.res` starts an additional telemetry batch timer.
- Telemetry sends through shared request infrastructure, risking queue contention under heavy logs.

## Suggested Action Plan
- [ ] Default diagnostics OFF in production; use explicit runtime toggle for deep tracing.
- [ ] Consolidate to one telemetry scheduler and remove duplicate timers.
- [ ] Introduce backpressure policy (drop/sampling/coalescing) for low-priority logs when queue is saturated.
- [ ] Separate telemetry transport from critical API request queue or enforce strict low priority.
- [ ] Add redaction policy checks to avoid leaking sensitive metadata in telemetry payloads.

## Verification
- [ ] Synthetic log storm does not starve user-facing API requests.
- [ ] Telemetry throughput and queue depth remain within configured bounds.
- [ ] Confirm error/warn signal quality remains intact after sampling/backpressure changes.
