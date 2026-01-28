# 🏗️ ARCHITECTURAL MANIFEST (v1.0)

## 🎯 MISSION STATEMENT
The `_dev-system` is an **AI-Native Governance Engine** designed to maintain a codebase that is optimized for autonomous agents. Unlike traditional linters that focus on human style, this system focuses on **Cognitive Bandwidth, Context Preservation, and Token Economy.**

---

## 🧠 CORE VOCABULARY & CONCEPTS

### 1. 💨 Drag (Resistance Metric)
**Drag** is the cumulative weight of a file's complexity. A file with high drag requires more "inference energy" to understand and modify safely.
*   **Drag Sources**: Nesting depth (`bracket_stack²`), logic density (branching/loops), and language-specific "risks" (e.g., `mutable`, `unsafe`, `unwrap`).

### 2. 🌫️ Context Fog (Hotspots)
A **Hotspot** is a specific 5-line window where the Drag spikes to a critical level.
*   **AI Interpretation**: In these lines, the probability of an AI hallucinating or missing a state change increases exponentially. The system flags these for immediate surgical refactoring.

### 3. 💵 Read Tax (Token Overhead)
The "hidden cost" of file fragmentation. Every time an agent has to `view_file` or perform an `ls` to find related logic, it incurs a **Read Tax** in tokens and attention.
*   **System Response**: The system penalizes large numbers of small files in a single folder, recommending merges to keep related logic within a single context window.

### 4. 🚀 Cohesion Bonus
Files that have a high ratio of internal logic to external dependencies receive a **LOC Allowance**.
*   **Philosophy**: One self-contained 300-line file is cheaper for an AI than three 100-line files that are tightly coupled via complex imports.

### 5. 🧱 Vertical Slicing (Feature Pods)
A structural paradigm where **UI, State, and Logic** for a single feature live in the same folder.
*   **Fragmentation Tax**: Triggered when a single feature (e.g., "Viewer") is spread across multiple root directories (Core, Components, Systems). This forces the AI to "folder hop," leading to context decay.

---

## 📐 THE MATHEMATICAL ENGINE

### The Limit Formula
The dynamic line-count limit for any file is calculated using:
`Limit = (Base_Limit * Role_Multiplier * Cohesion_Bonus) / Drag^1.5`

*   **Drag^1.5**: We use an exponential power to aggressively shrink the budget for complex files.
*   **Role Multiplier**: Architectural roles (e.g., `orchestrator`, `data-model`) provide different starting budgets based on the expected "density" of that role.
*   **Hard Ceiling**: No file, regardless of bonuses or exceptions, may ever exceed **800 lines** (The standard AI safety threshold).

---

## 🛠️ GOVERNANCE TOOLS

| Tool | Purpose | Output |
| :--- | :--- | :--- |
| **Analyzer** | The Rust-powered scanning engine. | `pending/*.md`, `metadata.json` |
| **Surgical Strikes** | Recommendations to move a Hotspot logic range into a new module. | `RESCRIPT_PLAN.md` |
| **Contextual Merges** | Suggestions to combine small related files to reduce Read Tax. | `SYSTEM_PLAN.md` |
| **Structural Rebase** | Suggestions to move fragmented feature files into a unified Vertical Slice. | `SYSTEM_PLAN.md` |
| **Dashboard** | A glassmorphic UI for real-time architectural visualization. | `DASHBOARD.html` |

---

## 🛡️ WHY WE BUILT THIS
Traditional software architecture optimizes for "Human Readability." However, AI Agents:
1.  **Don't "read" like humans**: They ingest tokens in parallel but have limited attention over long sequences.
2.  **Suffer from Context Fog**: They lose the "thread" of complex state in deeply nested code.
3.  **Incur High Latency on Jumps**: Every new file read is a network roundtrip and a context reload.

**The `_dev-system` ensures the codebase evolves in a way that remains "AI-Friendly" as the project grows.**
