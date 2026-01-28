# 🏛️ THE EFFICIENCY GOVERNOR: ARCHITECTURAL MANIFEST

## 1. Core Philosophy
The `_dev-system` is an autonomous "Architectural Governor" designed to maintain code quality, prevent bloat, and ensure modularity without human micromanagement. It operates on a **"Zero-Human" intervention model** where uncertainty is handled by delegating "Precursor Tasks" to an AI Agent.

**Key Mandates:**
*   **100% Accuracy:** No "guessing" via Regex. All analysis uses AST (Abstract Syntax Tree) or Structural Parsing.
*   **Cross-Platform Portability:** Uses an "Allow-list" approach (scanning only known extensions) to avoid OS-specific noise.
*   **Actionable Blueprints:** It does not just flag errors; it generates "Surgical Tasks" with specific instructions for refactoring.

---

## 2. The Logic & Formulas (The "Brain")

### A. The Dynamic Limit Formula (De-Bloating)
Instead of a static line limit (e.g., "Max 300 lines"), the system calculates a unique `MaxLOC` for every file based on its **cognitive density**.

**Formula:**
`L_max = (Base_Limit * P_mod) / Drag_Factor`

**Variables:**
*   **Base_Limit:** 250 LOC (The "Goldilocks" context window).
*   **P_mod (Purpose Multiplier):** Defined in `efficiency.json`. 
    *   *Examples:* UI Components (1.4x) are allowed to be longer; Core Algorithms (0.5x) must be shorter.
*   **Drag_Factor:** The resistance to readability.
    *   `Drag = 1.0 + (Nesting * 0.05) + (LogicDensity * 2.0) + ComplexityPenalty`

### B. The Fragmentation Formula (Consolidation)
Detects "Micro-Module Fatigue" (too many tiny files scattered across a folder).

**Formula:**
`Merge_Score = (File_Count * 10) / (Avg_LOC + 1)`

*   **Threshold:** If `Score > 1.5`, the folder is flagged for consolidation.

---

## 3. The System Architecture

### A. Directory Structure (`_dev-system/`)
*   **`analyzer/`**: The Rust binary (The Engine).
    *   **`drivers/`**: Language-specific logic (`rust.rs`, `rescript.rs`, `css.rs`, etc.).
    *   **`main.rs`**: The Orchestrator (Crawler, Inference, Task Gen).
*   **`config/efficiency.json`**: The Configuration (Weights, Multipliers, Forbidden Patterns).
*   **`pending/`**: The Output. Contains the "Master Plans" (`RUST_PLAN.md`, `SYSTEM_PLAN.md`).

### B. The Inference Engine (Taxonomy)
The system automatically classifies files into architectural roles based on:
1.  **Path Segments:** `/systems/` -> `service-orchestrator`, `/core/` -> `domain-logic`.
2.  **Filenames:** `main.rs` -> `orchestrator`, `types.res` -> `data-model`.
3.  **Content Headers:** `// @efficiency: singleton` overrides automatic inference.

### C. The Workflow
1.  **Scan**: The Rust binary crawls the project (ignoring `node_modules`, `old_ref`, etc.).
2.  **Ambiguity Check**: If a file's role cannot be determined, a **Precursor Task** is created in `SYSTEM_PLAN.md`.
3.  **Metric Extraction**: Drivers calculate LOC, Logic Count, and Nesting Depth using structural parsing.
4.  **Violation Check**: Checks for forbidden patterns (`unwrap`, `mutable`, `console.log`).
5.  **Task Generation**:
    *   **Surgical Task**: "Split file X because Drag is too high."
    *   **Merge Task**: "Combine folder Y because it's too fragmented."
    *   **Violation**: "Fix `unwrap` usage immediately."

---

## 4. Supported Languages & Drivers

| Language | Extension | Driver Logic | Complexity Penalties |
| :--- | :--- | :--- | :--- |
| **Rust** | `.rs` | `syn` (AST) | `unsafe`, `unwrap`, `panic!`, `&mut`, `macro_rules!` |
| **ReScript** | `.res` | Stack-Based Lexer | `->` (Pipe), `switch`, `mutable`, `Obj.magic` |
| **Web UI** | `.jsx`, `.html` | Tag/Indent Stack | Deep Nesting, `useEffect`, inline `style={{}}` |
| **CSS** | `.css` | Selector State Machine | `!important`, `@media`, Deep Selectors |
| **Config** | `.json` | JSON Tree Walker | Key Density |

---

## 5. Usage Instructions

### For the "Orchestrator" (User)
1.  **Run the Scan:** Execute the binary in `_dev-system/analyzer`.
2.  **Check Plans:** Look at `_dev-system/pending/`.
3.  **Delegate:** Copy the content of a Plan (e.g., `RUST_PLAN.md`) to your AI Coder.
    *   *"Execute the Surgical Task for `algorithms.rs`."*
    *   *"Resolve the Ambiguity for `index.html`."*

### For the AI Agent
1.  **Read the Anchor:** Use the specific symbol or file path provided in the Task.
2.  **Respect the Logic:** Do not blindly split; follow the "Extract to Target" instruction.
3.  **Verify:** Ensure no build errors are introduced (circular dependencies).

---

## 6. Maintenance
To tweak the strictness of the system, edit `_dev-system/config/efficiency.json`.
*   **To make it stricter:** Increase `complexity_dictionary` weights.
*   **To allow larger files:** Increase `base_loc_limit`.
