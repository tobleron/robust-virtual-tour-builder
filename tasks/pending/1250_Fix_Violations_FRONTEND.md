# Task 1250: Fix Violations FRONTEND

## Objective
## 🛡️ Violation Objective
**Role:** Code Safety Officer
**Goal:** Fix critical anti-patterns or missing safety nets.
**Priority:** High. These issues risk stability or build integrity.
**Optimal State:** Zero forbidden patterns remaining in the module.

## Tasks

### 🔧 Action: Fix Pattern `Obj.magic`
**Directive:** CSP Compliance: Replace 'Obj.magic' with `rescript-json-combinators` (Zero-Eval).

- [ ] `../../src/core/JsonParsersDecoders.res`
