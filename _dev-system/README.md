# 🛠️ _dev-system: AI-Native Architectural Engine (v1.5.0)

The `_dev-system` is a high-performance, Rust-powered governance engine designed to maintain a codebase optimized for **Autonomous AI Agents**. It prioritizes **Cognitive Bandwidth, Context Preservation, and Token Economy** over traditional human-centric metrics.

---

## 🎯 MISSION STATEMENT
To ensure the codebase evolves into a structure where **AI Agents perform better, faster, and cheaper.** By minimizing "AI Cognitive Load" and "Read Tax," we future-proof the project for high-frequency autonomous development.

---

## 🧠 CORE VOCABULARY & CONCEPTS

### 1. 💨 Drag (Resistance Metric)
**Drag** is the cumulative weight of a file's complexity. A file with high drag requires more "inference energy" to understand and modify safely.
*   **Metric Sources**: AST-derived nesting depth, logic density (branching/loops), and language-specific risks (e.g., `mutable`, `unsafe`, `unwrap`).

### 2. 🌫️ Context Fog (Hotspots)
A **Hotspot** is a specific semantic region (Function or Module) where the Drag spikes to a critical level. 
*   **AI Impact**: In these regions, the probability of an AI hallucinating or missing a state change increases exponentially. The system flags these for immediate **Surgical Striking**.

### 3. 💵 Read Tax (Token Overhead)
The "hidden cost" of file fragmentation. Every time an agent has to perform a file jump or directory traversal, it incurs a **Read Tax** in tokens and attention.
*   **Solution**: **Contextual Merges** unify related small modules into a single context window.

### 4. 🚀 Cohesion Bonus
Files with a high ratio of internal logic to external dependencies receive a **LOC Allowance**. Cohesive files are "AI-Friendly" as they minimize context-switching.

### 5. 🧱 Vertical Slicing (Feature Pods)
A structural paradigm where **UI, State, and Logic** for a single feature live in the same folder to minimize directory traversal and "folder hopping."

---

## 📐 THE MATHEMATICAL ENGINE (v1.5.0 Semantic Tuning)

### The Limit Formula
`Limit = (Base_Limit * Role_Multiplier * Cohesion_Bonus) / Drag^n`

*   **Base Limit**: 400 lines (Adjustable per project avg).
*   **Hard Ceiling**: **800 lines** (The standard AI safety threshold for standard context windows).
*   **Semantic Weights**: 
    *   **Nesting**: 0.50 (Aggressive penalty for deep conditional trees).
    *   **State**: 6.00 (Heavy penalty for excessive mutable state/refs).

---

## 🚀 ADVANCED FEATURES (v1.5.0 Semantic Engine)

### 🌲 1. Semantic AST Parsing
The analyzer utilizes a high-fidelity **Semantic Scanner** (e.g., `RescriptParser`) that understands function boundaries and scope depth. It replaces simple regex heuristics with actual structural analysis.

### 🎯 2. Symbol-Aware Hotspotting
Advisory tasks are no longer bound to volatile line numbers. The system identifies **Symbols** (e.g., `Function: handleUpload`) as targets, ensuring 100% accurate refactoring guidance even as files change.

### 📉 3. Inference Feedback Loop
The analyzer scans local failure logs (`FAILURE_REPORT.md`, `test_results.txt`). Problematic files that cause recent AI hallucinations or test failures receive an automatic **1.5x Drag Multiplier**, prioritizing them for refactoring.

### 🛡️ 4. Architectural Stability Guard
Persistence layer (`analyzer_state.json`) tracks the stability score and failure history of every file. It includes a **Stability Lock** to prevent rapid "Merge/Split" yoyo cycles, ensuring a consistent architectural trajectory.

---

## 🛠️ GOVERNANCE TOOLS

| Tool | Purpose | Output |
| :--- | :--- | :--- |
| **Analyzer** | Rust scanning engine with AST awareness. | `metadata.json`, `analyzer_state.json` |
| **Surgical Strikes** | Symbol-aware recommendations to de-bloat modules. | `RESCRIPT_PLAN.md`, `RUST_PLAN.md` |
| **Contextual Merges** | Suggestions to combine small related files to reduce Read Tax. | `SYSTEM_PLAN.md` |
| **Stability Guard** | Prevents architectural flip-flopping. | `analyzer_state.json` |
| **Dashboard** | Glassmorphic UI for real-time health visualization. | `DASHBOARD.html` |

---

## 🔄 THE AI WORKFLOW

1.  **Detection**: Run `./scripts/dev-system.sh` to scan the project.
2.  **Analysis**: The analyzer generates symbol-aware plans in `tasks/pending/`.
3.  **Refactoring**: Delegate a "Surgical Task" targeting a specific Function/Symbol to an agent.
4.  **Verification**: Re-run the analyzer. Successful refactors result in the removal of the task and an increase in the file's **Stability Score**.

---

## 🛡️ WHY WE BUILT THIS
Traditional software architecture optimizes for "Human Readability." The `_dev-system` ensures the codebase evolves in a way that remains **"Agent-Ready"**—where logic is flat, context is unified, and complexity is always within the safe bounds of modern LLM inference.