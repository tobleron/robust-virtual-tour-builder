# Task 1811: Unit Test Alignment with Stable App Behavior

## Objective
Ensure frontend unit tests represent the **current stable behavior** of the app. If tests are outdated or assert legacy behavior, update them (and add missing tests where needed) so the test suite protects current functionality from regressions.

## Context
The app has undergone multiple stability and UX updates (navigation, project-load locking/readiness, hotspot sequencing/return-node behavior, and visual pipeline behavior). Existing unit tests may still target older logic.

## Scope
- In scope:
  - `tests/unit/**`
  - Test helpers/mocks under `tests/**` used by unit tests
  - Minimal test-only fixtures
- Out of scope:
  - Product-feature refactors unrelated to test correctness
  - E2E suite rewrites (unless a unit test requires equivalent mock correction)

## Required Outcome
- Unit tests must match the behavior of the currently stable app version.
- Legacy/incorrect expectations must be replaced.
- Missing coverage for key stable behaviors must be added.

## Execution Plan
1. Baseline and inventory:
   - Run `npm run res:build`
   - Run `npm run test:frontend`
   - Produce a categorized list: failing due to outdated expectations vs failing due to real bug.
2. Behavior-to-test mapping:
   - Identify source-of-truth modules for stable behavior and map each to existing unit tests.
   - Mark gaps where behavior has no unit coverage.
3. Update outdated tests:
   - Rewrite assertions that encode legacy behavior.
   - Update mocks/fixtures to match current state contracts and lifecycle expectations.
4. Add missing tests for high-risk stable behaviors:
   - Project load readiness/locking lifecycle behavior
   - Navigation/simulation traversal sequencing invariants
   - Return-node (`R`) classification and numbering rules
   - Visual pipeline derivation invariants that must remain stable
5. Reliability hardening:
   - Remove flaky timing assumptions; use deterministic test utilities where possible.
   - Ensure test names clearly describe the expected stable behavior.

## Guardrails
- Do not weaken tests by over-mocking core logic.
- Do not silence failures with broad snapshots or permissive assertions.
- If a failure reveals a real source bug (not a test issue), log it clearly and create a separate follow-up task.

## Acceptance Criteria
- `npm run res:build` passes.
- `npm run test:frontend` passes.
- Updated/added unit tests clearly reflect current stable behavior.
- A short mapping summary is added to `docs/_pending_integration/` showing:
  - stable behavior area
  - test files covering it
  - what was updated and why

## Deliverables
- Updated unit tests in `tests/unit/**`
- Any required test fixtures/mocks updates
- Mapping summary document in `docs/_pending_integration/`
