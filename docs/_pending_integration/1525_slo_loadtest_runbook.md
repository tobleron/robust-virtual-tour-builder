# 1525 SLO + Load Test + Rollback Runbook

## SLO Template
- Upload submit success rate: `>= 99.9%`
- Async job completion success rate: `>= 99.5%`
- `process-full` completion P95 / P99: `< target_ms`
- Export completion P95 / P99: `< target_ms`
- Teaser completion P95 / P99: `< target_ms`

## Load Test Matrix
- Scenario A: steady-state heavy uploads (N users, fixed RPS).
- Scenario B: burst spike (10x baseline for 5 minutes).
- Scenario C: mixed workload (upload + export + teaser concurrent).
- Scenario D: degraded dependency (queue lag / storage latency injected).

For each scenario capture:
- Queue depth and oldest job age.
- Worker CPU/memory saturation.
- Job retries and terminal failure classes.
- P95/P99 completion times.

## Parity Validation Checklist
- Output artifact equivalence (or acceptable tolerance) vs sync path.
- Metadata completeness and ordering guarantees.
- Error semantics parity (user-facing and API-facing).

## Rollback Checklist
1. Flip feature flag to disable async path by operation type.
2. Drain/stop workers gracefully; preserve in-flight job statuses.
3. Re-route new requests to legacy sync path.
4. Announce status and incident scope in ops channel.
5. Capture post-incident report with retry/error timeline.

## Alerting Baseline
- Queue depth > threshold for 5m.
- Oldest job age > threshold for 5m.
- Retry rate above baseline.
- P99 completion time breach for two consecutive windows.

