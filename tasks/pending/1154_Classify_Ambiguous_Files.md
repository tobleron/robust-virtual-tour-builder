# Task 1154: Classify Ambiguous Files

## Objective
## 🏷️ Ambiguity Objective
**Role:** Code Taxonomist
**Goal:** Classify unknown files to enable accurate analysis.
**Action:** Add an @efficiency-role: <role> tag to the file header (CRITICAL: must include the colon).
**Note:** If a file is legacy, third-party, or should not be subject to splitting/merging rules, classify it as **ignored**.
**Optimal State:** Every file has a clear architectural identity, allowing the analyzer to apply correct LOC limits.

### 📚 Valid Roles
*   **service-orchestrator**: Complex coordination between multiple domain services.
*   **ui-component**: Visual presentation and user interaction layers.
*   **domain-logic**: Pure business logic, entities, and domain services.
*   **state-reducer**: Deterministic state transitions (Redux/Store style).
*   **util-pure**: Side-effect free helper functions.
*   **ignored**: Exclude this file from all efficiency metrics and tasks.
*   **infra-adapter**: External API clients, database drivers, and third-party bindings.
*   **data-model**: Type definitions, schemas, and DTOs (low logic density).
*   **state-hook**: Custom hooks with high state-to-logic ratio.
*   **infra-config**: Build scripts, project configuration, and environment setups.
*   **infra-binding**: External JS/FFI bindings. High LOC permitted due to low logic density.
*   **orchestrator**: App entry points and high-level flow control.


## Tasks

### 🔧 Action: Classify Ambiguous Files
**Directive:** Taxonomy Resolution: Add the required @efficiency-role: <role> tag (including colon) to help the analyzer apply the correct complexity limits.

- [ ] `../../backend/src/auth/handlers.rs`
- [ ] `../../backend/src/pathfinder/timeline.rs`
- [ ] `../../backend/src/pathfinder/walk.rs`
- [ ] `../../backend/src/services/geocoding/cache.rs`
- [ ] `../../backend/src/services/geocoding/osm.rs`
