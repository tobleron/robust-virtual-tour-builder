# Task D004: Classify Ambiguous Files

## Objective
## 🏷️ Ambiguity Objective
**Role:** Code Taxonomist
**Goal:** Classify unknown files to enable accurate analysis.
**Action:** Add an @efficiency-role: <role> tag to the file header (CRITICAL: must include the colon).
**Note:** If a file is legacy, third-party, or should not be subject to splitting/merging rules, classify it as **ignored**.
**Optimal State:** Every file has a clear architectural identity, allowing the analyzer to apply correct LOC limits.

### 📚 Valid Roles
*   **domain-logic**: Pure business logic, entities, and domain services.
*   **ignored**: Exclude this file from all efficiency metrics and tasks.
*   **orchestrator**: App entry points and high-level flow control.
*   **state-reducer**: Deterministic state transitions (Redux/Store style).
*   **state-hook**: Custom hooks with high state-to-logic ratio.
*   **util-pure**: Side-effect free helper functions.
*   **ui-component**: Visual presentation and user interaction layers.
*   **infra-binding**: External JS/FFI bindings. High LOC permitted due to low logic density.
*   **data-model**: Type definitions, schemas, and DTOs (low logic density).
*   **infra-adapter**: External API clients, database drivers, and third-party bindings.
*   **service-orchestrator**: Complex coordination between multiple domain services.
*   **infra-config**: Build scripts, project configuration, and environment setups.


## Tasks

### 🔧 Action: Classify Ambiguous Files
**Directive:** Taxonomy Resolution: Add the required @efficiency-role: <role> tag (including colon) to help the analyzer apply the correct complexity limits.

- [ ] `../../backend/src/services/project/export_session.rs`
- [ ] `../../backend/src/services/project/export_upload.rs`
- [ ] `../../backend/src/services/project/export_upload_runtime.rs`
