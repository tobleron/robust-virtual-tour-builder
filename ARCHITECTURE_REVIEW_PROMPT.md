# Full Software Architecture Review Prompt

**Role:** Expert Software Architect & Systems Engineer
**Subject:** Robust Virtual Tour Builder (VTB) Codebase
**Context:** This project is a professional-grade virtual tour creation platform.
- **Frontend:** ReScript v12 (Functional, Strongly Typed) + React + Tailwind + Pannellum.
- **Backend:** Rust (Actix-web) + File System Storage + OSM Geocoding.
- **Key Patterns:** FSM-driven logic (AppFSM, NavigationFSM), Supervisor Pattern for concurrency (NavigationSupervisor), Reducer-based state management, and an AI-Governance system (`_dev-system`).

**Objective:** Perform a comprehensive architectural audit of the codebase to identify structural weaknesses, deviation from standards, performance bottlenecks, and opportunities for modernization.

---

## 🏗️ 1. Architecture & Design Patterns
*   **FSM Integrity:** Analyze `src/core/AppFSM.res` and `src/systems/Navigation/NavigationFSM.res`. Are states mutually exclusive? Are transitions deterministic? Are there side effects leaking into the FSM logic?
*   **Concurrency Model:** Evaluate `src/systems/Navigation/NavigationSupervisor.res`. Does it correctly handle race conditions using `AbortController`? Legacy locking mechanisms (`TransitionLock.res`) have been decommissioned.
*   **State Management:** Review `src/core/Reducer.res` and `src/core/State.res`. Is the state normalized? Are "God Objects" forming? Is `AppStateBridge` effectively synchronizing state without causing render loops?
*   **Data Flow:** specific check against `DATA_FLOW.md`. Do the actual call chains match the documented flows? Are there "backdoor" direct DOM manipulations or global variable usages bypassing the React/ReScript flow?

## 💎 2. Code Quality & Standards
*   **ReScript Idioms:** Check for strict usage of `Option`/`Result` types. Are there instances of unsafe unwrapping (`.get()`, `unwrap()`) or JavaScript interop that bypasses type safety (`%raw`, `Obj.magic`)?
*   **Rust Safety:** Analyze the backend (`backend/src/`). Are `unwrap()` or `expect()` used in production paths? Is error handling exhaustive?
*   **Complexity ("Drag"):** Identify files that likely violate the `_dev-system`'s "Drag" metric. Look for deep nesting (>4 levels), high state density (many `mutable` variables), or excessive length (>400 lines without justification).

## 🚀 3. Performance & Scalability
*   **Render Cycles:** Inspect `src/components/ViewerUI.res` and `src/components/Sidebar.res`. Are there potential unnecessary re-renders?
*   **Asset Pipeline:** Review `src/systems/Resizer.res` and `src/systems/UploadProcessor.res`. Is the client-side compression and resizing efficient? Does it block the main thread?
*   **Bundle Size:** Check imports in `src/Main.res` and `src/App.res`. Is `LazyLoad` used effectively for heavy modules (Viewer, Simulation)?

## 🛡️ 4. Reliability & Recovery
*   **Error Boundaries:** Are `AppErrorBoundary` and `CriticalErrorMonitor` catching and logging errors correctly?
*   **Operation Recovery:** Evaluate `src/utils/OperationJournal.res` and `src/utils/RecoveryManager.res`. Can the system truly recover from a browser crash during a batch upload?
*   **Type Sharing:** Verify `src/core/SharedTypes.res` vs `backend/src/models.rs`. Are there discrepancies in data contracts?

## 📝 5. Deliverables
Produce a **Structured Audit Report** containing:
1.  **Executive Summary**: High-level health assessment (Score 1-10).
2.  **Critical Issues**: Bugs, race conditions, or safety violations (Priority 0).
3.  **Architectural Debts**: Structural problems that hinder maintainability (Priority 1).
4.  **Refactoring Recommendations**: Specific files or modules to split/merge/rewrite.
5.  **Pattern Violations**: instances where the code deviates from `DATA_FLOW.md` or `MAP.md` protocols.

---
**Instructions for Agent:**
Use your tool capabilities to search, read, and analyze the files mentioned above. Cross-reference findings with the project's documentation (`docs/`, `_dev-system/plans/`). Be specific—cite file paths and line numbers where possible.
