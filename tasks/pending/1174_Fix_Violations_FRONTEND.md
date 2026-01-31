# Task 1174: Fix Violations FRONTEND

## Objective
## 🛡️ Violation Objective
**Role:** Code Safety Officer
**Goal:** Fix critical anti-patterns or missing safety nets.
**Priority:** High. These issues risk stability or build integrity.
**Optimal State:** Zero forbidden patterns remaining in the module.

## Tasks

### 🔧 Action: Fix Pattern `Obj.magic`
**Directive:** Pattern Fix: Replace the forbidden 'Obj.magic' pattern with the recommended functional alternative (Logger, Result/Option, etc).

- [ ] `../../src/core/SchemaParsers.res`
- [ ] `../../src/systems/ApiHelpers.res`
- [ ] `../../src/systems/ProjectManager.res`
- [ ] `../../src/utils/PersistenceLayer.res`
- [ ] `../../src/utils/SessionStore.res`
