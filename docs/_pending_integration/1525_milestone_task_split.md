# 1525 Milestone Task Split

## M1: Baseline + SLO + ADR
- `M1.1` Benchmark current sync throughput and tail latency (`process-full`, export, teaser).
- `M1.2` Define SLOs by operation type (submit success, P95, P99, failure rate).
- `M1.3` Finalize queue/storage technology decision and migration ADR.

## M2: Queue/Worker Platform in Dev/Staging
- `M2.1` Provision queue + status store + worker runtime skeleton.
- `M2.2` Implement job contract schema (`job_id`, idempotency key, payload hash, retries).
- `M2.3` Implement worker telemetry and progress/status publication.

## M3: Async `process-full` Migration
- `M3.1` Add submit endpoint (`202 + job id`) behind feature flag.
- `M3.2` Implement worker processing pipeline with parity checks.
- `M3.3` Build client polling/status UX and fallback to legacy sync.

## M4: Async Export/Teaser Migration
- `M4.1` Export job pipeline and artifact publish flow.
- `M4.2` Teaser job pipeline and artifact publish flow.
- `M4.3` Add output parity regression checks and quality guardrails.

## M5: Production Rollout + Reliability Sign-Off
- `M5.1` Canary with shadow traffic and rollback gates.
- `M5.2` Autoscaling + queue concurrency tuning.
- `M5.3` Incident drills (worker crash, storage outage, queue lag).
- `M5.4` Final sign-off against SLO/error-budget criteria.

## Owners (Suggested)
- Platform/Backend: queue, worker runtime, storage adapters.
- Frontend/API: submit/status UX, fallback logic, telemetry surfaces.
- QA/Perf: load tests, parity validation, chaos runs.

