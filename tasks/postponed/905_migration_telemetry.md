# Migration Phase 5: Quality, Telemetry & Hardening

**Goal**: Maximize system visibility and establish a rigorous testing shield to prevent regressions in the commercial-grade architecture.

## 📋 Requirements
1. **Trace-Level Logging**: Configuration for the highest level of logging in both Frontend and Backend.
2. **Regression Shield**: 90%+ test coverage for core state reducers and navigation logic.
3. **E2E Testing**: Automated Playwright suite for critical user journeys.
4. **Visual Regression**: Baseline screenshots to prevent CSS regressions during branding changes.
5. **Standards Documentation**: Update docs for anchor-based positioning and core web vitals.

## 🛠️ Implementation Steps
1. **Maximum Fidelity Logging**:
   - Update `main.rs` to support `RUST_LOG=trace`.
   - Enhance `LoggerTelemetry.res` to send full request snapshots on failures.
2. **Hardening the Core (Test Coverage)**:
   - Expand unit tests for `src/core/reducers/` to 100% branch coverage.
   - Verify auto-forward and loop prevention logic in `NavigationGraph.res`.
3. **E2E Automation (Playwright)**:
   - Setup Playwright and implement tests for: Upload -> Add Link -> AutoPilot -> Save.
   - Integrate `npm run test:e2e` into the CI pipeline.
4. **Visual Regression & UI Standards**:
   - Implement baseline screenshot testing for key UI states.
   - Update `docs/ARCHITECTURE.md` with "Anchor-Based Positioning Standards."
5. **Performance Auditing**:
   - Measure and document Core Web Vitals (LCP, FID, CLS) in `docs/PERFORMANCE_AND_METRICS.md`.

## ✅ Success Criteria
- 100% pass rate on unit and E2E tests.
- Logs provide a step-by-step "story" of every request, including SQL queries and user context.
- No visual regressions detected across browsers (Chrome, Firefox, Safari).
- Performance metrics meet "Good" thresholds (<2.5s LCP).