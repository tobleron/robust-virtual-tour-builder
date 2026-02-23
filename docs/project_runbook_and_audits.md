# Enterprise Runbooks & Audits

This document is a collection of operational runbooks, performance budgets, and historical codebase audits that serve as a baseline for the project's commercial readiness and architectural health.

---

## 1. Enterprise Reliability & Performance Runbook

**Scope**: CI-enforced performance budgets and stress gates, aligned to Enterprise SLO targets.

### Budget Gates

#### Bundle Gate
- **Command**: `npm run budget:bundle`
- **Enforced Thresholds**:
  - Total JS bytes <= 4,500,000
  - Total gzip bytes <= 750,000
  - Largest chunk <= 2,000,000

#### Runtime Gate
- **Command**: `npm run test:e2e:budgets` and `npm run budget:runtime`
- **Enforced Thresholds**:
  - Rapid navigation p95 <= 1500ms
  - Rapid navigation long tasks <= 15
  - Bulk upload latency <= 90,000ms
  - Long simulation distinct active scenes >= 2
  - Long simulation long tasks <= 30

### SLO Alignment
| Metric | Threshold | Current Baseline | Status |
|---|---|---|---|
| Scene Switching p95 | < 1.5s | 125ms (cache) | Meets |
| Frontend Long Tasks (avg) | < 10 | 2 (rapid nav) | Meets |
| Memory Trend Stability | Growth Ratio <= 2.5 | 1.0 (gated suites) | Meets |

---

## 2. Commercial Readiness Audit (v4.14.0)

**Verdict**: Commercially Viable with Strategic Improvements Needed (Score: 7.5/10)

### Exceptional Strengths
1. **World-Class Type Safety**: Zero `unwrap()` in Rust, zero `console.log` in ReScript. Explicit error handling.
2. **Sophisticated Robustness Patterns**: Circuit Breaker, Retry with Backoff, Optimistic Updates, Rate Limiting, Interaction Queues.
3. **Self-Governing Dev System**: `_dev-system` analyzer automatically enforces complexity constraints and limits architectural drift.
4. **Clean Architecture**: Unidirectional data flow, modular decomposition, and local-first IndexedDB persistence.

### Identified Risks (At Time of Audit)
1. **Dev Token Fallback**: `ProjectManager.res` hardcoded a dev token. (Needs env gates for production).
2. **IndexedDB Quota**: Missing quota monitoring causing silent data loss risk.
3. **E2E Coverage**: Expand critical path coverage (Upload -> Link -> Export). 
4. **Global Singletons**: `GlobalStateBridge.res` acting as a singleton bottleneck.

---

## 3. Principal Code Quality Report (Feb 19, 2026)

**Focus Areas**: Export pipeline, Sidebar orchestration, E2E architecture.
**Rating**: B+

### Key Findings & Recommendations
1. **Export UX Drift**: Shortcut text output (`L to toggle`) does not match the actual supported key handlers (`L/M/1-3`). Needs strict alignment. 
2. **E2E Flakiness**: Direct `waitForTimeout` usage causes CI drift. Migrate fully to event/state-driven waits (`setupAIObservability`).
3. **E2E Setup Duplication**: Repeated reset/bootstrap logic across test suites. Consolidate to shared fixtures.
4. **Sidebar Logic Monolith**: `SidebarLogic.res` (>370 LOC) mixes Upload, Project IO, Export, and Notification logic. Needs splitting into sub-modules (`SidebarUploadLogic`, `SidebarProjectIoLogic`, etc.).

---

## 4. Operational Handoff Summary

The **Robust Virtual Tour Builder** exhibits enterprise-level engineering discipline, predominantly due to the tight integration of ReScript and Rust. The primary continuous focus must remain on:
1. Expanding event-driven E2E tests instead of time-based waits.
2. Monitoring performance budgets in CI to prevent bundle sprawl.
3. Adhering to the `_dev-system` Drag thresholds (Limit < 1.8) explicitly for all newly minted UI Orchestrator modules.
