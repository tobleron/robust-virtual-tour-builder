# Task 1118: Classify Ambiguous Files

## Objective
## 🏷️ Ambiguity Objective
**Role:** Code Taxonomist
**Goal:** Classify unknown files to enable accurate analysis.
**Action:** Add an @efficiency-role tag to the file header.
**Note:** If a file is legacy, third-party, or should not be subject to splitting/merging rules, classify it as **ignored**.
**Optimal State:** Every file has a clear architectural identity, allowing the analyzer to apply correct LOC limits.

### 📚 Valid Roles
*   **orchestrator**: App entry points and high-level flow control.
*   **domain-logic**: Pure business logic, entities, and domain services.
*   **infra-config**: Build scripts, project configuration, and environment setups.
*   **ui-component**: Visual presentation and user interaction layers.
*   **util-pure**: Side-effect free helper functions.
*   **infra-adapter**: External API clients, database drivers, and third-party bindings.
*   **service-orchestrator**: Complex coordination between multiple domain services.
*   **data-model**: Type definitions, schemas, and DTOs (low logic density).
*   **state-reducer**: Deterministic state transitions (Redux/Store style).
*   **ignored**: Exclude this file from all efficiency metrics and tasks (use for legacy, dummy, or third-party code).


## Tasks
- [ ] `../../backend/src/pathfinder/graph.rs`
    - **Directive:** Taxonomy Resolution: Add the required @efficiency-role tag to help the analyzer apply the correct complexity limits.
- [ ] `../../backend/src/services/geocoding.rs`
    - **Directive:** Taxonomy Resolution: Add the required @efficiency-role tag to help the analyzer apply the correct complexity limits.
- [ ] `../../backend/src/pathfinder/algorithms.rs`
    - **Directive:** Taxonomy Resolution: Add the required @efficiency-role tag to help the analyzer apply the correct complexity limits.
