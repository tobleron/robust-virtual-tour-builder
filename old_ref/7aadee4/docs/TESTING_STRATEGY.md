# Testing Strategy: Unit, Smoke, and Smart Regression

This document outlines the formalized testing strategy for the Robust Virtual Tour Builder, established during the v4.4.7 stability sprint. This strategy ensures long-term maintainability and prevents bug regression.

## 🏛️ The Three-Tier Strategy

Our testing system is built on three pillars, providing deep logic verification, high-level stability checks, and historical bug protection.

### 1. Unit Tests (Logic Guards)
**Goal:** Verify the mathematical and logical correctness of isolated functions.
*   **Target**: Pure functions, mathematical utilities, and data transformers.
*   **Examples**:
    *   `ColorPalette_v.test.res`: Maps IDs to styling tokens.
    *   `HotspotLine_v.test.res`: Validates complex 3D-to-2D projection math.
    *   `ViewerTypes_v.test.res`: Verifies data structure defaults.
*   **Standard**: Every utility module must have 100% logic coverage.

### 2. Smoke Tests (Boot Guards)
**Goal:** Ensure major UI components can "boot" and render their core elements without crashing.
*   **Target**: Complex React components and Context Providers.
*   **Mechanism**: Uses `ReactDOMClient` to mount components into a virtual JSDOM environment.
*   **Examples**:
    *   `ViewerUI_v.test.res`: Checks if the utility bar and logo render.
    *   `Sidebar_v.test.res`: Verifies the main sidebar branding.
    *   `ModalContext_v.test.res`: Ensures the modal system can open and close.
*   **Standard**: Key "Main" components must have a smoke test to prevent "white-screen" errors.

### 3. Smart Regression Tests (Bug Guards)
**Goal:** Codify past bugs into permanent tests to ensure they never return.
*   **Target**: Logic paths that were previously identified as brittle or buggy.
*   **Mechanism**: Simulate the exact conditions that caused a historical failure.
*   **Example**:
    *   `UploadProcessor_v.test.res`: Specifically tests "100% duplicate upload" to ensure the progress bar no longer hangs (fixing a bug from Jan 2026).
*   **Standard**: Every bug fix MUST be accompanied by a regression test in this category.

---

## 🛠️ Implementation Standards

### 1. Environmental Setup (JSDOM)
All frontend tests run in a JSDOM environment. Components that rely on browser-only APIs (like `ResizeObserver`) must be polyfilled in a setup file.
*   **Setup File**: `tests/unit/LabelMenu_v.test.setup.jsx` (and similar).
*   **Usage**: Registered in `vitest.config.mjs` under `test.setupFiles`.

### 2. Mocking Strategy
To maintain isolation, we use a tiered mocking approach:
*   **Global Mocks**: Use `.test.setup.jsx` files for cross-cutting dependencies (e.g., Shadcn UI components, Lucide Icons).
*   **Partial Mocks**: Use `vi.mock` with `importOriginal` to override specific functions while keeping the rest of the module real.
*   **Component Mocks**: For integration tests, mock sub-components (like `SceneList` inside `Sidebar`) to focus on the parent's logic.

### 3. ReScript Compilation Workflow
Due to occasional file-locking issues with background watchers, the **Standard Build Workflow** is:
1.  Stop background watchers if compilation hangs.
2.  Run `npm run res:build` (Manual Force Build).
3.  Run `npm run test:frontend`.

---

## 🚀 How to Verify
To verify the entire safety net, run:
```bash
npm run test:frontend
```
This command executes Vitest against the compiled `.bs.js` files, triggering all Unit, Smoke, and Regression tests in a single pass.

---

## 📅 Maintenance
*   **New Modules**: Must include a `_v.test.res` file.
*   **Complexity**: If a component is too complex for simple unit tests, implement a **Smoke Test** at minimum.
*   **Mocks**: Keep mocks updated in `tests/unit/*.setup.jsx` to reflect changes in the UI library.
