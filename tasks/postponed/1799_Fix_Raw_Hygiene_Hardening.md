# Task 1799: Comprehensive %raw Hygiene & Hardening

## 🤖 Agent Metadata
- **Assignee**: Antigravity (AI Agent)
- **Capacity Class**: B (Complex cross-module implementation with strict bounds)
- **Objective**: Reduce `%raw` blocks from 102 down to <30 while preserving runtime stability and browser interop.
- **Boundary**: All `.res` files in `src/`.
- **Owned Interfaces**: `Bindings.res` (to be created), `SharedTypes.res` (internal types only).
- **No-Touch Zones**: `src/core/AppFSM.res`, `src/core/NavigationFSM.res` (State machine transitions must not be touched).
- **Independent Verification**: 
  - [ ] `npm run res:build` (Zero warnings/errors)
  - [ ] `npm test` (Full unit suite completion)
  - [ ] `npx playwright test --grep @robustness` (Verification of survival through failure modes)
- **Depends On**: None

---

## 🛡️ Objective
Eliminate the **type-safety gap** created by 102 `%raw` JavaScript blocks. Most of these blocks bypass the ReScript compiler and risk runtime crashes if the DOM or external JS libraries change.

---

## 📈 Strategy (Tiered Execution)

### Phase 1: Tier 1 — Safe Browser Bindings (Low Risk)
**Goal**: Move common DOM/Global usage into a central `Bindings.res` module using `@val`, `@send`, and `@get`.
- [ ] Create `src/utils/Bindings.res`.
- [ ] Migrate usage of `window.location`, `window.scrollTo`, `document.*`, `localStorage`, `sessionStorage`.
- [ ] Replace simple `%raw` wrappers for `Blob`, `File`, and `URL` creation.
- [ ] Target: ~50-60 `%raw` blocks.

### Phase 2: Tier 2 — Logic & Type Guard Extraction (Medium Risk)
**Goal**: Replace manual JS type checks with ReScript safe patterns.
- [ ] Replace `%raw` runtime type checks (e.g., `typeof obj === "string"`) with `JsonCombinators` or `Option` patterns.
- [ ] Extract regex logic from `%raw` into typed `RegExp` bindings.
- [ ] Target: ~20 `%raw` blocks.

### Phase 3: Tier 3 — Service Worker & Worker Hardening (High Risk)
**Goal**: Safely wrap Service Worker message handling and Fetch API objects.
- [ ] Hardening of `src/ServiceWorkerMain.res` — replacing raw object manipulation with proper ReScript interfaces for `Request`, `Response`, and `Headers`.
- [ ] Move worker initialization logic into a typed singleton.
- [ ] Target: ~15 `%raw` blocks.

### Phase 4: Tier 4 — The "Untouchables" Audit
**Goal**: Explicitly document why remaining `%raw` blocks must stay.
- [ ] Any `%raw` that cannot be safely typed (e.g., legacy bypass for library bugs) must be wrapped in a function with a clear comment explaining the "Why".
- [ ] Target: Remaining <30 blocks.

---

## 🛠️ Execution Checklist

### 🔧 Pre-Flight
- [ ] Run `grep -r "%raw" src --include="*.res" | wc -l` to confirm baseline count.

### 🔧 Implementation
- [ ] **Step 1**: Create `src/utils/Bindings.res`.
- [ ] **Step 2**: Iterate through `src/` modules file-by-file starting with `utils/`.
- [ ] **Step 3**: Re-verify build after every 5 files modified.

### 🔧 Verification
- [ ] **Build**: `npm run res:build` must pass with zero warnings.
- [ ] **Tests**: `npm test` must pass all current suites.
- [ ] **E2E**: Run `@robustness` and `@performance` tags in Playwright to ensure no regressions in heavy operations.

---

## ⚠️ Stability Guards
- **Do NOT** change the logic inside the `%raw` block unless it is demonstrably broken. The goal is to **re-type**, not to refactor the feature.
- **Do NOT** touch `Simulation.res` or `TeaserRecorder.res` logic unless you have 100% test coverage for the specific path.
- **Rollback Rule**: If a Tier 3 refactor breaks a test 2x, revert and document as "Untouchable".
