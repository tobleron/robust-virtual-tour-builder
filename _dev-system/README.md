# 🛠️ _dev-system: AI-Native Architectural Engine (v1.5.0)

The `_dev-system` is a high-performance, Rust-powered governance engine designed to maintain a codebase optimized for **Autonomous AI Agents**. It prioritizes **Cognitive Bandwidth, Context Preservation, and Token Economy** over traditional human-centric metrics.

---

## 🎯 MISSION STATEMENT
To ensure the codebase evolves into a structure where **AI Agents perform better, faster, and cheaper.** By minimizing "AI Cognitive Load" and "Read Tax," we future-proof the project for high-frequency autonomous development.

---

## 🧠 CORE VOCABULARY & CONCEPTS

### 1. 💨 Drag (Estimated Modification Risk)
**Drag** is the cumulative weight of a file's complexity. A file with high drag is more likely to produce unsafe or incomplete edits, but Drag is still a heuristic rather than a direct measurement of AI capability.
*   **Metric Sources**: AST-derived nesting depth, logic density (branching/loops), and language-specific risks (e.g., `mutable`, `unsafe`, `unwrap`).

### 2. 🌫️ Context Fog (Hotspots)
A **Hotspot** is a specific semantic region (Function or Module) where the Drag spikes to a critical level. 
*   **AI Impact**: In these regions, the probability of an AI hallucinating or missing a state change increases exponentially. The system flags these for immediate **Surgical Striking**.

### 3. 💵 Read Tax (Token Overhead)
The "hidden cost" of file fragmentation. Every time an agent has to perform a file jump or directory traversal, it incurs a **Read Tax** in tokens and attention.
*   **Solution**: **Contextual Merges** unify related small modules into a single context window.

### 4. 🚀 Cohesion Bonus
Files with a high ratio of internal logic to external dependencies receive a **LOC Allowance**. Cohesive files can stay larger because they minimize context-switching and reduce the need for tiny helper shards.

### 5. 🧱 Vertical Slicing (Feature Pods)
A structural paradigm where **UI, State, and Logic** for a single feature live in the same folder to minimize directory traversal and "folder hopping."

---

## 📐 THE MATHEMATICAL ENGINE (v2.0 Formula Optimization)

### The Limit Formula
`Limit = (Base_Limit × Role_Multiplier × Cohesion_Bonus) / Drag^0.8`

*   **Base Limit**: 400 lines (Adjustable per project avg).
*   **Hard Ceiling**: **800 lines** (The standard AI safety threshold for standard context windows).
*   **Preferred Working Band**: **350-450 LOC**, centered at **400 LOC** for cohesive Rust and ReScript modules.
*   **Semantic Weights** (v2.0 - Empirically Optimized): 
    *   **Nesting**: 0.60 (Critical for AI comprehension - increased from 0.50).
    *   **Density**: 1.00 (Moderate impact - decreased from 1.20).
    *   **State**: 8.00 (Heavy unified penalty - increased from 6.00, removed double-counting).
    *   **Depth**: 0.60 (Minor directory nesting penalty).

---

## 🚀 ADVANCED FEATURES (v1.6.0 Semantic Engine)

### 🌲 1. Semantic AST Parsing
The analyzer utilizes a high-fidelity **Semantic Scanner** (e.g., `RescriptParser`) that understands function boundaries and scope depth. It replaces simple regex heuristics with actual structural analysis.

### 🎯 2. Symbol-Aware Architectural Targets
Advisory tasks are no longer bound to volatile line numbers. The system identifies **Symbols** (e.g., `Function: handleUpload`) as targets and calculates **Exactly how many modules** are required for an optimal split (aiming for a 300 LOC "Soft Floor").

### ⚖️ 3. Hysteresis (Stability Dead Zone)
To prevent "Architectural Jitter" (Split/Merge loops), the system implements a **+/- 25% Buffer Zone**. 
*   **Split**: Triggered at `Limit * 1.25`.
*   **Merge**: Resulting file must be `< Limit * 0.75`.
This ensures files only move when the architectural benefit is mathematically significant.

### 👤 4. Shadow Orchestrator Protection
The merge engine automatically detects when a folder's contents belong to a sibling "Orchestrator" file (e.g., `auth.rs` + `auth/`). It forbids merging sub-modules back into their parents to maintain intentional domain separation.

### 🏢 5. Folder Flattening (Nesting Tax)
Merge tasks now explicitly require **Flattening**. When a folder's logic is consolidated into a single module, the directory is deleted to move the file one level higher in the hierarchy, reducing the "Directory Nesting Tax."

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
