# Task 1069: Classify Ambiguous Files with Efficiency Headers

## Objective
Analyze the 111 files listed as "Ambiguous" in `_dev-system/pending/SYSTEM_PLAN.md` and insert the appropriate `@efficiency` header to classify their architectural role. This will enable the AI-Native math engine to apply correct LOC limits and Drag calculations.

## Context
The `_dev-system` uses a taxonomy-based governor. Files without a classification default to "unknown" and bypass governance. We need to "stamp" these files with their true intent.

## Instructions
1.  **Read the Ambiguity List**: Open `_dev-system/pending/SYSTEM_PLAN.md` and locate the "PRECURSOR: AMBIGUITY RESOLUTION" section.
2.  **Analyze Content**: For each file, determine its role based on the logic:
    -   `orchestrator`: Main entry points, complex coordination logic.
    -   `ui-component`: React/Pannellum UI elements, styles, templates.
    -   `service-orchestrator`: Systems, Managers, complex Logic modules.
    -   `domain-logic`: Pure business rules, core state transitions.
    -   `state-reducer`: Redux-style reducers and state handlers.
    -   `data-model`: Types, Schemas, Struct definitions.
    -   `infra-adapter`: API clients, DB connectors, hardware/browser bindings.
    -   `util-pure`: Math helpers, string utils, pure functional helpers.
    -   `infra-config`: Configuration files, scripts, build tools.
3.  **Insert Header**: Add the header at the top of the file using the correct comment style:
    -   **ReScript/Rust/JS/JSX**: `// @efficiency: [role]`
    -   **CSS**: `/* @efficiency: [role] */`
    -   **HTML**: `<!-- @efficiency: [role] -->`
    -   **JSON**: `"@efficiency": "[role]"` (As a top-level property).
    -   **YAML/TOML**: `# @efficiency: [role]`
4.  **Verify**: Re-run the analyzer (`cd _dev-system/analyzer && cargo run --release`) to ensure the "Ambiguity" count drops to 0.

## Success Criteria
-   Zero files listed under "Ambiguity" in the next scan.
-   All source files have correctly assigned roles.
