# 🛠️ _dev-system: AI-Native Architectural Engine (v8.0)

The `_dev-system` is a high-performance, Rust-powered governance engine that monitors the codebase for **AI Efficiency**. It ensures the codebase remains optimized for autonomous agents by enforcing a strict balance between complexity, depth, and context.

---

## 🏛️ ARCHITECTURAL PRINCIPLES & TERMS

This system operates on a unique mathematical model designed to minimize the "AI Cognitive Load."

### 1. 💨 Drag (Resistance Metric)
**Drag** is the cumulative weight of a file's complexity. A file with high drag requires more "inference energy" to understand.
*   **Formula**: Sum of nesting depth (`bracket_stack²`), logic density (branching/loops), and language-specific risks (e.g., `mutable`, `unsafe`, `unwrap`).

### 2. 🌫️ Context Fog (Hotspots)
A **Hotspot** is a specific line range where the Drag spikes to a critical level, indicating a high probability of AI hallucination or state-tracking errors.
*   **Action**: These are flagged for immediate **Surgical Striking** (extraction into new modules).

### 3. 💵 Read Tax & Fragmentation
The cost incurred in tokens and latency when an agent has to switch contexts or resolve many small files.
*   **Contextual Merges**: The system suggests merging small, related files into a single context window to reduce the "Token Read Tax."
*   **Fragmentation Tax**: Penalizes features spread across multiple root directories (UI vs. State vs. Logic).

### 4. 🚀 Cohesion Bonus
Self-contained files with low external dependency density are granted a **LOC Allowance**. The system recognizes that one cohesive 300-line file is more "AI-Friendly" than three dependent 100-line files.

### 5. 🧱 Vertical Slicing
The system promotes **Feature Pods**—where UI, Logic, and State live in the same folder—to minimize directory traversal overhead for AI agents.

---

## 📐 THE MATH ENGINE
The system calculates a dynamic **LOC Limit** for every source file:
`Limit = (Base_Limit * Role_Multiplier * Cohesion_Bonus) / Drag^1.5`

*   **Role Multipliers**: Orchestrator (0.8x), Data-Model (1.5x), UI-Component (1.4x), util-pure (0.4x).
*   **Depth Penalty**: Files deeper than **4** directory levels receive an automatic Drag penalty per level.
*   **Hard Ceiling**: No file may exceed **800 lines**, ensuring it always fits within a standard 128k context window with safety margins.

---

## 📂 SYSTEM ARCHITECTURE

- **`/analyzer`**: High-performance Rust binary performing AST-like scanning and plan generation.
- **`/config`**: Configuration files (`efficiency.json`) defining taxonomy multipliers, forbidden patterns, and exclusion rules.
- **`/pending`**: Automated "Plan" files (`RESCRIPT_PLAN.md`, `SYSTEM_PLAN.md`) which serve as surgical blueprints for agents.
- **`DASHBOARD.html`**: A premium glassmorphic UI for real-time visualization of codebase health and "Hotspots."

---

## 🔄 THE AI WORKFLOW

1.  **Detection**: The Analyzer scans the project and generates a `metadata.json` and Markdown plans.
2.  **Visualization**: Use the **Architectural Dashboard** to identify the most "Foggy" regions of the app.
3.  **Refactoring**: Delegate a "Surgical Task" from the `pending/` folder to an AI agent.
4.  **Verification**: Re-run the analyzer. If the task was successful, the violation disappears from the dashboard.

---

## 🚀 WHY AI-NATIVE?
Human readability is not always AI readability. Humans read linearly and use visual cues; AI ingest tokens in high-dimensional space but struggle with long-range state dependencies and context switching. The `_dev-system` ensures the codebase evolves toward a structure where **Agents perform better, faster, and cheaper.**
