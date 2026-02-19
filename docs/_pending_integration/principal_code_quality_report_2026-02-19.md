# Principal Code Quality Report (2026-02-19)

## Scope
This review focuses on recently changed/high-impact areas:
- Export pipeline and exported runtime templates (`src/systems/Exporter*`, `src/systems/TourTemplates*`)
- Sidebar orchestration and progress handling (`src/components/Sidebar/*`)
- E2E test architecture and reliability (`tests/e2e/*`, `playwright.config.ts`)
- Analyzer health check (`_dev-system/analyzer`)

## Validation Performed
- `cargo run` in `_dev-system/analyzer` -> success (`All project modules are represented in data flows`)
- Playwright updated subset run (Chromium):
  - `tests/e2e/editor.spec.ts`
  - `tests/e2e/ingestion.spec.ts`
  - `tests/e2e/upload-link-export-workflow.spec.ts`
  - Result: `5 passed`

## Executive Assessment
- Architecture direction: **Good**
- Reliability posture: **Medium** (improving, still timing-sensitive in broad E2E suite)
- Maintainability: **Medium** (some monolith modules and duplicated test setup)
- Operational clarity: **Good** (rich telemetry + analyzer workflow)

Overall rating: **B+**, with clear path to **A-** after targeted refactors.

## Key Findings (Prioritized)

### 1) Functional Contract Drift in Export Runtime UX (High)
**Evidence**
- `src/systems/TourTemplates.res:159` renders only `L to toggle` shortcut text in exported HTML.
- `src/systems/TourTemplates/TourScriptInput.res:19` handles key events for `L`, `M`, and `1-3` only.

**Risk**
- Recently communicated UX expectations around export shortcuts can diverge from real runtime behavior.
- Product QA and acceptance criteria become inconsistent with implementation.

**Recommendation**
- Create a single source of truth for export shortcut contracts (spec + tests).
- Either:
  1. Implement missing shortcut behavior in export runtime scripts, or
  2. Explicitly revise product/task expectations and regression tests.

---

### 2) E2E Flake Surface Still Elevated (High)
**Evidence**
- `22` direct `waitForTimeout(...)` calls remain across E2E specs.
- Timing waits exist in critical suites like:
  - `tests/e2e/robustness.spec.ts:137`
  - `tests/e2e/rapid-scene-switching.spec.ts:81`
  - `tests/e2e/save-load-recovery.spec.ts:57`

**Risk**
- CI instability and non-deterministic failures under varying machine load.
- Longer debugging cycles with low signal failures.

**Recommendation**
- Continue migration from time-based waits to event/state-driven waits.
- Standardize on helper primitives (state unlock, FSM stabilization, modal readiness).
- Add lint/guardrails for new `waitForTimeout` usage in non-visual tests.

---

### 3) E2E Setup Duplication and Drift Risk (Medium-High)
**Evidence**
- Repeated reset/upload/initialization logic appears across many suites.
- New helper consolidation started in `tests/e2e/e2e-helpers.ts` and is working.

**Risk**
- Every UX/state-flow change requires touching many files.
- Divergent setup behavior causes hidden test inconsistencies.

**Recommendation**
- Move all remaining suites to shared helpers/fixtures.
- Standardize canonical flows:
  - clean app bootstrap
  - upload+start-building
  - link creation
  - export download handling

---

### 4) Test Log Noise Still Excessive in Some Suites (Medium)
**Evidence**
- Many direct `console.log` and extra `page.on('console')` listeners remain (e.g. `tests/e2e/rapid-scene-switching.spec.ts:64`).
- Observability helper now filters by warning/error, but some suites still bypass it.

**Risk**
- CI output bloat hides true failures.
- Increased runtime overhead and reduced debuggability.

**Recommendation**
- Route all browser logging through `setupAIObservability` only.
- Keep verbose browser logs behind an env flag (`E2E_VERBOSE_CONSOLE=1`).

---

### 5) Sidebar Logic Module Still Too Broad (Medium)
**Evidence**
- `src/components/Sidebar/SidebarLogic.res` is ~377 LOC and handles upload, load, save, export, notifications, and progress concerns.

**Risk**
- Higher regression likelihood from unrelated edits.
- Harder unit isolation and ownership boundaries.

**Recommendation**
- Split into focused modules:
  - `SidebarUploadLogic`
  - `SidebarProjectIoLogic`
  - `SidebarExportLogic`
  - `SidebarProgressLogic`
- Keep shared payload/event types in one dedicated types module.

---

### 6) Playwright Environment Portability Gap (Resolved, Keep Guard) (Medium)
**Evidence**
- Browser discovery now includes macOS cache path in `playwright.config.ts:13`.

**Risk (if regressed)**
- False “no browser provisioned” failures despite valid local installs.

**Recommendation**
- Keep platform-specific cache candidates and add a quick config self-test in CI bootstrap.

---

### 7) Analyzer Invocation Footgun (Low-Medium)
**Evidence**
- Running analyzer from repo root fails due relative config path; running from `_dev-system/analyzer` works.

**Risk**
- Developer confusion and inconsistent local tooling behavior.

**Recommendation**
- Add root-level script wrapper (e.g. `npm run dev:analyzer`) that sets correct working directory.

## Strengths Observed
- Export flow has clear phase instrumentation and monotonic progress behavior.
- Dev-system analyzer is integrated and giving actionable architecture feedback.
- Recent E2E updates now verify generated export template contracts (not only UI clicks).
- Project has strong architectural documentation (`MAP.md`, `DATA_FLOW.md`) and disciplined task process.

## Suggested 30/60/90 Plan

### 0-30 days
- Finish E2E helper migration for highest-flake suites (`robustness`, `rapid-scene-switching`, `save-load-recovery`).
- Remove/replace at least 70% of remaining `waitForTimeout` calls.
- Decide and lock export shortcut contract (`L/M/1-3` vs additional shortcuts).

### 31-60 days
- Split `SidebarLogic.res` into focused modules.
- Add small tooling checks:
  - fail CI on accidental broad console spam in E2E
  - warn on new raw timeout waits in non-visual tests

### 61-90 days
- Introduce E2E reliability dashboard (flake rate by spec over last N runs).
- Expand contract tests for exported artifacts (template semantics, key handlers, navigation behavior).

## Immediate Next Actions
1. Resolve export shortcut contract drift (implement or formally de-scope).
2. Continue deterministic wait migration in `tests/e2e/robustness.spec.ts` and `tests/e2e/rapid-scene-switching.spec.ts`.
3. Modularize `SidebarLogic.res` to reduce change blast radius.
