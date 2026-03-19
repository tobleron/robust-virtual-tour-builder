# Async Media Processing Platform

**Status:** Proposed (ADR 1525)  
**Last Updated:** March 19, 2026  
**Owners:** Platform/Backend (queue, worker runtime, storage), Frontend/API (submit/status UX), QA/Perf (load tests, parity validation)

---

## 1. Executive Summary

This document defines the architecture for migrating heavy media processing operations from synchronous request-response to an **asynchronous submit-and-track job model**. This decouples user request latency from CPU-bound execution and enables horizontal scaling.

**Scope:**
- `process-full` (image processing pipeline)
- Export packaging
- Teaser video rendering

---

## 2. Problem Statement

### Current Architecture Limitations

1. **Coupled Latency:** Synchronous request lifecycle couples user latency to CPU-bound processing
2. **Poor Scaling:** Single-node model degrades sharply under concurrent heavy uploads
3. **Limited Throughput:** Existing rate-limit and retry controls reduce failures but do not provide throughput scaling
4. **No Backpressure:** No queue-based scheduling or fair resource allocation

### Impact

- Users experience long blocking waits during upload processing
- Server resources cannot scale independently for API vs compute workloads
- Burst traffic causes cascading timeouts and rate-limit storms

---

## 3. Decision

Adopt a **submit-and-track async job architecture** separating API and worker responsibilities:

### Architecture Overview

```
┌──────────────┐      ┌─────────────┐      ┌──────────────┐
│  API Nodes   │─────▶│   Queue     │─────▶│ Worker Nodes │
│  - Validate  │      │  (Redis)    │      │ - Process    │
│  - Enqueue   │      │             │      │ - Store      │
│  - Return 202│      │             │      │ - Emit Status│
└──────────────┘      └─────────────┘      └──────────────┘
                              │
                              ▼
                       ┌─────────────┐
                       │Object Store │
                       │   (S3)      │
                       └─────────────┘
```

### Component Responsibilities

**API Nodes:**
- Authenticate and validate requests
- Persist input metadata
- Enqueue idempotent jobs
- Return `202 Accepted` with job ID

**Worker Nodes:**
- Pull jobs from queue
- Process media with bounded concurrency
- Persist artifacts to shared object storage
- Emit progress and terminal status updates

**Shared Dependencies:**
- **Queue Backend:** Redis Streams (recommended for Phase 1)
- **Object Storage:** S3-compatible storage
- **Status Store:** Job lifecycle tracking and audit trail

---

## 4. Why This Architecture

### Benefits

1. **Decoupled Execution:** User request path independent from compute-heavy execution
2. **Horizontal Scaling:** Workers scale independently from API nodes
3. **Queue Backpressure:** Natural load leveling and fair scheduling
4. **Improved Retry Semantics:** Idempotent job execution with exponential backoff
5. **Resource Isolation:** API responsiveness unaffected by processing load

### Rejected Alternatives

| Alternative | Reason for Rejection |
|---|---|
| Keep synchronous model + bigger nodes | Poor tail latency, low elasticity, expensive vertical scaling |
| Full event-sourcing rewrite | Too broad for migration timeline and risk profile |
| Hybrid sync/async by operation size | Adds complexity without solving fundamental scaling limits |

---

## 5. Migration Milestones

### M1: Baseline + SLO + ADR

- [ ] **M1.1** Benchmark current sync throughput and tail latency (`process-full`, export, teaser)
- [ ] **M1.2** Define SLOs by operation type (submit success, P95, P99, failure rate)
- [ ] **M1.3** Finalize queue/storage technology decision and migration ADR

### M2: Queue/Worker Platform in Dev/Staging

- [ ] **M2.1** Provision queue + status store + worker runtime skeleton
- [ ] **M2.2** Implement job contract schema (`job_id`, idempotency key, payload hash, retries)
- [ ] **M2.3** Implement worker telemetry and progress/status publication

### M3: Async `process-full` Migration

- [ ] **M3.1** Add submit endpoint (`202 + job id`) behind feature flag
- [ ] **M3.2** Implement worker processing pipeline with parity checks
- [ ] **M3.3** Build client polling/status UX and fallback to legacy sync

### M4: Async Export/Teaser Migration

- [ ] **M4.1** Export job pipeline and artifact publish flow
- [ ] **M4.2** Teaser job pipeline and artifact publish flow
- [ ] **M4.3** Add output parity regression checks and quality guardrails

### M5: Production Rollout + Reliability Sign-Off

- [ ] **M5.1** Canary with shadow traffic and rollback gates
- [ ] **M5.2** Autoscaling + queue concurrency tuning
- [ ] **M5.3** Incident drills (worker crash, storage outage, queue lag)
- [ ] **M5.4** Final sign-off against SLO/error-budget criteria

---

## 6. Service Level Objectives (SLOs)

### SLO Templates

| Metric | Target | Measurement Window |
|---|---|---|
| Upload submit success rate | `>= 99.9%` | Rolling 7-day |
| Async job completion success rate | `>= 99.5%` | Rolling 7-day |
| `process-full` completion P95 | `< target_ms` | Per deployment |
| `process-full` completion P99 | `< target_ms` | Per deployment |
| Export completion P95/P99 | `< target_ms` | Per deployment |
| Teaser completion P95/P99 | `< target_ms` | Per deployment |

