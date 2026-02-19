# Task 1481: Full E2E Suite Hardening and Cross-Browser Validation

## Objective
Execute and stabilize the **entire Playwright E2E suite** against current product behavior, ensuring deterministic pass outcomes across supported browser projects and improved resistance to timing/environment flakiness.

## Background
Recent architecture and UX updates (export pipeline, viewer/navigation internals, scene naming/ingestion behavior, and progress instrumentation) introduced drift in older E2E assumptions. A focused subset was recently updated and validated; this task expands that effort to all E2E suites.

## Scope
- Run all E2E specs under `tests/e2e/*.spec.ts`.
- Validate all applicable Playwright projects currently configured in `playwright.config.ts`:
  - `chromium`
  - `firefox`
  - `webkit`
  - `chromium-budget` (for `@budget`-tagged tests)
- Update tests to match current functionality and contracts.
- Reduce flaky patterns (hard sleeps, brittle selectors, overly broad console hooks).
- Keep assertions behavior-focused (user-visible outcomes + domain-state invariants where appropriate).

## Non-Goals
- Product feature redesign.
- Performance optimization outside test reliability context.
- Backend API contract refactors unless blocking test correctness.

## Implementation Plan

### Phase 1: Baseline Execution and Failure Triage
- Run full E2E suite by project and capture failure clusters:
  1. Selector drift
  2. Timing/race conditions
  3. Environment/startup portability
  4. Legitimate regressions in app behavior
- Record failing test IDs, browser matrix impact, and reproducibility notes.

### Phase 2: Determinism and Robustness Improvements
- Replace `waitForTimeout`-based waits with deterministic conditions where feasible:
  - explicit UI state readiness
  - FSM/overlay unlock checks
  - modal/dialog visibility lifecycle
- Prefer resilient selectors:
  - `getByRole` / `getByLabel` / stable IDs / constrained locators
  - avoid fragile class-chain assumptions unless no stable alternative exists
- Consolidate repeated setup flows into shared helpers/fixtures.
- Reduce test log noise:
  - keep verbose console output behind env flag
  - default to warnings/errors + structured diagnostics only

### Phase 3: Coverage Alignment for Recent Functionalities
- Ensure export-related tests validate current behavior and generated output contracts.
- Ensure ingestion/editor/navigation tests no longer depend on outdated scene-name assumptions.
- Add/adjust checks for progress/lock lifecycle where regressions were previously observed.

### Phase 4: Cross-Browser and Budget Validation
- Execute full suite for Chromium, Firefox, WebKit.
- Execute budget-tagged suite in `chromium-budget` project.
- Fix browser-specific nondeterminism without weakening core assertions.

### Phase 5: Final Verification and Reporting
- Produce final run matrix with pass/fail counts per project.
- Summarize remaining risks and intentionally deferred test debt.
- Keep report path in `docs/_pending_integration/` if an additional technical report is generated.

## Acceptance Criteria
- Full suite executes end-to-end with deterministic outcomes in local environment.
- Cross-browser runs pass (or any known exceptions are explicitly documented with concrete blockers).
- Flake-prone patterns are materially reduced (especially raw sleeps and fragile selectors in critical flows).
- Tests reflect current app behavior/contracts (no stale assumptions from previous UX/state models).
- Build remains green after test updates (`npm run build`).

## Verification Commands
```bash
# Full E2E (all configured projects)
npm run test:e2e

# Optional targeted by project
npm run test:e2e -- --project=chromium
npm run test:e2e -- --project=firefox
npm run test:e2e -- --project=webkit

# Budget project
npm run test:e2e:budgets

# Build guard
npm run build
```

## Deliverables
1. Updated E2E suites in `tests/e2e/` aligned with current functionality.
2. Shared helper/fixture improvements for setup and deterministic waits.
3. Final validation evidence (commands + high-level results).
4. Optional technical summary in `docs/_pending_integration/` if needed.

## Risks and Mitigations
- **Risk:** Browser-specific intermittent behavior.
  - **Mitigation:** project-specific stabilization only where justified; avoid assertion weakening.
- **Risk:** Long runtime due to heavy upload/export flows.
  - **Mitigation:** helper reuse, reduced log noise, and deterministic readiness checks.
- **Risk:** Hidden contract drift between UX spec and runtime templates.
  - **Mitigation:** artifact-level assertions for export outputs where relevant.
