# Task D001: Classify Ambiguous Files

## Objective
## 🏷️ Ambiguity Objective
**Role:** Code Taxonomist
**Goal:** Classify unknown files to enable accurate analysis.
**Action:** Add an @efficiency-role: <role> tag to the file header (CRITICAL: must include the colon).
**Note:** If a file is legacy, third-party, or should not be subject to splitting/merging rules, classify it as **ignored**.
**Optimal State:** Every file has a clear architectural identity, allowing the analyzer to apply correct LOC limits.

### 📚 Valid Roles
*   **util-pure**: Side-effect free helper functions.
*   **ignored**: Exclude this file from all efficiency metrics and tasks.
*   **infra-config**: Build scripts, project configuration, and environment setups.
*   **data-model**: Type definitions, schemas, and DTOs (low logic density).
*   **domain-logic**: Pure business logic, entities, and domain services.
*   **infra-binding**: External JS/FFI bindings. High LOC permitted due to low logic density.
*   **infra-adapter**: External API clients, database drivers, and third-party bindings.
*   **ui-component**: Visual presentation and user interaction layers.
*   **orchestrator**: App entry points and high-level flow control.
*   **service-orchestrator**: Complex coordination between multiple domain services.
*   **state-reducer**: Deterministic state transitions (Redux/Store style).
*   **state-hook**: Custom hooks with high state-to-logic ratio.


## Tasks

### 🔧 Action: Classify Ambiguous Files
**Directive:** Taxonomy Resolution: Add the required @efficiency-role: <role> tag (including colon) to help the analyzer apply the correct complexity limits.

- [ ] `../../backend/src/middleware/rate_limiter.rs`
- [ ] `../../backend/src/services/project/import_upload.rs`
