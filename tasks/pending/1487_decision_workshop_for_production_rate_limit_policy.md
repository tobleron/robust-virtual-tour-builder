# 1487 - Decision Workshop: Product/Policy Inputs for Optimal Rate-Limit Configuration

## Purpose
Collect the three owner-level decisions AI cannot infer reliably, then translate answers into concrete backend/frontend configuration targets.

## Owner Decision Areas
1. Final business policy and tolerance profile for throttling.
2. Production rollout/risk posture and deployment strategy.
3. Production telemetry baselines and threshold ownership.

## AI Role in This Task
- Ask structured, minimal, high-signal questions.
- Convert answers into explicit config profiles.
- Produce a recommended policy matrix for approval.
- Apply approved profile in code/config in a follow-up implementation task.

## Output Required from This Task
- Completed decision matrix with chosen options.
- Final profile proposal:
  - limiter scope budgets (`health/read/write/admin`)
  - retry/backoff caps
  - queue behavior policy
  - UX messaging strictness
- Rollout plan:
  - canary %, observation window, rollback trigger
- SLO/alert thresholds for initial production baseline.

## Structured Questions AI Must Ask

### Section A - Business Tolerance and User Experience
- What is the highest acceptable temporary throttling window shown to users before UX is considered degraded?
- Which user operations are highest priority to preserve under load?
  - Project import
  - Scene/image browsing
  - Save/export
  - Telemetry/background sync
- Should low-priority/background tasks be auto-paused aggressively during load?
- Is “degraded but usable” preferred over strict correctness for non-critical background features?

### Section B - Multi-Profile Environment Strategy
- Should production use one global profile or environment/tenant-specific profiles?
- Is burst tolerance preferred (higher burst, stricter sustained rate) or steady throughput preferred?
- For health and control-plane endpoints, do you want near-exempt status or still bounded limits?

### Section C - Rollout and Risk
- Preferred rollout type:
  - staged canary
  - percentage rollout
  - big bang with rollback guard
- Maximum acceptable incident exposure window before rollback.
- Who approves rollback/forward decisions and on what signal?

### Section D - Observability and SLO Baseline
- Primary success KPI (e.g., import completion, retry recovery time, 429 rate by scope).
- Acceptable 429 envelope by scope (`health/read/write/admin`).
- Alert thresholds for:
  - sustained 429
  - queue pause duration
  - failed recovery attempts

## Decision Matrix Template (to fill)
- `policy_profile`: conservative | balanced | aggressive
- `priority_order`: [ops ranked 1..n]
- `background_pause_policy`: strict | adaptive | minimal
- `health_limit_policy`: high-cap | moderate | strict
- `rollout_strategy`: canary | percentage | immediate
- `rollback_trigger`: (metric + threshold + window)
- `slo_targets`: (latency/error/throttle targets)

## Acceptance Criteria
- All decision sections answered with no unresolved critical fields.
- AI provides one recommended profile and one fallback profile.
- Owner approves final profile for implementation.
- Follow-up implementation task can proceed with zero ambiguity.

## Next Task Dependency
- On completion, create/activate implementation task to apply approved policy profile into:
  - backend limiter config
  - frontend retry/backpressure config
  - observability thresholds and docs
