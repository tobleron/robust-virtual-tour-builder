# ADR 1525: Async Media Processing Platform Migration

## Status
Proposed

## Decision
Adopt a submit-and-track async job architecture for heavy operations (`process-full`, export packaging, teaser render), separating API and worker responsibilities.

## Context
- Current sync request lifecycle couples user latency to CPU-bound processing.
- Single-node model degrades sharply under concurrent heavy uploads.
- Existing rate-limit and retry controls reduce failure, but do not provide throughput scaling.

## Chosen Architecture
- API nodes:
  - Validate/authenticate requests.
  - Persist input metadata.
  - Enqueue idempotent jobs.
  - Return `202 Accepted` with job ID.
- Worker nodes:
  - Pull jobs from queue.
  - Process media with bounded concurrency.
  - Persist artifacts to shared object storage.
  - Emit progress/terminal status.
- Shared dependencies:
  - Queue backend (`Redis Streams` recommended first phase).
  - Object storage (S3-compatible).
  - Status store for job lifecycle and audit.

## Why This Option
- Decouples user request path from compute-heavy execution.
- Supports horizontal scaling of workers independent from API.
- Enables queue-based backpressure and fair scheduling.
- Improves retry semantics (idempotent job execution).

## Rejected Alternatives
- Keep synchronous model + bigger node sizes:
  - Simpler short-term but poor tail latency and low elasticity.
- Full event-sourcing rewrite:
  - Too broad for migration timeline and risk profile.

## Migration Constraints
- Preserve existing API behavior through feature-flagged dual path.
- Keep legacy sync path for rollback until async parity is proven.
- Require deterministic output parity checks between sync and async paths.

## Success Metrics
- 5-10x sustained heavy-upload concurrency in staging benchmark.
- P95/P99 job completion time within defined SLO budgets.
- Reduced rate-limit storm incidents under burst traffic.

