# Task 1097: Perfect _dev-system Analyzer (Phase 2)

## Objective
Upgrade the `_dev-system` analyzer logic to achieve "100% Accuracy and Reliability" by implementing the Phase 2 structural features identified during the audit.

## Background
The Phase 1 tuning (metrics and config) solved the False Positive problem. Phase 2 focuses on "Architectural Intelligence"—making the system aware of dead code, coupling, and granular clusters.

## Tasks

### 1. 🧟 Implement `WorkUnit::DeadCode` Task Generation
- [ ] Update `main.rs` and `WorkUnit` enum to support a `DeadCode` variant.
- [ ] Connect the existing `DependencyGraph` results to the scan loop.
- [ ] If a file is > 50 LOC and not reachable from entry points (`Main.res`, `main.rs`, etc.), generate a task instructing the AI to "Audit & Delete" the orphaned module.

### 2. 🔗 Explicit Coupling & Cohesion Reporting
- [ ] Modify the `surgical_objective` template to include a field for **Dependency Pressure**.
- [ ] In `main.rs`, explicitly calculate the Cohesion Bonus/Penalty and report the raw "Coupling Score" (External Calls / LOC) in the task reason.
- [ ] This helps AI agents understand *why* a file is considered high drag (i.e., is it internal logic density or external dependency tangle?).

### 3. 🧩 Recursive Cluster Merge Logic
- [ ] Upgrade the `Smart Merge` logic in `consolidator/mod.rs` to detect clusters of small files across sub-folders.
- [ ] Instead of just merging an immediate directory, identify "Feature Pods" (e.g., all small files across `css/components/*`) that can be unified into a single context, even if they reside in different leaf folders.

## Verification
- [ ] Run `cargo run` in `_dev-system/analyzer`.
- [ ] Verify that unused files (like the old `handlers.rs` if it exists) are now flagged as Dead Code.
- [ ] Verify that `RUST_PLAN.md` and `RESCRIPT_PLAN.md` show explicit Coupling metrics.
