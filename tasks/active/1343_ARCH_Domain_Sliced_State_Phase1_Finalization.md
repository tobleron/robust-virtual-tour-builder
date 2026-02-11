# [1343] Domain-Sliced State Migration — Phase 1 Finalization

## Priority: P1 (High — Blocks next phases)

## Context
Task 1335 established the NavigationState domain slice architecture foundation. The core refactoring is complete, but 3-4 field accessor updates remain to pass compilation and verify the implementation.

## Related Task
Continuation of **Task 1335: Domain-Sliced State Migration — Phase 1 Foundation**

## Objective
Finalize Phase 1 by:
1. Fixing remaining navigation field accessor references
2. Achieving clean build (`npm run build` passes)
3. Running E2E tests to verify behavior unchanged
4. Prepare codebase for Phase 2 (component selector hook migration)

## Implementation

### Step 1: Fix Remaining Field Accessor References

**File: `src/systems/Navigation/NavigationController.res`**
- Lines 104, 112, 162: Update dependency arrays and switch statements
  - `state.navigationFsm` → `state.navigationState.navigationFsm`
  - `state.navigation` → `state.navigationState.navigation`

**File: `src/systems/InputSystem.res`**
- Line 75: Update field access
  - `state.autoForwardChain` → `state.navigationState.autoForwardChain`

**File: `tests/unit/HotspotManager_v.test.res`**
- Line 139: Update test state constructor
  - `navigation: ...` → `navigationState: {..., navigation: ...}`

### Step 2: Verify Build

```bash
npm run build
```

Expected outcome:
- ✅ Zero compilation errors
- ✅ Frontend bundle compiles successfully
- ✅ Service Worker syncs without issues

### Step 3: Run E2E Tests

```bash
npm run test:e2e
```

Focus on these test suites to verify navigation behavior unchanged:
- `navigation.spec.ts` — Scene switching and FSM transitions
- `robustness.spec.ts` — Navigation state consistency
- `upload-link-export-workflow.spec.ts` — Multi-step workflows with navigation

### Step 4: Verify No Regressions

- [ ] Navigation transitions work smoothly
- [ ] Journey ID tracking is correct
- [ ] Auto-forward chains function properly
- [ ] Incoming link previews display correctly
- [ ] No "toast storms" or notification duplication (from Task 1334 consolidation)

## Files Affected
- `src/systems/Navigation/NavigationController.res` — 3 updates
- `src/systems/InputSystem.res` — 1 update
- `tests/unit/HotspotManager_v.test.res` — 1 update

## Verification
- [ ] `npm run build` passes with zero errors
- [ ] `npm run test:e2e` passes all navigation-related tests
- [ ] All state field accesses use `navigationState.*` pattern
- [ ] No legacy top-level navigation fields remain in use
- [ ] Phase 1 foundation is production-ready

## Phase 2 Readiness
Once this task completes, the codebase will be ready for:
- **Phase 2**: Migrate components to `useNavigationState()` selector hook
- **Phases 3-5**: Extract ViewerState, EditorState, ProjectState slices

## Estimated Effort: 1-2 hours