**Note:** `target_ms` values to be determined in M1.1 benchmark phase.

---

## 7. Load Testing Strategy

### Load Test Matrix

| Scenario | Description | Metrics to Capture |
|---|---|---|
| **Scenario A** | Steady-state heavy uploads (N users, fixed RPS) | Queue depth, worker saturation, P95/P99 |
| **Scenario B** | Burst spike (10x baseline for 5 minutes) | Queue lag, retry rate, recovery time |
| **Scenario C** | Mixed workload (upload + export + teaser concurrent) | Resource contention, fair scheduling |
| **Scenario D** | Degraded dependency (queue lag / storage latency injected) | Circuit breaker triggers, fallback behavior |

### Metrics to Capture Per Scenario

- Queue depth and oldest job age
- Worker CPU/memory saturation
- Job retries and terminal failure classes
- P95/P99 completion times
- API submit latency (should remain stable)

---

## 8. Parity Validation

### Output Equivalence Checks

- [ ] Artifact equivalence (or acceptable tolerance) vs sync path
- [ ] Metadata completeness and ordering guarantees
- [ ] Error semantics parity (user-facing and API-facing)
- [ ] Progress reporting accuracy

### Quality Guardrails

- Deterministic output validation between sync and async paths
- Regression checks on image quality metrics
- EXIF/metadata preservation verification

---

## 9. Rollback Plan

### Rollback Checklist

1. Flip feature flag to disable async path by operation type
2. Drain/stop workers gracefully; preserve in-flight job statuses
3. Re-route new requests to legacy sync path
4. Announce status and incident scope in ops channel
5. Capture post-incident report with retry/error timeline

### Feature Flag Strategy

- Async path behind feature flag per operation type
- Legacy sync path preserved until async parity proven
- Dual-path capability for shadow traffic testing

---

## 10. Monitoring & Alerting

### Alerting Baseline

| Alert | Threshold | Window |
|---|---|---|
| Queue depth high | > threshold | 5m |
| Oldest job age high | > threshold | 5m |
| Retry rate elevated | Above baseline | 5m |
| P99 completion breach | > SLO target | 2 consecutive windows |

### Telemetry Requirements

- Job lifecycle events (submitted, started, completed, failed)
- Queue metrics (depth, age, throughput)
- Worker metrics (utilization, error rate, retry rate)
- Storage metrics (write latency, artifact size)

---

## 11. Implementation Guidelines

### Job Contract Schema

```typescript
{
  job_id: string,           // UUID v4
  idempotency_key: string,  // SHA-256 of input payload
  payload_hash: string,     // SHA-256 of input files
  operation_type: "process-full" | "export" | "teaser",
  retries: number,          // Remaining retry count
  created_at: number,       // Unix timestamp
  payload: {                // Operation-specific payload
    // ...
  }
}
```

### Status Store Schema

```typescript
{
  job_id: string,
  status: "pending" | "processing" | "completed" | "failed" | "cancelled",
  progress: number,         // 0-100 percentage
  result: {                 // Present on completion
    artifacts: string[],    // S3 keys
    metadata: object
  },
  error: {                  // Present on failure
    code: string,
    message: string,
    retryable: boolean
  },
  timestamps: {
    submitted: number,
    started: number,
    completed: number
  }
}
```

### Worker Processing Pattern

```rust
async fn process_job(job: Job) -> Result<JobResult, JobError> {
    // 1. Validate payload
    // 2. Download input artifacts from object store
    // 3. Execute processing pipeline
    // 4. Upload output artifacts
    // 5. Update status store
    // 6. Emit telemetry
}
```

---

## 12. Success Metrics

### Technical Success

- [ ] 5-10x sustained heavy-upload concurrency in staging benchmark
- [ ] P95/P99 job completion time within defined SLO budgets
- [ ] Reduced rate-limit storm incidents under burst traffic
- [ ] Zero data loss during worker failures

### Business Success

- [ ] Improved user-perceived latency (submit is instant)
- [ ] Higher job completion rate under load
- [ ] Reduced infrastructure cost per processed job
- [ ] Better capacity planning via queue metrics

---

## 13. Related Documents

- [Performance Architecture](./performance.md)
- [System Robustness](./robustness.md)
- [Deployment Guide](../operations/deployment.md)
- [Runbook & Audits](../project/runbook_and_audits.md)

---

## 14. Appendix: Technology Evaluation

### Queue Backend Options

| Technology | Pros | Cons | Recommendation |
|---|---|---|---|
| Redis Streams | Simple, fast, mature | Requires Redis infra | **Phase 1** |
| AWS SQS | Managed, scalable | Vendor lock-in | Phase 2 (cloud) |
| Kafka | High throughput, durable | Complex ops | Overkill for MVP |
| PostgreSQL LISTEN/NOTIFY | No new infra | Limited scale | Fallback option |

### Object Storage Options

| Technology | Pros | Cons | Recommendation |
|---|---|---|---|
| AWS S3 | Industry standard, durable | Vendor lock-in | **Production** |
| MinIO | S3-compatible, self-hosted | Ops overhead | **Dev/Staging** |
| Cloudflare R2 | S3-compatible, no egress fees | Newer service | Evaluate Phase 2 |

---

**Document History:**
- March 19, 2026: Initial ADR 1525 integration
