# Task 1174: Fix Violations FRONTEND

## Objective
## 🛡️ Violation Objective
**Role:** Code Safety Officer
**Goal:** Fix critical anti-patterns or missing safety nets.
**Priority:** High. These issues risk stability or build integrity.
**Optimal State:** Zero forbidden patterns remaining in the module.

## Tasks

### 🔧 Action: Fix Pattern `!important`
**Directive:** Pattern Fix: Replace the forbidden '!important' pattern with the recommended functional alternative.

- [ ] `../../css/components/ui.css`

### 🔧 Action: Fix Pattern `JSON.stringifyAny`
**Directive:** CSP Compliance: Replace 'JSON.stringifyAny' with `rescript-json-combinators` (Zero-Eval).

- [ ] `../../src/systems/Api/AuthenticatedClient.res`
- [ ] `../../src/systems/ProjectManager.res`

### 🔧 Action: Fix Pattern `JSON.stringify`
**Directive:** CSP Compliance: Replace 'JSON.stringify' with `rescript-json-combinators` (Zero-Eval).

- [ ] `../../src/systems/Api/AuthenticatedClient.res`
- [ ] `../../src/systems/ProjectManager.res`

### 🔧 Action: Fix Pattern `Obj.magic`
**Directive:** CSP Compliance: Replace 'Obj.magic' with `rescript-json-combinators` (Zero-Eval).

- [ ] `../../src/components/NotificationContext.res`
- [ ] `../../src/systems/ApiHelpers.res`
- [ ] `../../src/systems/ProjectManager.res`
