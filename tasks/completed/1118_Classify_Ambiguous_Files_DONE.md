# Task 1118: Classify Ambiguous Files

## Objective
## 🏷️ Ambiguity Objective
**Role:** Code Taxonomist
**Goal:** Classify unknown files to enable accurate analysis.
**Action:** Add an @efficiency-role tag to the file header.
**Note:** If a file is legacy, third-party, or should not be subject to splitting/merging rules, classify it as **ignored**.
**Optimal State:** Every file has a clear architectural identity, allowing the analyzer to apply correct LOC limits.

### 📚 Valid Roles
*   **domain-logic**: Pure business logic, entities, and domain services.
*   **infra-adapter**: External API clients, database drivers, and third-party bindings.
*   **infra-binding**: External JS/FFI bindings. High LOC permitted due to low logic density.
*   **orchestrator**: App entry points and high-level flow control.
*   **service-orchestrator**: Complex coordination between multiple domain services.
*   **util-pure**: Side-effect free helper functions.
*   **state-hook**: Custom hooks with high state-to-logic ratio.
*   **ignored**: Exclude this file from all efficiency metrics and tasks.
*   **ui-component**: Visual presentation and user interaction layers.
*   **infra-config**: Build scripts, project configuration, and environment setups.
*   **state-reducer**: Deterministic state transitions (Redux/Store style).
*   **data-model**: Type definitions, schemas, and DTOs (low logic density).


## Tasks

### 🔧 Action: Classify Ambiguous Files
**Directive:** Taxonomy Resolution: Add the required @efficiency-role tag to help the analyzer apply the correct complexity limits.

- [ ] `../../backend/src/pathfinder/algorithms.rs`
- [ ] `../../backend/src/pathfinder/graph.rs`
- [ ] `../../backend/src/services/geocoding.rs`
