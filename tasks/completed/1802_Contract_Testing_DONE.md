# Task 1802: Stability: API Contract Testing & Schema Verification

## 🤖 Agent Metadata
- **Assignee**: Antigravity (AI Agent)
- **Capacity Class**: B
- **Objective**: Ensure frontend and backend remain in sync via contract verification.
- **Boundary**: `tests/contracts/`, `src/core/JsonParsersShared.res`.
- **Owned Interfaces**: API Response JSON shapes.
- **No-Touch Zones**: Actual business logic in handlers.
- **Independent Verification**: 
  - [ ] Contract test fails if a backend field is renamed without updating the frontend decoder.
- **Depends On**: None

---

## 🛡️ Objective
Prevent "silent" breaking changes where the backend modifies its JSON output but the frontend decoders continue to compile (but fail at runtime).

---

## 🛠️ Execution Roadmap
1. **Schema Definition**: Capture current API responses as the "Golden Schema".
2. **Test Harness**: Create a new test suite that runs against the backend health/mocked endpoints.
3. **Validation**: Use `rescript-json-combinators` decoders to validate real backend responses in a CI-ready script.
4. **CI Integration**: Add a `npm run test:contracts` step to the CI pipeline.

---

## ✅ Acceptance Criteria
- [ ] Every major API endpoint has a verified JSON contract.
- [ ] Build fails if the backend live response violates the ReScript decoder expectations.
