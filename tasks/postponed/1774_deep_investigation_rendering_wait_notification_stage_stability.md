# 1774 - Deep Investigation: "Rendering...please wait" Configuration & Stage Viewer Stability

## Objective
Perform a deep codebase investigation of all configuration paths that produce the `"Rendering...please wait"` notification, determine whether current thresholds/behaviors are optimal for stage-viewer editing reliability, and propose safe optimization options ranked by stability risk.

## Why This Task Exists
Current behavior is driven by snapshot throttling/rate limiting and can surface during active stage work (fast scene switching, hotspot navigation, simulation/teaser traversal). We need evidence-based tuning guidance that improves user experience stability without regressing navigation correctness, export/teaser parity, or UI responsiveness.

## Confirmed Current Trigger Conditions (To Be Audited)
1. **Min-interval throttle hit**: snapshot request arrives before `minIntervalMs` passes.
2. **Sliding-window quota hit**: snapshot requests exceed `maxCalls` within `windowMs`.
3. **Scene-swap fan-out trigger path**: snapshot request is invoked after swap completion, including fallback swap flows.
4. **Notification dedupe/refresh behavior**: repeated same-context notifications refresh existing toast instead of creating new ones.

## Key Files to Audit
- `src/components/ViewerSnapshot.res`
- `src/systems/Scene/SceneTransition.res`
- `src/core/InteractionGuard.res`
- `src/core/InteractionPolicies.res`
- `src/core/NotificationManager.res`
- `src/core/NotificationQueue.res`
- `src/systems/Navigation/NavigationController.res`
- `src/components/NotificationCenter.res`

## Investigation Scope
- Validate exact runtime paths that can call snapshot request logic.
- Evaluate whether current limiter tuple is optimal:
  - `SlidingWindow(10, 60000, 2000)`
- Evaluate whether current debounce behavior (`wait=1000`, trailing) is optimal under rapid stage interactions.
- Evaluate notification UX impact (clarity, frequency, dismissibility, dedupe refresh cadence).
- Assess interaction with active workflows:
  - Fast scene switching from sidebar
  - Hotspot/arrow navigation
  - Simulation preview
  - Teaser recording lifecycle
  - Export-related stage interactions

## Required Research Outputs
1. **Configuration Audit Matrix**
   - Current values
   - Where applied
   - Trigger frequency risk
   - User-facing effect
   - Stability risk level (Low/Medium/High)
2. **Failure/Stress Scenarios Table**
   - Scenario
   - Expected behavior
   - Observed behavior
   - Root-cause hypothesis
3. **Safe Optimization Proposals (Ranked)**
   - Proposal A (most conservative)
   - Proposal B (balanced)
   - Proposal C (aggressive, optional)
   - For each: expected impact, regression risk, rollback strategy
4. **Recommended Defaults**
   - Proposed limiter/debounce values
   - Rationale tied to stage reliability and perceived smoothness
5. **Verification Plan**
   - Unit and E2E checks required before rollout
   - Manual stage stress test checklist

## Guardrails
- This task is **investigation + recommendation only** unless implementation is explicitly requested later.
- Do not change production logic during this task.
- Any optional instrumentation must be temporary and documented for clean rollback.

## Acceptance Criteria
- All four trigger conditions are traced with exact call paths and code references.
- Recommendation includes at least one no-risk/no-code operational option and one code-tuning option.
- Stability impact and regression risk are explicitly stated for each proposal.
- Deliverables are sufficient for a follow-up implementation task without re-discovery.

## Suggested Follow-Up Tasks (Create After Completion)
- `T####` targeted tuning implementation task (if approved)
- `T####` regression-hardening test task for snapshot/notification behavior under rapid scene operations
